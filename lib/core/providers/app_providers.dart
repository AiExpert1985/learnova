import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/config_service.dart';
import '../services/openai/openai_service.dart';
import '../services/openai/openai_service_impl.dart';
import '../../features/qa/services/qa_service.dart';

/// Provider for OpenAI API key from config
final apiKeyProvider = Provider<String>((ref) {
  return ConfigService.get('OPENAI_API_KEY');
});

/// Provider for OpenAI service
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  final apiKey = ref.watch(apiKeyProvider);
  return OpenAIServiceImpl(apiKey: apiKey);
});

/// Provider for QA service
final qaServiceProvider = Provider<QAService>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  return QAService(openAIService: openAIService);
});
