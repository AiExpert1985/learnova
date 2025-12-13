import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidorion/core/services/voice/state/voice_notifier.dart';
import 'package:vidorion/core/services/voice/voice_service.dart';
import 'package:vidorion/core/services/voice/permission_service.dart';
import 'package:vidorion/core/services/voice/voice_models.dart';
import 'package:vidorion/core/services/voice/vad_service.dart';
import 'package:vidorion/core/services/audio/audio_device_service.dart';
import 'package:vidorion/core/services/audio/audio_session_service.dart';

/// Mock Voice Service for testing
class MockVoiceService implements VoiceService {
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isContinuousListening = false;
  List<SpeechRecognitionResult>? _customResults;
  Function(String)? _onQuestionCallback;
  Function()? _onSpeechStartCallback;

  @override
  Future<void> initialize() async {
    // Mock initialization - no state to track
  }

  /// Set custom results for testing specific scenarios
  void setCustomResults(List<SpeechRecognitionResult> results) {
    _customResults = results;
  }

  /// Simulate detecting a question in continuous mode
  void simulateQuestionDetected(String question) {
    _onQuestionCallback?.call(question);
  }

  /// Simulate speech start in continuous mode
  void simulateSpeechStart() {
    _onSpeechStartCallback?.call();
  }

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    _isListening = true;
    // Use custom results if set, otherwise use default
    if (_customResults != null) {
      final results = _customResults!;
      _customResults = null; // Reset after use
      return Stream.fromIterable(results);
    }
    return Stream.fromIterable([
      SpeechRecognitionResult(
        recognizedText: 'partial text',
        confidence: 0.7,
        isFinal: false,
      ),
      SpeechRecognitionResult(
        recognizedText: 'final recognized text',
        confidence: 0.95,
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
    _onQuestionCallback = onQuestionDetected;
    _onSpeechStartCallback = onSpeechStart;
  }

  @override
  void restartListeningCycle({
    required Function(String recognizedText) onQuestionDetected,
    Function()? onSpeechStart,
    Duration? pauseFor,
    Duration? listenFor,
  }) {
    // Mock implementation - restart listening cycle
    _onQuestionCallback = onQuestionDetected;
    _onSpeechStartCallback = onSpeechStart;
  }

  @override
  Future<void> stopContinuousListening() async {
    _isContinuousListening = false;
    _onQuestionCallback = null;
    _onSpeechStartCallback = null;
  }

  @override
  bool get isContinuousListening => _isContinuousListening;

  @override
  Future<void> dispose() async {
    // Mock disposal - no state to clean up
  }
}

/// Mock Permission Service for testing
class MockPermissionService extends PermissionService {
  bool _hasMicPermission = true;

  @override
  Future<bool> hasMicrophonePermission() async => _hasMicPermission;

  @override
  Future<bool> requestMicrophonePermission() async => _hasMicPermission;

  @override
  Future<bool> isMicrophonePermissionPermanentlyDenied() async => false;

  void setMicPermission(bool value) {
    _hasMicPermission = value;
  }
}

/// Mock Audio Device Service for testing
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

/// Mock Audio Session Service for testing
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

/// Mock VAD Service for testing
class MockVADService implements VADService {
  bool _isMonitoring = false;
  bool _isVoiceActive = false;
  Function()? _onVoiceStart;
  Function()? _onVoiceEnd;

  @override
  Future<void> initialize() async {}

  @override
  void startMonitoring({
    required Function() onVoiceStart,
    required Function() onVoiceEnd,
  }) {
    _isMonitoring = true;
    _onVoiceStart = onVoiceStart;
    _onVoiceEnd = onVoiceEnd;
  }

  @override
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _onVoiceStart = null;
    _onVoiceEnd = null;
  }

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  bool get isVoiceActive => _isVoiceActive;

  @override
  Future<void> dispose() async {
    await stopMonitoring();
  }

  /// Simulate voice detected
  void simulateVoiceStart() {
    _isVoiceActive = true;
    _onVoiceStart?.call();
  }

  /// Simulate voice ended
  void simulateVoiceEnd() {
    _isVoiceActive = false;
    _onVoiceEnd?.call();
  }
}

void main() {
  group('VoiceNotifier', () {
    late VoiceNotifier voiceNotifier;
    late MockVoiceService mockVoiceService;
    late MockPermissionService mockPermissionService;
    late MockAudioDeviceService mockAudioDeviceService;
    late MockAudioSessionService mockAudioSessionService;
    late MockVADService mockVADService;

    setUp(() {
      mockVoiceService = MockVoiceService();
      mockPermissionService = MockPermissionService();
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

    test('initial state is correct', () {
      expect(voiceNotifier.state.isListening, false);
      expect(voiceNotifier.state.isSpeaking, false);
      expect(voiceNotifier.state.recognizedText, '');
      expect(voiceNotifier.state.error, null);
    });

    test(
      'startListening waits for stream completion and returns final text',
      () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await voiceNotifier.startListening();

        // Should return the final recognized text
        expect(result, 'final recognized text');
        expect(voiceNotifier.state.recognizedText, 'final recognized text');
        expect(voiceNotifier.state.isListening, false);
      },
    );

    test('startListening requests permission if needed', () async {
      mockPermissionService.setMicPermission(false);

      final result = await voiceNotifier.startListening();

      expect(result, null);
      expect(voiceNotifier.state.error, isNotNull);
    });

    test('stopListening updates state', () async {
      await voiceNotifier.startListening();
      await voiceNotifier.stopListening();

      expect(voiceNotifier.state.isListening, false);
    });

    test('cancelListening clears recognized text', () async {
      await voiceNotifier.startListening();
      await Future.delayed(const Duration(milliseconds: 50));
      await voiceNotifier.cancelListening();

      expect(voiceNotifier.state.isListening, false);
      expect(voiceNotifier.state.recognizedText, '');
    });

    test('speak updates state', () async {
      await voiceNotifier.speak('test answer');

      // Give time for stream to emit values
      await Future.delayed(const Duration(milliseconds: 100));

      expect(voiceNotifier.state.isSpeaking, false);
      expect(voiceNotifier.state.synthesisState, SpeechSynthesisState.idle);
    });

    test('stopSpeaking updates state', () async {
      await voiceNotifier.speak('test');
      await voiceNotifier.stopSpeaking();

      expect(voiceNotifier.state.isSpeaking, false);
    });

    test('clearError removes error from state', () {
      voiceNotifier.state = voiceNotifier.state.copyWith(error: 'test error');

      voiceNotifier.clearError();

      expect(voiceNotifier.state.error, isNull);
    });

    test(
      'startListening captures last text even without isFinal flag',
      () async {
        // Setup: mock results without isFinal=true
        mockVoiceService.setCustomResults([
          SpeechRecognitionResult(
            recognizedText: 'first update',
            confidence: 0.7,
            isFinal: false,
          ),
          SpeechRecognitionResult(
            recognizedText: 'second update',
            confidence: 0.8,
            isFinal: false,
          ),
          SpeechRecognitionResult(
            recognizedText: 'last recognized text',
            confidence: 0.9,
            isFinal: false, // No final flag
          ),
        ]);

        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final result = await voiceNotifier.startListening();

        // Should return the last recognized text even without isFinal=true
        expect(result, 'last recognized text');
        expect(voiceNotifier.state.recognizedText, 'last recognized text');
        expect(voiceNotifier.state.isListening, false);
      },
    );

    test('continuous mode requires headphones', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      mockAudioDeviceService.setHeadphonesConnected(false);

      await voiceNotifier.startContinuousMode(
        onQuestion: (question) {},
        onAnswerReady: (answer) {},
      );

      // Should have headphone required error
      expect(voiceNotifier.state.error, 'headphone_required');
      expect(voiceNotifier.state.isContinuousModeEnabled, false);
    });

    test('continuous mode starts when headphones connected', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      mockAudioDeviceService.setHeadphonesConnected(true);

      await voiceNotifier.startContinuousMode(
        onQuestion: (question) {},
        onAnswerReady: (answer) {},
      );

      // Should start continuous mode
      expect(voiceNotifier.state.isContinuousModeEnabled, true);
      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.listening,
      );
      // Audio session should be configured
      expect(mockAudioSessionService.isConfiguredForContinuousListening, true);
    });

    test('continuous mode stops when headphones disconnect', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      mockAudioDeviceService.setHeadphonesConnected(true);

      await voiceNotifier.startContinuousMode(
        onQuestion: (question) {},
        onAnswerReady: (answer) {},
      );

      expect(voiceNotifier.state.isContinuousModeEnabled, true);

      // Disconnect headphones
      mockAudioDeviceService.setHeadphonesConnected(false);

      // Wait for event to propagate
      await Future.delayed(const Duration(milliseconds: 100));

      // Should stop continuous mode
      expect(voiceNotifier.state.isContinuousModeEnabled, false);
    });

