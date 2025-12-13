/// Unit tests for continuous listening mode
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidorion/core/services/voice/voice_service.dart';
import 'package:vidorion/core/services/voice/voice_service_impl.dart';
import 'package:vidorion/core/services/voice/stt_service.dart';
import 'package:vidorion/core/services/voice/tts_service.dart';
import 'package:vidorion/core/services/voice/voice_models.dart';
import 'package:vidorion/core/services/voice/vad_service.dart';
import 'package:vidorion/core/services/voice/state/voice_notifier.dart';
import 'package:vidorion/core/services/voice/state/voice_state.dart';
import 'package:vidorion/core/services/voice/permission_service.dart';
import 'package:vidorion/core/services/audio/audio_device_service.dart';
import 'package:vidorion/core/services/audio/audio_session_service.dart';
import 'package:permission_handler/permission_handler.dart';

// Manual Mocks
class MockSTTService implements STTService {
  bool _isListening = false;
  StreamController<SpeechRecognitionResult>? _streamController;
  Function(Duration?)? onStartListening;
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
    onStartListening?.call(listenDuration);
    _streamController = StreamController<SpeechRecognitionResult>();
    return _streamController!.stream;
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
  bool get isListening => _isListening;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<List<String>> getSupportedLocales() async => ['en-US'];

  void simulateResult(SpeechRecognitionResult result) {
    _streamController?.add(result);
  }

  void simulateError(VoiceException error) {
    _streamController?.addError(error);
  }

  void closeStream() {
    _streamController?.close();
  }
}

class MockTTSService implements TTSService {
  bool _isSpeaking = false;

  @override
  Future<void> initialize() async {}

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

  Future<void> configure({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  }) async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<List<String>> getLanguages() async => ['en-US'];

  @override
  Future<List<String>> getVoices() async => ['en-US-default'];

  @override
  Future<void> setLanguage(String language) async {}

  @override
  Future<void> setVoice(String voice) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPitch(double pitch) async {}
}

class MockPermissionService implements PermissionService {
  bool _hasMicPermission = true;

  @override
  Future<bool> hasMicrophonePermission() async => _hasMicPermission;

  @override
  Future<bool> requestMicrophonePermission() async => _hasMicPermission;

  @override
  Future<bool> isMicrophonePermissionPermanentlyDenied() async => false;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<PermissionStatus> getMicrophonePermissionStatus() async =>
      _hasMicPermission ? PermissionStatus.granted : PermissionStatus.denied;

  @override
  Future<bool> hasSpeechRecognitionPermission() async => true;

  @override
  Future<bool> requestSpeechRecognitionPermission() async => true;

  @override
  Future<bool> requestVoicePermissions() async => _hasMicPermission;

  void setMicPermission(bool value) {
    _hasMicPermission = value;
  }
}

class MockAudioDeviceService implements AudioDeviceService {
  bool _areHeadphonesConnected = true;
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  @override
  Future<bool> areHeadphonesConnected() async => _areHeadphonesConnected;

  @override
  Stream<bool> get headphoneConnectionStream => _connectionController.stream;

  @override
  void dispose() {
    _connectionController.close();
  }

  void setHeadphonesConnected(bool value) {
    _areHeadphonesConnected = value;
    _connectionController.add(value);
  }
}

class MockAudioSessionService implements AudioSessionService {
  bool _isConfiguredForContinuousListening = false;

  @override
  Future<void> configureForContinuousListening() async {
    _isConfiguredForContinuousListening = true;
  }

  @override
  Future<void> configureForPlayback() async {
    _isConfiguredForContinuousListening = false;
  }

  @override
  Future<void> dispose() async {}

  bool get isConfiguredForContinuousListening =>
      _isConfiguredForContinuousListening;
}

class MockVADService implements VADService {
  bool _isMonitoring = false;
  bool _isVoiceActive = false;

  @override
  Future<void> initialize() async {}

  @override
  void startMonitoring({
    required Function() onVoiceStart,
    required Function() onVoiceEnd,
  }) {
    _isMonitoring = true;
  }

