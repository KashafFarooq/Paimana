import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/orders/data/datasources/order_local_data_source.dart';
import 'package:paimana/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:paimana/features/orders/domain/entities/order.dart';
import 'package:paimana/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(
    this._localDataSource, {
    OrderRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
  }) : _remoteDataSource =
           remoteDataSource ?? OrderRemoteDataSource(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  final OrderLocalDataSource _localDataSource;
  final OrderRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final HiveRecordStore _store = HiveRecordStore();

  @override
  Future<List<TailoringOrder>> getAll() async {
    final local = await _localDataSource.getAll();
    if (!await _canSync) return local;
    try {
      await _flushQueue();
      final remote = await _remoteDataSource.getAll();
      for (final order in remote) {
        await _localDataSource.save(order);
      }
      final merged = {for (final order in local) order.id: order};
      for (final order in remote) {
        merged[order.id] = order;
      }
      return merged.values.toList(growable: false);
    } on DioException catch (error) {
      if (!_isDeferredFailure(error)) rethrow;
      developer.log(
        'Order sync deferred; showing saved local records.',
        name: 'paimana.sync.orders',
        error: error,
      );
      return local;
    }
  }

  @override
  Future<void> save(TailoringOrder order) async {
    await _localDataSource.save(order);
    await _store.enqueue(
      entity: 'order',
      id: order.id,
      operation: 'upsert',
      payload: order.toJson(),
      scope: await _scope,
    );
    if (await _canSync) await _flushQueue();
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
    await _store.enqueue(
      entity: 'order',
      id: id,
      operation: 'delete',
      payload: const {},
      scope: await _scope,
    );
    if (await _canSync) await _flushQueue();
  }

  Future<bool> get _canSync async =>
      AppConfig.hasApi && (await _tokenStorage.readAccessToken()) != null;

  Future<String> get _scope async =>
      await _tokenStorage.readAccountId() ?? 'local';

  Future<void> _flushQueue() async {
    final scope = await _scope;
    for (final entry in await _store.readQueue('order', scope: scope)) {
      final id = entry['id'] as String;
      final operation = entry['operation'] as String;
      try {
        if (operation == 'upsert') {
          final payload = entry['payload'];
          if (payload is! Map) {
            throw const FormatException('Queued order data is invalid.');
          }
          await _remoteDataSource.upsert(
            TailoringOrder.fromJson(Map<String, dynamic>.from(payload)),
          );
        } else if (operation == 'delete') {
          try {
            await _remoteDataSource.delete(id);
          } on DioException catch (error) {
            if (error.response?.statusCode != 404) rethrow;
          }
        } else {
          throw FormatException('Unsupported order sync operation: $operation');
        }
        await _store.removeFromQueue(entity: 'order', id: id, scope: scope);
      } on DioException catch (error) {
        if (!_isDeferredFailure(error)) rethrow;
        developer.log(
          'Order sync queue paused; the operation remains queued.',
          name: 'paimana.sync.orders',
          error: error,
        );
        return;
      }
    }
  }

  bool _isDeferredFailure(DioException error) {
    if (error.response?.statusCode == 401) return true;
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError => true,
      _ => (error.response?.statusCode ?? 0) >= 500,
    };
  }
}
