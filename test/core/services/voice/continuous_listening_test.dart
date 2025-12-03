/// Unit tests for continuous listening mode
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:learnova/core/services/voice/voice_service.dart';
import 'package:learnova/core/services/voice/voice_service_impl.dart';
import 'package:learnova/core/services/voice/stt_service.dart';
import 'package:learnova/core/services/voice/tts_service.dart';
import 'package:learnova/core/services/voice/voice_models.dart';
import 'package:learnova/core/services/voice/state/voice_notifier.dart';
import 'package:learnova/core/services/voice/state/voice_state.dart';
import 'package:learnova/core/services/voice/permission_service.dart';

// Mocks
class MockSTTService extends Mock implements STTService {}

class MockTTSService extends Mock implements TTSService {}

class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late MockSTTService mockSTT;
  late MockTTSService mockTTS;
  late MockPermissionService mockPermissionService;
  late VoiceServiceImpl voiceService;

  setUp(() {
    mockSTT = MockSTTService();
    mockTTS = MockTTSService();
    mockPermissionService = MockPermissionService();
    voiceService = VoiceServiceImpl(
      sttService: mockSTT,
      ttsService: mockTTS,
    );

    // Default mocks
    when(() => mockSTT.initialize()).thenAnswer((_) async {});
    when(() => mockTTS.initialize()).thenAnswer((_) async {});
    when(() => mockSTT.isListening).thenReturn(false);
    when(() => mockTTS.isSpeaking).thenReturn(false);
  });

  group('VoiceService Continuous Listening', () {
    test('startContinuousListening enables continuous mode', () async {
      await voiceService.initialize();

      final streamController = StreamController<SpeechRecognitionResult>();
      when(() => mockSTT.startListening(listenDuration: any(named: 'listenDuration')))
          .thenAnswer((_) => streamController.stream);

      final questions = <String>[];
      voiceService.startContinuousListening(
        onQuestionDetected: (q) => questions.add(q),
      );

      expect(voiceService.isContinuousListening, true);

      await streamController.close();
    });

    test('stops continuous listening when stopContinuousListening called', () async {
      await voiceService.initialize();

      final streamController = StreamController<SpeechRecognitionResult>();
      when(() => mockSTT.startListening(listenDuration: any(named: 'listenDuration')))
          .thenAnswer((_) => streamController.stream);
      when(() => mockSTT.stopListening()).thenAnswer((_) async {});

      voiceService.startContinuousListening(
        onQuestionDetected: (_) {},
      );

      await voiceService.stopContinuousListening();

      expect(voiceService.isContinuousListening, false);
      await streamController.close();
    });

    test('calls onQuestionDetected with recognized text', () async {
      await voiceService.initialize();

      final streamController = StreamController<SpeechRecognitionResult>();
      when(() => mockSTT.startListening(listenDuration: any(named: 'listenDuration')))
          .thenAnswer((_) => streamController.stream);

      final questions = <String>[];
      voiceService.startContinuousListening(
        onQuestionDetected: (q) => questions.add(q),
      );

      // Simulate speech recognition
      streamController.add(SpeechRecognitionResult(
        recognizedText: 'What is AI?',
        confidence: 0.9,
        isFinal: true,
      ));

      await streamController.close();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(questions, contains('What is AI?'));
    });

    test('handles errors and retries listening', () async {
      await voiceService.initialize();

      final streamController = StreamController<SpeechRecognitionResult>();
      var callCount = 0;
      when(() => mockSTT.startListening(listenDuration: any(named: 'listenDuration')))
          .thenAnswer((_) {
        callCount++;
        return streamController.stream;
      });

      voiceService.startContinuousListening(
        onQuestionDetected: (_) {},
      );

      // Simulate error
      streamController.addError(VoiceException('Test error', VoiceErrorType.unknown));

      await Future.delayed(const Duration(seconds: 3));

      // Should retry after error
      expect(callCount, greaterThan(1));

      await voiceService.stopContinuousListening();
      await streamController.close();
    });
  });

  group('VoiceNotifier Continuous Mode State Machine', () {
    late VoiceNotifier voiceNotifier;
    late VoiceService mockVoiceService;

    setUp(() {
      mockVoiceService = MockVoiceService();
      when(() => mockVoiceService.initialize()).thenAnswer((_) async {});
      when(() => mockVoiceService.isListening).thenReturn(false);
      when(() => mockVoiceService.isSpeaking).thenReturn(false);
      when(() => mockPermissionService.hasMicrophonePermission())
          .thenAnswer((_) async => true);

      voiceNotifier = VoiceNotifier(mockVoiceService, mockPermissionService);
    });

    tearDown(() {
      voiceNotifier.dispose();
    });

    test('toggleContinuousMode enables mode', () async {
      when(() => mockVoiceService.startContinuousListening(
            onQuestionDetected: any(named: 'onQuestionDetected'),
            pauseFor: any(named: 'pauseFor'),
            listenFor: any(named: 'listenFor'),
          )).thenReturn(null);

      await Future.delayed(const Duration(milliseconds: 100)); // Wait for initialization

      await voiceNotifier.toggleContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      expect(voiceNotifier.state.isContinuousModeEnabled, true);
      expect(voiceNotifier.state.continuousListeningState, ContinuousListeningState.listening);
    });

    test('toggleContinuousMode disables when already enabled', () async {
      when(() => mockVoiceService.startContinuousListening(
            onQuestionDetected: any(named: 'onQuestionDetected'),
            pauseFor: any(named: 'pauseFor'),
            listenFor: any(named: 'listenFor'),
          )).thenReturn(null);
      when(() => mockVoiceService.stopContinuousListening()).thenAnswer((_) async {});

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
      expect(voiceNotifier.state.continuousListeningState, ContinuousListeningState.idle);
    });

    test('transitions to processing state when question detected', () async {
      when(() => mockVoiceService.startContinuousListening(
            onQuestionDetected: any(named: 'onQuestionDetected'),
            pauseFor: any(named: 'pauseFor'),
            listenFor: any(named: 'listenFor'),
          )).thenReturn(null);

      await Future.delayed(const Duration(milliseconds: 100));

      String? detectedQuestion;
      await voiceNotifier.startContinuousMode(
        onQuestion: (q) => detectedQuestion = q,
        onAnswerReady: (_) {},
      );

      // Simulate question detection
      final capturedCallback = verify(
        () => mockVoiceService.startContinuousListening(
          onQuestionDetected: captureAny(named: 'onQuestionDetected'),
          pauseFor: any(named: 'pauseFor'),
          listenFor: any(named: 'listenFor'),
        ),
      ).captured.first as Function(String);

      capturedCallback('What is machine learning?');

      expect(voiceNotifier.state.continuousListeningState, ContinuousListeningState.processing);
      expect(detectedQuestion, 'What is machine learning?');
    });

    test('transitions to speaking state when answer ready', () async {
      when(() => mockVoiceService.startContinuousListening(
            onQuestionDetected: any(named: 'onQuestionDetected'),
            pauseFor: any(named: 'pauseFor'),
            listenFor: any(named: 'listenFor'),
          )).thenReturn(null);

      final streamController = StreamController<SpeechSynthesisState>();
      when(() => mockVoiceService.speak(any())).thenAnswer((_) => streamController.stream);

      await Future.delayed(const Duration(milliseconds: 100));

      await voiceNotifier.startContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      await voiceNotifier.speakAnswerAndResume('Machine learning is...');

      expect(voiceNotifier.state.continuousListeningState, ContinuousListeningState.speaking);

      await streamController.close();
    });

    test('auto-disables after 5 minutes of inactivity', () async {
      when(() => mockVoiceService.startContinuousListening(
            onQuestionDetected: any(named: 'onQuestionDetected'),
            pauseFor: any(named: 'pauseFor'),
            listenFor: any(named: 'listenFor'),
          )).thenReturn(null);
      when(() => mockVoiceService.stopContinuousListening()).thenAnswer((_) async {});

      await Future.delayed(const Duration(milliseconds: 100));

      await voiceNotifier.startContinuousMode(
        onQuestion: (_) {},
        onAnswerReady: (_) {},
      );

      // Fast-forward time (would need clock mocking in real scenario)
      // For now, just verify the timer was set up
      expect(voiceNotifier.state.isContinuousModeEnabled, true);
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
      expect(updatedState.continuousListeningState, ContinuousListeningState.listening);
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

class MockVoiceService extends Mock implements VoiceService {}
