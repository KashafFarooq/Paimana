import 'package:paimana/features/orders/domain/entities/order.dart';
import 'package:paimana/features/orders/domain/repositories/order_repository.dart';
import 'package:uuid/uuid.dart';

class GetOrders {
  const GetOrders(this._repository);

  final OrderRepository _repository;

  Future<List<TailoringOrder>> call() => _repository.getAll();
}

class AddOrder {
  const AddOrder(this._repository);

  final OrderRepository _repository;

  Future<void> call({
    required String customerName,
    required String garment,
    required DateTime dueDate,
    required double totalAmount,
    required double paidAmount,
    String note = '',
  }) {
    final order = TailoringOrder(
      id: const Uuid().v4(),
      customerName: customerName.trim(),
      garment: garment.trim(),
      dueDate: dueDate,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    return _repository.save(order);
  }
}

class DeleteOrder {
  const DeleteOrder(this._repository);

  final OrderRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
