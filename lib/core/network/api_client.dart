import 'package:dio/dio.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/core/storage/token_storage.dart';

Dio createApiClient({TokenStorage? tokenStorage}) {
  final tokens = tokenStorage ?? TokenStorage();
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.hasApi
          ? AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '')
          : 'https://localhost.invalid',
     connectTimeout: const Duration(seconds: 60),
receiveTimeout: const Duration(seconds: 90),
sendTimeout: const Duration(seconds: 60),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(_JwtInterceptor(dio: dio, tokenStorage: tokens));
  return dio;
}

final apiClient = createApiClient();

class _JwtInterceptor extends Interceptor {
  _JwtInterceptor({required this.dio, required this.tokenStorage});

  final Dio dio;
  final TokenStorage tokenStorage;
  Future<String?>? _refreshFuture;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final accessToken = await tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    if (error.response?.statusCode != 401 ||
        request.path.endsWith('/auth/refresh') ||
        request.extra['retriedAfterRefresh'] == true) {
      handler.next(error);
      return;
    }

    try {
      final accessToken = await (_refreshFuture ??= _refreshAccessToken());
      if (accessToken == null) {
        await tokenStorage.clearCredentials();
        handler.next(error);
        return;
      }

      final headers = Map<String, dynamic>.from(request.headers)
        ..['Authorization'] = 'Bearer $accessToken';
      final retry = request.copyWith(
        headers: headers,
        extra: {...request.extra, 'retriedAfterRefresh': true},
      );
      handler.resolve(await dio.fetch<dynamic>(retry));
    } on DioException {
      await tokenStorage.clearCredentials();
      handler.next(error);
    } on FormatException {
      await tokenStorage.clearCredentials();
      handler.next(error);
    } finally {
      _refreshFuture = null;
    }
  }

  Future<String?> _refreshAccessToken() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response =
        await Dio(
          BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
            contentType: Headers.jsonContentType,
          ),
        ).post<Map<String, dynamic>>(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
        );
    final payload = response.data?['data'] ?? response.data;
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid token refresh response.');
    }
    final accessToken = payload['accessToken'];
    final nextRefreshToken = payload['refreshToken'];
    final user = payload['user'];
    final accountId = user is Map<String, dynamic> ? user['id'] : null;
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('Refresh response did not include a token.');
    }
    await tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: nextRefreshToken is String
          ? nextRefreshToken
          : refreshToken,
      accountId: accountId is String ? accountId : null,
    );
    return accessToken;
  }
}
