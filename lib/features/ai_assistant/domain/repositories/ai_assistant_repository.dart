abstract interface class AiAssistantRepository {
  Future<String> run({required String action, required String prompt});
}
