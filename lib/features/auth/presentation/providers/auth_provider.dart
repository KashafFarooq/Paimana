import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:paimana/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:paimana/features/auth/domain/entities/auth_user.dart';
import 'package:paimana/features/auth/domain/repositories/auth_repository.dart';
import 'package:paimana/features/auth/domain/usecases/auth_use_cases.dart';
import 'package:paimana/features/customers/presentation/providers/customer_providers.dart';
import 'package:paimana/features/orders/presentation/providers/order_providers.dart';

final authProvider = AsyncNotifierProvider<AuthController, AuthUser?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthUser?> {
  late final TokenStorage _tokens = TokenStorage();
  late final AuthRepository _repository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSource(tokenStorage: _tokens),
    tokenStorage: _tokens,
  );

  @override
  Future<AuthUser?> build() {
    if (!AppConfig.hasApi) return Future.value(null);
    return RestoreSession(_repository).call();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = AsyncData(await SignIn(_repository).call(
        email: email,
        password: password,
      ));
      ref.invalidate(customersProvider);
      ref.invalidate(ordersProvider);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      state = AsyncData(await RegisterAccount(_repository).call(
        name: name,
        email: email,
        password: password,
      ));
      ref.invalidate(customersProvider);
      ref.invalidate(ordersProvider);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await SignOut(_repository).call();
      state = const AsyncData(null);
      ref.invalidate(customersProvider);
      ref.invalidate(ordersProvider);
    } catch (error) {
      state = const AsyncData(null);
      ref.invalidate(customersProvider);
      ref.invalidate(ordersProvider);
      rethrow;
    }
  }
}
