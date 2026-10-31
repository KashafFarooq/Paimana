import 'package:paimana/features/orders/domain/entities/order.dart';

abstract interface class OrderRepository {
  Future<List<TailoringOrder>> getAll();
  Future<void> save(TailoringOrder order);
  Future<void> delete(String id);
}
