import 'package:dio/dio.dart';
import 'package:paimana/core/network/api_client.dart';
import 'package:paimana/core/storage/token_storage.dart';
import 'package:paimana/features/auth/domain/entities/auth_user.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required TokenStorage tokenStorage,
    Dio? dio,
  }) : _tokenStorage = tokenStorage,
       _dio = dio ?? apiClient;

  final TokenStorage _tokenStorage;
  final Dio _dio;

  Future<AuthUser?> restoreSession() async {
    if (await _tokenStorage.readAccessToken() == null) return null;
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    final data = _data(response.data);
    final user = data['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('The API did not return an authenticated user.');
    }
    return AuthUser.fromJson(user);
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return _saveSession(response.data);
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
    return _saveSession(response.data);
  }

  Future<void> signOut() async {
    if (await _tokenStorage.readAccessToken() == null) {
      await _tokenStorage.clear();
      return;
    }
    try {
      await _dio.post<void>('/auth/logout');
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<AuthUser> _saveSession(Map<String, dynamic>? response) async {
    final data = _data(response);
    final user = data['user'];
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    if (user is! Map<String, dynamic> ||
        accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty) {
      throw const FormatException('The API returned an invalid sign-in response.');
    }
    final authUser = AuthUser.fromJson(user);
    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accountId: authUser.id,
    );
    return authUser;
  }

  Map<String, dynamic> _data(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (response?['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid response.');
    }
    return data;
  }
}
