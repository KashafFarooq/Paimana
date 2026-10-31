import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/features/orders/data/datasources/order_local_data_source.dart';
import 'package:paimana/features/orders/data/repositories/order_repository_impl.dart';
import 'package:paimana/features/orders/domain/entities/order.dart';
import 'package:paimana/features/orders/domain/repositories/order_repository.dart';
import 'package:paimana/features/orders/domain/usecases/order_use_cases.dart';

final ordersProvider =
    AsyncNotifierProvider<OrderController, List<TailoringOrder>>(
      OrderController.new,
    );

class OrderController extends AsyncNotifier<List<TailoringOrder>> {
  late final OrderRepository _repository = OrderRepositoryImpl(
    OrderLocalDataSource(HiveRecordStore()),
  );

  @override
  Future<List<TailoringOrder>> build() => GetOrders(_repository).call();

  Future<void> add({
    required String customerName,
    required String garment,
    required DateTime dueDate,
    required double totalAmount,
    required double paidAmount,
    String note = '',
  }) async {
    final previous = state;
    try {
      await AddOrder(_repository).call(
        customerName: customerName,
        garment: garment,
        dueDate: dueDate,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        note: note,
      );
      state = AsyncData(await GetOrders(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final previous = state;
    try {
      await DeleteOrder(_repository).call(id);
      state = AsyncData(await GetOrders(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus(TailoringOrder updatedOrder) async {
    final previous = state;
    try {
      await _repository.save(updatedOrder);
      state = AsyncData(await GetOrders(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
