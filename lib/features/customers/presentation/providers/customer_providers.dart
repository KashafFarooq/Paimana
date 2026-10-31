import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:paimana/features/customers/data/repositories/customer_repository_impl.dart';
import 'package:paimana/features/customers/domain/entities/customer.dart';
import 'package:paimana/features/customers/domain/repositories/customer_repository.dart';
import 'package:paimana/features/customers/domain/usecases/customer_use_cases.dart';

final customersProvider =
    AsyncNotifierProvider<CustomerController, List<Customer>>(
      CustomerController.new,
    );

class CustomerController extends AsyncNotifier<List<Customer>> {
  late final CustomerRepository _repository = CustomerRepositoryImpl(
    CustomerLocalDataSource(HiveRecordStore()),
  );

  @override
  Future<List<Customer>> build() => GetCustomers(_repository).call();

  Future<void> add({
    required String name,
    required String phone,
    String note = '',
  }) async {
    final previous = state;
    try {
      await AddCustomer(_repository).call(name: name, phone: phone, note: note);
      state = AsyncData(await GetCustomers(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    final previous = state;
    try {
      await DeleteCustomer(_repository).call(id);
      state = AsyncData(await GetCustomers(_repository).call());
    } catch (error, stackTrace) {
      state = previous.hasValue ? previous : AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
