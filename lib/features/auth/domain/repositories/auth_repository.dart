import 'package:paimana/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> restoreSession();
  Future<AuthUser> signIn({required String email, required String password});
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
}
