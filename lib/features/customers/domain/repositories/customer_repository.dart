import 'package:paimana/features/customers/domain/entities/customer.dart';

abstract interface class CustomerRepository {
  Future<List<Customer>> getAll();
  Future<void> save(Customer customer);
  Future<void> delete(String id);
}
