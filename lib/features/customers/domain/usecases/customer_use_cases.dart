import 'package:paimana/features/customers/domain/entities/customer.dart';
import 'package:paimana/features/customers/domain/repositories/customer_repository.dart';
import 'package:uuid/uuid.dart';

class GetCustomers {
  const GetCustomers(this._repository);

  final CustomerRepository _repository;

  Future<List<Customer>> call() => _repository.getAll();
}

class AddCustomer {
  const AddCustomer(this._repository);

  final CustomerRepository _repository;

  Future<void> call({
    required String name,
    required String phone,
    String note = '',
  }) {
    final customer = Customer(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone.trim(),
      note: note.trim(),
      createdAt: DateTime.now(),
    );
    return _repository.save(customer);
  }
}

class DeleteCustomer {
  const DeleteCustomer(this._repository);

  final CustomerRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
