import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/config_service.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/openai_llm_service.dart';
import '../../features/qa/services/qa_service.dart';

/// Provider for OpenAI API key from config
final apiKeyProvider = Provider<String>((ref) {
  return ConfigService.get('OPENAI_API_KEY');
});

/// Provider for LLM service (currently OpenAI, easily swappable)
final llmServiceProvider = Provider<LLMService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return OpenAILLMService(apiKey: apiKey);

  // Future: swap to different LLM providers
  // return GeminiLLMService(apiKey: geminiKey);
  // return ClaudeLLMService(apiKey: claudeKey);
});

/// Provider for QA service
final qaServiceProvider = Provider<QAService>((ref) {
  final llmService = ref.watch(llmServiceProvider);
  return QAService(llmService: llmService);
});
