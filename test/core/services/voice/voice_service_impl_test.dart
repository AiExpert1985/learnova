import 'package:flutter_test/flutter_test.dart';
import 'package:vidorion/core/services/voice/voice_service_impl.dart';
import 'package:vidorion/core/services/voice/stt_service.dart';
import 'package:vidorion/core/services/voice/tts_service.dart';
import 'package:vidorion/core/services/voice/voice_models.dart';

/// Mock STT Service for testing
class MockSTTService implements STTService {
  bool _isListening = false;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    _isListening = true;
    return Stream.value(
      SpeechRecognitionResult(
        recognizedText: 'test question',
        confidence: 0.9,
        isFinal: true,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> cancelListening() async {
    _isListening = false;
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  bool get isListening => _isListening;

  @override
  Future<List<String>> getSupportedLocales() async => ['en-US'];

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}

/// Mock TTS Service for testing
class MockTTSService implements TTSService {
  bool _isSpeaking = false;
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Stream<SpeechSynthesisState> speak(String text) {
    _isSpeaking = true;
    return Stream.fromIterable([
      SpeechSynthesisState.speaking,
      SpeechSynthesisState.idle,
    ]);
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<List<String>> getLanguages() async => ['en-US'];

  @override
  Future<List<String>> getVoices() async => ['default'];

  @override
  Future<void> setVoice(String voice) async {}

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}

void main() {
  group('VoiceServiceImpl', () {
    late VoiceServiceImpl voiceService;
    late MockSTTService mockSTTService;
    late MockTTSService mockTTSService;

    setUp(() {
      mockSTTService = MockSTTService();
      mockTTSService = MockTTSService();
      voiceService = VoiceServiceImpl(
        sttService: mockSTTService,
        ttsService: mockTTSService,
      );
    });

    test('initialize initializes both STT and TTS services', () async {
      await voiceService.initialize();
      expect(mockSTTService._isInitialized, true);
      expect(mockTTSService._isInitialized, true);
    });

    test('startListening returns recognition results', () async {
      await voiceService.initialize();

      final stream = voiceService.startListening();
      final result = await stream.first;

      expect(result.recognizedText, 'test question');
      expect(result.confidence, 0.9);
      expect(result.isFinal, true);
    });

    test('startListening stops TTS if speaking', () async {
      await voiceService.initialize();

      // Start speaking
      mockTTSService._isSpeaking = true;

      // Start listening should stop speaking
      voiceService.startListening();

      expect(mockTTSService._isSpeaking, false);
    });

    test('speak returns synthesis states', () async {
      await voiceService.initialize();

      final stream = voiceService.speak('test answer');
      final states = await stream.toList();

      expect(states.length, 2);
      expect(states[0], SpeechSynthesisState.speaking);
      expect(states[1], SpeechSynthesisState.idle);
    });

    test('speak stops STT if listening', () async {
      await voiceService.initialize();

      // Start listening
      mockSTTService._isListening = true;

      // Speaking should stop listening
      voiceService.speak('test');

      expect(mockSTTService._isListening, false);
    });

    test('isSpeechRecognitionAvailable returns true', () async {
      final available = await voiceService.isSpeechRecognitionAvailable();
      expect(available, true);
    });

    test('configureTTS sets TTS parameters', () async {
      await voiceService.initialize();

      // Should not throw
      await voiceService.configureTTS(
        speechRate: 0.5,
        volume: 0.8,
        pitch: 1.2,
        language: 'en-US',
      );
    });

    test('dispose cleans up resources', () async {
      await voiceService.initialize();
      await voiceService.dispose();

      expect(mockSTTService._isInitialized, false);
      expect(mockTTSService._isInitialized, false);
    });
  });
}
