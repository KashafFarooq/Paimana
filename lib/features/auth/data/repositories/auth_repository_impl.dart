import 'package:dio/dio.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:paimana/features/auth/domain/entities/auth_user.dart';
import 'package:paimana/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required TokenStorage tokenStorage,
  }) : _remoteDataSource = remoteDataSource,
       _tokenStorage = tokenStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthUser?> restoreSession() async {
    try {
      return await _remoteDataSource.restoreSession();
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokenStorage.clearCredentials();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _remoteDataSource.register(
      name: name,
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _remoteDataSource.signOut();
    } on DioException {
      await _tokenStorage.clear();
      rethrow;
    }
  }
}
