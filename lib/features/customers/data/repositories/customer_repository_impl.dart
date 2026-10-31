import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:paimana/features/customers/data/datasources/customer_remote_data_source.dart';
import 'package:paimana/features/customers/domain/entities/customer.dart';
import 'package:paimana/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  CustomerRepositoryImpl(
    this._localDataSource, {
    CustomerRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
  }) : _remoteDataSource =
           remoteDataSource ?? CustomerRemoteDataSource(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  final CustomerLocalDataSource _localDataSource;
  final CustomerRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final HiveRecordStore _store = HiveRecordStore();

  @override
  Future<List<Customer>> getAll() async {
    final local = await _localDataSource.getAll();
    if (!await _canSync) return local;
    try {
      await _flushQueue();
      final remote = await _remoteDataSource.getAll();
      for (final customer in remote) {
        await _localDataSource.save(customer);
      }
      final merged = {for (final customer in local) customer.id: customer};
      for (final customer in remote) {
        merged[customer.id] = customer;
      }
      return merged.values.toList(growable: false);
    } on DioException catch (error) {
      if (!_isDeferredFailure(error)) rethrow;
      developer.log(
        'Customer sync deferred; showing saved local records.',
        name: 'paimana.sync.customers',
        error: error,
      );
      return local;
    }
  }

  @override
  Future<void> save(Customer customer) async {
    await _localDataSource.save(customer);
    await _store.enqueue(
      entity: 'customer',
      id: customer.id,
      operation: 'upsert',
      payload: customer.toJson(),
      scope: await _scope,
    );
    if (await _canSync) await _flushQueue();
  }

  @override
  Future<void> delete(String id) async {
    await _localDataSource.delete(id);
    await _store.enqueue(
      entity: 'customer',
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
    for (final entry in await _store.readQueue('customer', scope: scope)) {
      final id = entry['id'] as String;
      final operation = entry['operation'] as String;
      try {
        if (operation == 'upsert') {
          final payload = entry['payload'];
          if (payload is! Map) {
            throw const FormatException('Queued customer data is invalid.');
          }
          await _remoteDataSource.upsert(
            Customer.fromJson(Map<String, dynamic>.from(payload)),
          );
        } else if (operation == 'delete') {
          try {
            await _remoteDataSource.delete(id);
          } on DioException catch (error) {
            if (error.response?.statusCode != 404) rethrow;
          }
        } else {
          throw FormatException('Unsupported customer sync operation: $operation');
        }
        await _store.removeFromQueue(
          entity: 'customer',
          id: id,
          scope: scope,
        );
      } on DioException catch (error) {
        if (!_isDeferredFailure(error)) rethrow;
        developer.log(
          'Customer sync queue paused; the operation remains queued.',
          name: 'paimana.sync.customers',
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
