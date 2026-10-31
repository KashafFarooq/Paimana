import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/customers/domain/entities/customer.dart';

class CustomerLocalDataSource {
  CustomerLocalDataSource(this._store, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final HiveRecordStore _store;
  final TokenStorage _tokenStorage;

  Future<List<Customer>> getAll() async => _store.readAll(
    HiveRecordStore.customersBoxName,
    Customer.fromJson,
    scope: await _scope,
  );

  Future<void> save(Customer customer) async => _store.write(
    HiveRecordStore.customersBoxName,
    customer.id,
    customer,
    (value) => value.toJson(),
    scope: await _scope,
  );

  Future<void> delete(String id) async => _store.delete(
    HiveRecordStore.customersBoxName,
    id,
    scope: await _scope,
  );

  Future<String> get _scope async {
    if (!AppConfig.hasApi) return 'local';
    return await _tokenStorage.readAccountId() ?? 'local';
  }
}