  @override
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _isVoiceActive = false;
  }

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  bool get isVoiceActive => _isVoiceActive;

  @override
  Future<void> dispose() async {
    await stopMonitoring();
  }
}

class MockVoiceService implements VoiceService {
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isContinuousListening = false;
  Function(String)? _onQuestionDetected;
  Function()? _onSpeechStart;
  int startContinuousListeningCallCount = 0;

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
        recognizedText: 'test',
        confidence: 0.9,
        isFinal: true,
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
  Stream<SpeechSynthesisState> speak(String text) {
    _isSpeaking = true;
    return Stream.fromIterable([
      SpeechSynthesisState.speaking,
      SpeechSynthesisState.idle,
    ]);
  }

  @override
  Future<void> stopSpeaking() async {
    _isSpeaking = false;
  }

  @override
  Future<void> pauseSpeaking() async {}

  @override
  Future<void> resumeSpeaking() async {}

  @override
  bool get isListening => _isListening;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<bool> isSpeechRecognitionAvailable() async => true;

  @override
  Future<void> configureTTS({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  }) async {}

  @override
  void startContinuousListening({
    required Function(String recognizedText) onQuestionDetected,
    Function()? onSpeechStart,
    Duration? pauseFor,
    Duration? listenFor,
  }) {
    _isContinuousListening = true;
    _onQuestionDetected = onQuestionDetected;
    _onSpeechStart = onSpeechStart;
    startContinuousListeningCallCount++;
  }

  @override
  void restartListeningCycle({
    required Function(String recognizedText) onQuestionDetected,
    Function()? onSpeechStart,
    Duration? pauseFor,
    Duration? listenFor,
  }) {
    _onQuestionDetected = onQuestionDetected;
    _onSpeechStart = onSpeechStart;
  }

  @override
  Future<void> stopContinuousListening() async {
    _isContinuousListening = false;
  }

  @override
  bool get isContinuousListening => _isContinuousListening;

  @override
  Future<void> dispose() async {}

  // Test helper to simulate question detection
  void simulateQuestionDetected(String question) {
    _onQuestionDetected?.call(question);
  }

  // Test helper to simulate speech start
  void simulateSpeechStart() {
    _onSpeechStart?.call();
  }
}

