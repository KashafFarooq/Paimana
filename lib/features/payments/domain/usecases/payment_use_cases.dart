import 'package:paimana/features/payments/domain/entities/payment.dart';
import 'package:paimana/features/payments/domain/repositories/payment_repository.dart';
import 'package:uuid/uuid.dart';

class GetPayments {
  const GetPayments(this._repository);

  final PaymentRepository _repository;

  Future<List<Payment>> call() => _repository.getAll();
}

class AddPayment {
  const AddPayment(this._repository);

  final PaymentRepository _repository;

  Future<void> call({
    required String orderId,
    required double amount,
    required PaymentType paymentType,
    required PaymentMethod method,
    required DateTime paidAt,
    required String note,
  }) {
    final now = DateTime.now();
    return _repository.save(
      Payment(
        id: const Uuid().v4(),
        orderId: orderId,
        amount: amount,
        paymentType: paymentType,
        method: method,
        paidAt: paidAt,
        note: note.trim(),
        createdAt: now,
      ),
    );
  }
}

class DeletePayment {
  const DeletePayment(this._repository);

  final PaymentRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
