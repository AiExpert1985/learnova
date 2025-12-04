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

    group('Continuous Listening Mode', () {
      test('captures recognized text even without isFinal flag', () async {
        await voiceService.initialize();

        // Create mock STT service that emits result without isFinal flag
        final mockSTTWithoutFinalFlag = MockSTTServiceWithoutFinalFlag();
        final voiceServiceWithMock = VoiceServiceImpl(
          sttService: mockSTTWithoutFinalFlag,
          ttsService: mockTTSService,
        );
        await voiceServiceWithMock.initialize();

        String? capturedQuestion;

        voiceServiceWithMock.startContinuousListening(
          onQuestionDetected: (text) {
            capturedQuestion = text;
          },
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        );

        // Wait for stream to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify question was captured despite isFinal being false
        expect(capturedQuestion, 'hello how are you');
      });

      test('captures latest text when multiple results received', () async {
        await voiceService.initialize();

        // Create mock STT service that emits multiple partial results
        final mockSTTWithPartialResults = MockSTTServiceWithPartialResults();
        final voiceServiceWithMock = VoiceServiceImpl(
          sttService: mockSTTWithPartialResults,
          ttsService: mockTTSService,
        );
        await voiceServiceWithMock.initialize();

        String? capturedQuestion;

        voiceServiceWithMock.startContinuousListening(
          onQuestionDetected: (text) {
            capturedQuestion = text;
          },
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        );

        // Wait for stream to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify latest recognized text was captured
        expect(capturedQuestion, 'what is machine learning');
      });

      test('does not capture empty or whitespace-only text', () async {
        await voiceService.initialize();

        // Create mock STT service that emits empty result
        final mockSTTWithEmptyResult = MockSTTServiceWithEmptyResult();
        final voiceServiceWithMock = VoiceServiceImpl(
          sttService: mockSTTWithEmptyResult,
          ttsService: mockTTSService,
        );
        await voiceServiceWithMock.initialize();

        String? capturedQuestion;

        voiceServiceWithMock.startContinuousListening(
          onQuestionDetected: (text) {
            capturedQuestion = text;
          },
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        );

        // Wait for stream to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify no question was captured (callback not invoked)
        expect(capturedQuestion, null);
      });

      test('stops continuous listening and cancels subscription', () async {
        await voiceService.initialize();

        voiceService.startContinuousListening(
          onQuestionDetected: (text) {},
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        );

        expect(voiceService.isContinuousListening, true);

        await voiceService.stopContinuousListening();

        expect(voiceService.isContinuousListening, false);
        expect(mockSTTService.isListening, false);
      });

      test('restarts listening cycle when no text detected (silence)', () async {
        await voiceService.initialize();

        // Create mock that simulates silence (no text)
        final mockSTTSilence = MockSTTServiceWithSilence();
        final voiceServiceWithMock = VoiceServiceImpl(
          sttService: mockSTTSilence,
          ttsService: mockTTSService,
        );
        await voiceServiceWithMock.initialize();

        int questionDetectedCount = 0;

        voiceServiceWithMock.startContinuousListening(
          onQuestionDetected: (text) {
            questionDetectedCount++;
          },
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 60),
        );

        // Wait for first silence cycle + restart delay (500ms) + processing time
        // Need at least 700ms for cycle to complete and restart to begin
        await Future.delayed(const Duration(milliseconds: 800));

        // No question should be detected
        expect(questionDetectedCount, 0);

        // But listening should restart (check call count increased)
        expect(mockSTTSilence.startListeningCallCount, greaterThan(1));
      });

      test('handles multiple question cycles correctly', () async {
        await voiceService.initialize();

        // Create mock that returns questions on each call
        final mockSTTMultiple = MockSTTServiceMultipleQuestions();
        final voiceServiceWithMock = VoiceServiceImpl(
          sttService: mockSTTMultiple,
          ttsService: mockTTSService,
        );
        await voiceServiceWithMock.initialize();

        final detectedQuestions = <String>[];

        voiceServiceWithMock.startContinuousListening(
          onQuestionDetected: (text) {
            detectedQuestions.add(text);
          },
          pauseFor: const Duration(milliseconds: 50),
          listenFor: const Duration(milliseconds: 100),
        );

        // Wait for the listening cycle to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Should detect exactly 1 question
        // The implementation does NOT auto-restart after detecting a question
        // It only auto-restarts after silence (no text detected)
        expect(detectedQuestions.length, 1);
        expect(detectedQuestions[0], 'question 1');

        // Clean up
        await voiceServiceWithMock.stopContinuousListening();
      });
    });
  });
}

/// Mock STT Service that simulates silence (empty results)
class MockSTTServiceWithSilence implements STTService {
  bool _isListening = false;
  int startListeningCallCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    _isListening = true;
    startListeningCallCount++;
    // Return empty stream (silence - no text detected)
    return Stream.value(
      SpeechRecognitionResult(
        recognizedText: '',
        confidence: 0.0,
        isFinal: false,
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
  Future<void> dispose() async {}
}

/// Mock STT Service that simulates multiple questions across cycles
/// Each call returns a different question to verify cycle restarts
class MockSTTServiceMultipleQuestions implements STTService {
  bool _isListening = false;
  int _cycleCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    _isListening = true;
    _cycleCount++;

    // Always return a question (test simulates manual restart after detection)
    return Stream.value(
      SpeechRecognitionResult(
        recognizedText: 'question $_cycleCount',
        confidence: 0.9,
        isFinal: false,
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
  Future<void> dispose() async {}
}

/// Mock STT Service that emits result without isFinal flag
class MockSTTServiceWithoutFinalFlag implements STTService {
  bool _isListening = false;

  @override
  Future<void> initialize() async {}

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    _isListening = true;
    return Stream.fromIterable([
      SpeechRecognitionResult(
        recognizedText: 'hello how are you',
        confidence: 0.8,
        isFinal: false, // Not marked as final
      ),
    ]);
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
  Future<void> dispose() async {}
}

/// Mock STT Service that emits multiple partial results
class MockSTTServiceWithPartialResults implements STTService {
  bool _isListening = false;

  @override
  Future<void> initialize() async {}

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    _isListening = true;
    return Stream.fromIterable([
      SpeechRecognitionResult(
        recognizedText: 'what',
        confidence: 0.5,
        isFinal: false,
      ),
      SpeechRecognitionResult(
        recognizedText: 'what is',
        confidence: 0.6,
        isFinal: false,
      ),
      SpeechRecognitionResult(
        recognizedText: 'what is machine learning',
        confidence: 0.9,
        isFinal: false,
      ),
    ]);
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
  Future<void> dispose() async {}
}

/// Mock STT Service that emits empty result
class MockSTTServiceWithEmptyResult implements STTService {
  bool _isListening = false;

  @override
  Future<void> initialize() async {}

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    _isListening = true;
    return Stream.fromIterable([
      SpeechRecognitionResult(
        recognizedText: '',
        confidence: 0.0,
        isFinal: false,
      ),
      SpeechRecognitionResult(
        recognizedText: '   ',
        confidence: 0.0,
        isFinal: false,
      ),
    ]);
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
  Future<void> dispose() async {}
}