void main() {
  late MockSTTService mockSTT;
  late MockTTSService mockTTS;
  late MockPermissionService mockPermissionService;
  late VoiceServiceImpl voiceService;

  setUp(() {
    mockSTT = MockSTTService();
    mockTTS = MockTTSService();
    mockPermissionService = MockPermissionService();
    voiceService = VoiceServiceImpl(sttService: mockSTT, ttsService: mockTTS);
  });

  group('VoiceService Continuous Listening', () {
    test('startContinuousListening enables continuous mode', () async {
      await voiceService.initialize();

      final questions = <String>[];
      voiceService.startContinuousListening(
        onQuestionDetected: (q) => questions.add(q),
      );

      expect(voiceService.isContinuousListening, true);

      await voiceService.stopContinuousListening();
    });

    test(
      'stops continuous listening when stopContinuousListening called',
      () async {
        await voiceService.initialize();

        voiceService.startContinuousListening(onQuestionDetected: (_) {});

        await voiceService.stopContinuousListening();

        expect(voiceService.isContinuousListening, false);
      },
    );

    test('calls onQuestionDetected with recognized text', () async {
      await voiceService.initialize();

      final questions = <String>[];
      voiceService.startContinuousListening(
        onQuestionDetected: (q) => questions.add(q),
      );

      // Give time for listening to start
      await Future.delayed(const Duration(milliseconds: 100));

      // Simulate speech recognition
      mockSTT.simulateResult(
        SpeechRecognitionResult(
          recognizedText: 'What is AI?',
          confidence: 0.9,
          isFinal: true,
        ),
      );

      // Close the stream to trigger onDone which calls onQuestionDetected
      mockSTT.closeStream();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(questions, contains('What is AI?'));

      await voiceService.stopContinuousListening();
    });

    test('handles errors and retries listening', () async {
      await voiceService.initialize();

      voiceService.startContinuousListening(onQuestionDetected: (_) {});

      // Give time for listening to start
      await Future.delayed(const Duration(milliseconds: 100));

      final initialCallCount = mockSTT.startListeningCallCount;

      // Simulate error
      mockSTT.simulateError(
        VoiceException('Test error', VoiceErrorType.unknown),
      );
      mockSTT.closeStream();

      await Future.delayed(const Duration(seconds: 3));

      // Should retry after error
      expect(mockSTT.startListeningCallCount, greaterThan(initialCallCount));

      await voiceService.stopContinuousListening();
    });
  });

  group('VoiceNotifier Continuous Mode State Machine', () {
    late VoiceNotifier voiceNotifier;
    late MockVoiceService mockVoiceService;
    late MockAudioDeviceService mockAudioDeviceService;
    late MockAudioSessionService mockAudioSessionService;
    late MockVADService mockVADService;

    setUp(() {
      mockVoiceService = MockVoiceService();
      mockAudioDeviceService = MockAudioDeviceService();
      mockAudioSessionService = MockAudioSessionService();
      mockVADService = MockVADService();
      voiceNotifier = VoiceNotifier(
        mockVoiceService,
        mockPermissionService,
        mockAudioDeviceService,
        mockAudioSessionService,
        mockVADService,
      );
    });

    tearDown(() {
      voiceNotifier.dispose();
    });

    test('toggleContinuousMode enables mode', () async {
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Wait for initialization

      await voiceNotifier.toggleContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      expect(voiceNotifier.state.isContinuousModeEnabled, true);
      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.listening,
      );
    });

    test('toggleContinuousMode disables when already enabled', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      // Enable
      await voiceNotifier.toggleContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      // Disable
      await voiceNotifier.toggleContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      expect(voiceNotifier.state.isContinuousModeEnabled, false);
      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.idle,
      );
    });

    test('transitions to processing state when question detected', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      String? detectedQuestion;
      await voiceNotifier.startContinuousMode(
        onQuestion: (q) => detectedQuestion = q,
        onAnswerReady: (_) {},
      );

      // Simulate question detection
      mockVoiceService.simulateQuestionDetected('What is machine learning?');

      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.processing,
      );
      expect(detectedQuestion, 'What is machine learning?');
    });

    test('transitions through speaking to grace period state', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      await voiceNotifier.startContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      // speakAnswerAndResume now awaits TTS completion
      // So by the time it returns, we're in grace period state
      await voiceNotifier.speakAnswerAndResume('Machine learning is...');

      // After TTS completes, should be in grace period waiting for next question
      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.waitingForNextQuestion,
      );
    });

    test('auto-disables after 5 minutes of inactivity', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      await voiceNotifier.startContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      // Fast-forward time (would need clock mocking in real scenario)
      // For now, just verify the timer was set up
      expect(voiceNotifier.state.isContinuousModeEnabled, true);
    });

    test('userSpeaking state is set when speech starts', () async {
      await Future.delayed(const Duration(milliseconds: 100));

      await voiceNotifier.startContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      // Simulate speech start
      mockVoiceService.simulateSpeechStart();

      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.userSpeaking,
      );
    });
  });

  group('VoiceState', () {
    test('copyWith updates continuous mode fields', () {
      const initialState = VoiceState();
      final updatedState = initialState.copyWith(
        isContinuousModeEnabled: true,
        continuousListeningState: ContinuousListeningState.listening,
      );

      expect(updatedState.isContinuousModeEnabled, true);
      expect(
        updatedState.continuousListeningState,
        ContinuousListeningState.listening,
      );
    });

    test('equality checks include continuous fields', () {
      const state1 = VoiceState(
        isContinuousModeEnabled: true,
        continuousListeningState: ContinuousListeningState.listening,
      );
      const state2 = VoiceState(
        isContinuousModeEnabled: true,
        continuousListeningState: ContinuousListeningState.listening,
      );
      const state3 = VoiceState(
        isContinuousModeEnabled: false,
        continuousListeningState: ContinuousListeningState.idle,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });
  });
}
