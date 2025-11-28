import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/config_service.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/openai_llm_service.dart';
import '../services/youtube/youtube_service.dart';
import '../../features/qa/services/qa_service.dart';
import '../../features/qa/state/qa_notifier.dart';
import '../../features/qa/state/qa_state.dart';

/// Provider for OpenAI API key from environment
final apiKeyProvider = Provider<String>((ref) {
  return ConfigService.apiKey;
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

/// Provider for YouTube service
final youtubeServiceProvider = Provider<YouTubeService>((ref) {
  return YouTubeService();
});

/// StateNotifier provider for Q&A feature
/// Manages video info, question history, and loading state
final qaNotifierProvider = StateNotifierProvider<QANotifier, QAState>((ref) {
  final qaService = ref.watch(qaServiceProvider);
  final youtubeService = ref.watch(youtubeServiceProvider);
  return QANotifier(
    qaService: qaService,
    youtubeService: youtubeService,
  );
});