    test('userSpeaking state is set when speech starts', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      mockAudioDeviceService.setHeadphonesConnected(true);

      await voiceNotifier.startContinuousMode(
        onQuestion: (question) {},
        onAnswerReady: (answer) {},
      );

      // Simulate speech start
      mockVoiceService.simulateSpeechStart();

      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.userSpeaking,
      );
    });

    test('question callback is triggered on question detection', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      mockAudioDeviceService.setHeadphonesConnected(true);

      String? detectedQuestion;
      await voiceNotifier.startContinuousMode(
        onQuestion: (question) {
          detectedQuestion = question;
        },
        onAnswerReady: (answer) {},
      );

      // Simulate question detected
      mockVoiceService.simulateQuestionDetected('What is Flutter?');

      expect(detectedQuestion, 'What is Flutter?');
      expect(
        voiceNotifier.state.continuousListeningState,
        ContinuousListeningState.processing,
      );
      expect(voiceNotifier.state.recognizedText, 'What is Flutter?');
    });

    test('stopContinuousMode resets audio session', () async {
      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      mockAudioDeviceService.setHeadphonesConnected(true);

      await voiceNotifier.startContinuousMode(
        onQuestion: (question) {},
        onAnswerReady: (answer) {},
      );

      expect(mockAudioSessionService.isConfiguredForContinuousListening, true);

      await voiceNotifier.stopContinuousMode();

      expect(voiceNotifier.state.isContinuousModeEnabled, false);
      expect(
        mockAudioSessionService.isConfiguredForContinuousListening,
        false,
      );
    });

    test('error is preserved when other state fields are updated', () async {
      // This test verifies the fix for the race condition where
      // _initialize() completing would clear errors set by startListening()

      // Don't wait for initialization - trigger the race condition scenario
      mockPermissionService.setMicPermission(false);

      // Start listening (should fail due to permission)
      final result = await voiceNotifier.startListening();

      // Result should be null (failed)
      expect(result, isNull);

      // Wait for initialization to complete (if it hasn't already)
      await Future.delayed(const Duration(milliseconds: 150));

      // The key assertion: error should NOT be cleared by _initialize()
      // completing after startListening set the error
      // The error message could be either:
      // - 'Voice service not initialized' (if init hasn't completed)
      // - 'Microphone permission denied' (if init completed before startListening)
      expect(voiceNotifier.state.error, isNotNull);
    });
  });
}
