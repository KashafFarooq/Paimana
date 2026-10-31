import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/payments/domain/entities/payment.dart';

class PaymentLocalDataSource {
  PaymentLocalDataSource(this._store, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final HiveRecordStore _store;
  final TokenStorage _tokenStorage;

  Future<List<Payment>> getAll() async => _store.readAll(
    HiveRecordStore.paymentsBoxName,
    Payment.fromJson,
    scope: await _scope,
  );

  Future<void> save(Payment payment) async => _store.write(
    HiveRecordStore.paymentsBoxName,
    payment.id,
    payment,
    (value) => value.toJson(),
    scope: await _scope,
  );

  Future<void> delete(String id) async => _store.delete(
    HiveRecordStore.paymentsBoxName,
    id,
    scope: await _scope,
  );

  Future<String> get _scope async {
    if (!AppConfig.hasApi) return 'local';
    return await _tokenStorage.readAccountId() ?? 'local';
  }
}
