import 'package:flutter_test/flutter_test.dart';
import 'package:vidorion/core/services/voice/state/voice_notifier.dart';
import 'package:vidorion/core/services/voice/voice_service.dart';
import 'package:vidorion/core/services/voice/permission_service.dart';
import 'package:vidorion/core/services/voice/voice_models.dart';

/// Mock Voice Service for testing
class MockVoiceService implements VoiceService {
  bool _isListening = false;
  bool _isSpeaking = false;

  @override
  Future<void> initialize() async {
    // Mock initialization - no state to track
  }

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
  }) {
    _isListening = true;
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
    Duration? pauseFor,
    Duration? listenFor,
  }) {
    // Mock implementation - no-op for basic tests
  }

  @override
  Future<void> stopContinuousListening() async {
    // Mock implementation - no-op for basic tests
  }

  @override
  bool get isContinuousListening => false;

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

void main() {
  group('VoiceNotifier', () {
    late VoiceNotifier voiceNotifier;
    late MockVoiceService mockVoiceService;
    late MockPermissionService mockPermissionService;

    setUp(() {
      mockVoiceService = MockVoiceService();
      mockPermissionService = MockPermissionService();
      voiceNotifier = VoiceNotifier(mockVoiceService, mockPermissionService);
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

      expect(voiceNotifier.state.error, '');
    });
  });
}
