import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/features/auth/presentation/providers/auth_provider.dart';
import 'package:paimana/features/customers/presentation/providers/customer_providers.dart';
import 'package:paimana/features/orders/presentation/providers/order_providers.dart';
import 'package:paimana/features/payments/presentation/providers/payment_providers.dart';

final autoSyncProvider = AsyncNotifierProvider<AutoSyncController, void>(
  AutoSyncController.new,
);

class AutoSyncController extends AsyncNotifier<void> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<void>? _syncFuture;

  @override
  Future<void> build() async {
    if (!AppConfig.hasApi) return;

    ref.onDispose(() => _connectivitySubscription?.cancel());
    ref.listen(authProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        unawaited(_synchronize());
      }
    });

    final connectivity = Connectivity();
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      (results) {
        if (_isOnline(results)) unawaited(_synchronize());
      },
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Connectivity monitoring failed.',
          name: 'paimana.sync',
          error: error,
          stackTrace: stackTrace,
        );
        state = AsyncError(error, stackTrace);
      },
    );

    final currentConnectivity = await connectivity.checkConnectivity();
    if (_isOnline(currentConnectivity)) unawaited(_synchronize());
  }

  Future<void> retry() => _synchronize();

  Future<void> _synchronize() {
    final activeSync = _syncFuture;
    if (activeSync != null) return activeSync;
    late final Future<void> sync;
    sync = _runSync().whenComplete(() {
      if (identical(_syncFuture, sync)) _syncFuture = null;
    });
    return _syncFuture = sync;
  }

  Future<void> _runSync() async {
    try {
      ref.invalidate(customersProvider);
      ref.invalidate(ordersProvider);
      ref.invalidate(paymentsProvider);
      await ref.read(customersProvider.future);
      await ref.read(ordersProvider.future);
      await ref.read(paymentsProvider.future);
      ref.invalidate(ordersProvider);
      await ref.read(ordersProvider.future);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      developer.log(
        'Automatic synchronization failed.',
        name: 'paimana.sync',
        error: error,
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
    }
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
