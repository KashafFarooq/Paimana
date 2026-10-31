import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/orders/data/datasources/order_local_data_source.dart';
import 'package:paimana/features/orders/domain/repositories/order_repository.dart';
import 'package:paimana/features/payments/data/datasources/payment_local_data_source.dart';
import 'package:paimana/features/payments/data/datasources/payment_remote_data_source.dart';
import 'package:paimana/features/payments/domain/entities/payment.dart';
import 'package:paimana/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(
    this._localDataSource, {
    required OrderRepository orderRepository,
    required OrderLocalDataSource orderLocalDataSource,
    PaymentRemoteDataSource? remoteDataSource,
    TokenStorage? tokenStorage,
  }) : _orderRepository = orderRepository,
       _orderLocalDataSource = orderLocalDataSource,
       _remoteDataSource = remoteDataSource ?? PaymentRemoteDataSource(),
       _tokenStorage = tokenStorage ?? TokenStorage();

  final PaymentLocalDataSource _localDataSource;
  final OrderRepository _orderRepository;
  final OrderLocalDataSource _orderLocalDataSource;
  final PaymentRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;
  final HiveRecordStore _store = HiveRecordStore();

  @override
  Future<List<Payment>> getAll() async {
    final local = await _localDataSource.getAll();
    if (!await _canSync) return local;
    try {
      await _flushQueue();
      await _orderRepository.getAll();
      final remote = await _remoteDataSource.getAll();
      for (final payment in remote) {
        await _localDataSource.save(payment);
      }
      final merged = {for (final payment in local) payment.id: payment};
      for (final payment in remote) {
        merged[payment.id] = payment;
      }
      return merged.values.toList(growable: false);
    } on DioException catch (error) {
      if (!_isDeferredFailure(error)) rethrow;
      developer.log(
        'Payment sync deferred; showing saved local records.',
        name: 'paimana.sync.payments',
        error: error,
      );
      return local;
    }
  }

  @override
  Future<void> save(Payment payment) async {
    final orders = await _orderLocalDataSource.getAll();
    final matches = orders.where((item) => item.id == payment.orderId);
    final order = matches.isEmpty ? null : matches.first;
    if (order == null) {
      throw StateError('The order for this payment could not be found.');
    }
    final remaining = order.totalAmount - order.paidAmount;
    if (payment.amount <= 0 || payment.amount > remaining) {
      throw ArgumentError('Payment must be positive and within the remaining balance.');
    }
    if (payment.paymentType == PaymentType.finalPayment &&
        (payment.amount - remaining).abs() > 0.000001) {
      throw ArgumentError('A final payment must clear the remaining balance.');
    }

    await _orderLocalDataSource.updatePaidAmountLocally(
      payment.orderId,
      order.paidAmount + payment.amount,
    );
    await _localDataSource.save(payment);
    await _store.enqueue(
      entity: 'payment',
      id: payment.id,
      operation: 'upsert',
      payload: payment.toJson(),
      scope: await _scope,
    );
    if (await _canSync) await _flushQueue();
  }

  @override
  Future<void> delete(String id) async {
    final payments = await _localDataSource.getAll();
    final paymentMatches = payments.where((item) => item.id == id);
    final payment = paymentMatches.isEmpty ? null : paymentMatches.first;
    if (payment == null) {
      throw StateError('The payment is no longer available.');
    }
    final orders = await _orderLocalDataSource.getAll();
    final orderMatches = orders.where((item) => item.id == payment.orderId);
    final order = orderMatches.isEmpty ? null : orderMatches.first;
    if (order == null || order.paidAmount < payment.amount) {
      throw StateError('The order balance no longer matches this payment.');
    }

    await _orderLocalDataSource.updatePaidAmountLocally(
      payment.orderId,
      order.paidAmount - payment.amount,
    );
    await _localDataSource.delete(id);
    await _store.enqueue(
      entity: 'payment',
      id: payment.id,
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
    for (final entry in await _store.readQueue('payment', scope: scope)) {
      final id = entry['id'] as String;
      final operation = entry['operation'] as String;
      try {
        if (operation == 'upsert') {
          final payload = entry['payload'];
          if (payload is! Map) {
            throw const FormatException('Queued payment data is invalid.');
          }
          await _remoteDataSource.save(
            Payment.fromJson(Map<String, dynamic>.from(payload)),
          );
        } else if (operation == 'delete') {
          try {
            await _remoteDataSource.delete(id);
          } on DioException catch (error) {
            if (error.response?.statusCode != 404) rethrow;
          }
        } else {
          throw FormatException('Unsupported payment sync operation: $operation');
        }
        await _store.removeFromQueue(
          entity: 'payment',
          id: id,
          scope: scope,
        );
      } on DioException catch (error) {
        if (!_isDeferredFailure(error)) rethrow;
        developer.log(
          'Payment sync queue paused; the operation remains queued.',
          name: 'paimana.sync.payments',
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
