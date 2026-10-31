import 'package:paimana/features/ai_assistant/data/datasources/ai_assistant_remote_data_source.dart';
import 'package:paimana/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

class AiAssistantRepositoryImpl implements AiAssistantRepository {
  const AiAssistantRepositoryImpl(this._remoteDataSource);

  final AiAssistantRemoteDataSource _remoteDataSource;

  @override
  Future<String> run({required String action, required String prompt}) {
    return _remoteDataSource.run(action: action, prompt: prompt);
  }
}
