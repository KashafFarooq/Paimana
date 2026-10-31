import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/features/orders/data/datasources/order_local_data_source.dart';
import 'package:paimana/features/orders/data/repositories/order_repository_impl.dart';
import 'package:paimana/features/orders/domain/repositories/order_repository.dart';
import 'package:paimana/features/orders/presentation/providers/order_providers.dart';
import 'package:paimana/features/payments/data/datasources/payment_local_data_source.dart';
import 'package:paimana/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:paimana/features/payments/domain/entities/payment.dart';
import 'package:paimana/features/payments/domain/repositories/payment_repository.dart';
import 'package:paimana/features/payments/domain/usecases/payment_use_cases.dart';

final paymentsProvider =
    AsyncNotifierProvider<PaymentController, List<Payment>>(
      PaymentController.new,
    );

class PaymentController extends AsyncNotifier<List<Payment>> {
  late final OrderLocalDataSource _orderLocalDataSource =
      OrderLocalDataSource(HiveRecordStore());
  late final OrderRepository _orderRepository = OrderRepositoryImpl(
    _orderLocalDataSource,
  );
  late final PaymentRepository _repository = PaymentRepositoryImpl(
    PaymentLocalDataSource(HiveRecordStore()),
    orderRepository: _orderRepository,
    orderLocalDataSource: _orderLocalDataSource,
  );

  @override
  Future<List<Payment>> build() => GetPayments(_repository).call();

  Future<void> add({
    required String orderId,
    required double amount,
    required PaymentType paymentType,
    required PaymentMethod method,
    required DateTime paidAt,
    required String note,
  }) async {
    final previous = state;
    try {
      await AddPayment(_repository).call(
        orderId: orderId,
        amount: amount,
        paymentType: paymentType,
        method: method,
        paidAt: paidAt,
        note: note,
      );
      ref.invalidate(ordersProvider);
      state = AsyncData(await GetPayments(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final previous = state;
    try {
      await DeletePayment(_repository).call(id);
      ref.invalidate(ordersProvider);
      state = AsyncData(await GetPayments(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteForOrder(String orderId) async {
    final previous = state;
    try {
      final payments = await GetPayments(_repository).call();
      for (final payment in payments.where(
        (payment) => payment.orderId == orderId,
      )) {
        await DeletePayment(_repository).call(payment.id);
      }
      ref.invalidate(ordersProvider);
      state = AsyncData(await GetPayments(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
