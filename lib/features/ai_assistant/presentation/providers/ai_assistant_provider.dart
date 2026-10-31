import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paimana/core/network/api_client.dart';
import 'package:paimana/features/ai_assistant/data/datasources/ai_assistant_remote_data_source.dart';
import 'package:paimana/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import 'package:paimana/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

final aiAssistantProvider =
    AsyncNotifierProvider<AiAssistantController, String>(
      AiAssistantController.new,
    );

class AiAssistantController extends AsyncNotifier<String> {
  late final AiAssistantRepository _repository = AiAssistantRepositoryImpl(
    AiAssistantRemoteDataSource(apiClient),
  );

  @override
  Future<String> build() async => '';

  Future<String> run({
    required String action,
    required String prompt,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repository.run(action: action, prompt: prompt);
      state = AsyncData(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}
