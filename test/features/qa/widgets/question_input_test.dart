import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vidorion/core/providers/app_providers.dart';
import 'package:vidorion/core/services/voice/state/voice_notifier.dart';
import 'package:vidorion/core/services/voice/state/voice_state.dart';
import 'package:vidorion/core/services/voice/voice_service.dart';
import 'package:vidorion/core/services/voice/voice_models.dart';
import 'package:vidorion/core/services/voice/permission_service.dart';
import 'package:vidorion/core/services/audio/audio_device_service.dart';
import 'package:vidorion/features/qa/state/qa_notifier.dart';
import 'package:vidorion/features/qa/state/qa_state.dart';
import 'package:vidorion/features/qa/widgets/question_input.dart';
import 'package:vidorion/features/qa/widgets/video_player.dart';
import 'package:vidorion/features/qa/services/qa_service.dart';
import 'package:vidorion/core/services/youtube/youtube_service.dart';
import 'package:vidorion/features/history/services/history_service.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// Manual Mocks

class FakeVoiceService implements VoiceService {
  @override
  Future<void> initialize() async {}
  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
  }) {
    return const Stream.empty();
  }

  @override
  Future<void> stopListening() async {}
  @override
  Future<void> cancelListening() async {}
  @override
  Stream<SpeechSynthesisState> speak(String text) {
    return const Stream.empty();
  }

  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> pauseSpeaking() async {}
  @override
  Future<void> resumeSpeaking() async {}
  @override
  bool get isListening => false;
  @override
  bool get isSpeaking => false;
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
  }) {}
  @override
  Future<void> stopContinuousListening() async {}
  @override
  bool get isContinuousListening => false;
  @override
  Future<void> dispose() async {}
}

class FakePermissionService implements PermissionService {
  @override
  Future<bool> hasMicrophonePermission() async => true;
  @override
  Future<bool> requestMicrophonePermission() async => true;
  @override
  Future<bool> isMicrophonePermissionPermanentlyDenied() async => false;
  @override
  Future<PermissionStatus> getMicrophonePermissionStatus() async =>
      PermissionStatus.granted;
  @override
  Future<bool> hasSpeechRecognitionPermission() async => true;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> requestSpeechRecognitionPermission() async => true;
  @override
  Future<bool> requestVoicePermissions() async => true;
}

class FakeAudioDeviceService implements AudioDeviceService {
  @override
  Future<bool> areHeadphonesConnected() async => true;

  @override
  Stream<bool> get headphoneConnectionStream => const Stream.empty();

  @override
  void dispose() {}
}

class FakeVoiceNotifier extends VoiceNotifier {
  String? _mockRecognizedText;

  FakeVoiceNotifier()
      : super(
          FakeVoiceService(),
          FakePermissionService(),
          FakeAudioDeviceService(),
        ) {
    state = const VoiceState(isInitialized: true);
  }

  void setMockRecognizedText(String text) {
    _mockRecognizedText = text;
  }

  @override
  Future<String?> startListening() async {
    state = state.copyWith(isListening: true);
    // Simulate async delay
    await Future.delayed(const Duration(milliseconds: 10));
    state = state.copyWith(
      isListening: false,
      recognizedText: _mockRecognizedText,
    );
    return _mockRecognizedText;
  }

  @override
  Future<void> stopListening() async {
    state = state.copyWith(isListening: false);
  }
}

class FakeQAService implements QAService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeYouTubeService implements YouTubeService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeHistoryService implements HistoryService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeQANotifier extends QANotifier {
  String? lastAskedQuestion;

  FakeQANotifier()
    : super(
        qaService: FakeQAService(),
        youtubeService: FakeYouTubeService(),
        historyService: FakeHistoryService(),
      );

  @override
  Future<void> askQuestion(
    String question, {
    bool isContinuousMode = false,
    InputMethod? inputMethod,
  }) async {
    lastAskedQuestion = question;
  }
}

class FakeYoutubePlayerController implements YoutubePlayerController {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #currentTime) return Future.value(0.0);
    return null;
  }

  @override
  Future<void> pauseVideo() async {}

  @override
  Future<void> playVideo() async {}

  @override
  Future<void> loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) async {}

  @override
  Future<double> get currentTime async => 0.0;

  @override
  Future<PlayerState> get playerState async => PlayerState.paused;

  @override
  Stream<YoutubePlayerValue> get stream => const Stream.empty();

  @override
  YoutubePlayerParams get params => const YoutubePlayerParams();

  @override
  Future<void> close() async {}
}

void main() {
  late FakeVoiceNotifier fakeVoiceNotifier;
  late FakeQANotifier fakeQANotifier;
  late FakeYoutubePlayerController fakeVideoController;

  setUp(() {
    fakeVoiceNotifier = FakeVoiceNotifier();
    fakeQANotifier = FakeQANotifier();
    fakeVideoController = FakeYoutubePlayerController();
  });

  testWidgets('Voice input populates text field', (tester) async {
    // Arrange
    fakeVoiceNotifier.setMockRecognizedText('Hello world');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceNotifierProvider.overrideWith((ref) => fakeVoiceNotifier),
          qaNotifierProvider.overrideWith((ref) => fakeQANotifier),
          youtubeControllerProvider.overrideWith((ref) => fakeVideoController),
        ],
        child: const MaterialApp(home: Scaffold(body: QuestionInput())),
      ),
    );

    // Act - Tap microphone button
    await tester.tap(find.byIcon(Icons.mic_none));
    await tester.pump(); // Start animation

    // Wait for async operation to complete
    await tester.pump(const Duration(milliseconds: 100));

    // Pump a few more frames to allow UI updates
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Assert - Check if text field contains the recognized text
    expect(find.text('Hello world'), findsOneWidget);

    // Verify the controller text is updated
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, 'Hello world');
  });

  testWidgets('Submitting text calls askQuestion', (tester) async {
    // Arrange
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceNotifierProvider.overrideWith((ref) => fakeVoiceNotifier),
          qaNotifierProvider.overrideWith((ref) => fakeQANotifier),
          youtubeControllerProvider.overrideWith((ref) => fakeVideoController),
        ],
        child: const MaterialApp(home: Scaffold(body: QuestionInput())),
      ),
    );

    // Act - Enter text and submit
    await tester.enterText(find.byType(TextField), 'Test question');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Assert
    expect(fakeQANotifier.lastAskedQuestion, 'Test question');
  });
}
