import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/hive_record_store.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/orders/domain/entities/order.dart';

class OrderLocalDataSource {
  OrderLocalDataSource(this._store, {TokenStorage? tokenStorage})
    : _tokenStorage = tokenStorage ?? TokenStorage();

  final HiveRecordStore _store;
  final TokenStorage _tokenStorage;

  Future<List<TailoringOrder>> getAll() async => _store.readAll(
    HiveRecordStore.ordersBoxName,
    TailoringOrder.fromJson,
    scope: await _scope,
  );

  Future<void> save(TailoringOrder order) async => _store.write(
    HiveRecordStore.ordersBoxName,
    order.id,
    order,
    (value) => value.toJson(),
    scope: await _scope,
  );

  Future<void> delete(String id) async => _store.delete(
    HiveRecordStore.ordersBoxName,
    id,
    scope: await _scope,
  );

  Future<void> updatePaidAmountLocally(
    String id,
    double paidAmount,
  ) async {
    final orders = await getAll();
    final matches = orders.where((item) => item.id == id);
    final order = matches.isEmpty ? null : matches.first;
    if (order == null) {
      throw StateError('The order for this payment is not available locally.');
    }
    await save(order.copyWith(paidAmount: paidAmount));
  }

  Future<String> get _scope async {
    if (!AppConfig.hasApi) return 'local';
    return await _tokenStorage.readAccountId() ?? 'local';
  }
}
