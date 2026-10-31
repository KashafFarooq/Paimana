import 'package:paimana/features/payments/domain/entities/payment.dart';

abstract interface class PaymentRepository {
  Future<List<Payment>> getAll();
  Future<void> save(Payment payment);
  Future<void> delete(String id);
}
