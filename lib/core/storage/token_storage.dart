import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'jwt_access_token';
  static const _refreshTokenKey = 'jwt_refresh_token';
  static const _accountIdKey = 'auth_account_id';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<String?> readAccountId() => _storage.read(key: _accountIdKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? accountId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (accountId != null) {
      await _storage.write(key: _accountIdKey, value: accountId);
    }
  }

  Future<void> clear() async {
    await clearCredentials();
    await _storage.delete(key: _accountIdKey);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
