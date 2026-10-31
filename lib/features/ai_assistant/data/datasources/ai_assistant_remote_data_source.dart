import 'package:dio/dio.dart';

class AiAssistantRemoteDataSource {
  const AiAssistantRemoteDataSource(this._dio);

  final Dio _dio;

  Future<String> run({required String action, required String prompt}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ai/$action',
      data: {'text': prompt},
    );
    final body = response.data;
    final data = body?['data'];
    if (body?['success'] != true ||
        data is! Map<String, dynamic> ||
        data['suggestion'] is! String) {
      throw const FormatException(
        'The API returned an invalid AI suggestion response.',
      );
    }
    return data['suggestion'] as String;
  }
}
