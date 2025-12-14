import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/config_service.dart';
import '../services/llm/llm_service.dart';
import '../services/llm/openai_llm_service.dart';
import '../services/youtube/youtube_service.dart';
import '../services/voice/stt_service.dart';
import '../services/voice/tts_service.dart';
import '../services/voice/voice_service.dart';
import '../services/voice/flutter_stt_service.dart';
import '../services/voice/flutter_tts_service.dart';
import '../services/voice/voice_service_impl.dart';
import '../services/voice/permission_service.dart';
import '../services/voice/state/voice_notifier.dart';
import '../services/voice/state/voice_state.dart';
import '../services/audio/audio_device_service.dart';
import '../services/audio/audio_device_service_impl.dart';
import '../services/storage/preferences_service.dart';
import '../../features/qa/services/qa_service.dart';
import '../../features/qa/state/qa_notifier.dart';
import '../../features/qa/state/qa_state.dart';
import '../../features/history/providers/history_providers.dart';

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
  final historyService = ref.watch(historyServiceProvider);
  return QANotifier(
    qaService: qaService,
    youtubeService: youtubeService,
    historyService: historyService,
  );
});

/// Provider for permission service
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Provider for audio device service (headphone detection)
final audioDeviceServiceProvider = Provider<AudioDeviceService>((ref) {
  return AudioDeviceServiceImpl();
});

/// Provider for STT service (speech_to_text implementation)
final sttServiceProvider = Provider<STTService>((ref) {
  return FlutterSTTService();
  // Future: swap to different STT providers
  // return GoogleCloudSTTService(apiKey: key);
});

/// Provider for TTS service (flutter_tts implementation)
final ttsServiceProvider = Provider<TTSService>((ref) {
  return FlutterTTSService();
  // Future: swap to different TTS providers
  // return GoogleCloudTTSService(apiKey: key);
});

/// Provider for voice service coordinator
final voiceServiceProvider = Provider<VoiceService>((ref) {
  final sttService = ref.watch(sttServiceProvider);
  final ttsService = ref.watch(ttsServiceProvider);
  return VoiceServiceImpl(
    sttService: sttService,
    ttsService: ttsService,
  );
});

/// StateNotifier provider for voice feature
final voiceNotifierProvider =
    StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final voiceService = ref.watch(voiceServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  final audioDeviceService = ref.watch(audioDeviceServiceProvider);
  return VoiceNotifier(
    voiceService,
    permissionService,
    audioDeviceService,
  );
});

/// Provider for preferences service (state persistence)
final preferencesServiceProvider = FutureProvider<PreferencesService>((ref) async {
  return await PreferencesService.create();
});
