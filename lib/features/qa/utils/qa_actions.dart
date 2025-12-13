import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

/// Toggles continuous listening mode with video integration
/// Video control is handled by QAScreenCoordinator via state transitions:
/// - Pause: on userSpeaking state (user STARTS speaking)
/// - Resume: on listening state after grace period
Future<void> toggleContinuousModeWithVideo(WidgetRef ref) async {
  final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
  final qaNotifier = ref.read(qaNotifierProvider.notifier);

  await voiceNotifier.toggleContinuousMode(
    onQuestion: (question) {
      // Process question through QA service
      // Video pause is handled by QAScreenCoordinator on userSpeaking state
      qaNotifier.askQuestion(question, isContinuousMode: true);
    },
    onAnswerReady: (answer) {
      // This is called if TTS fails, to display answer as text
      // The answer is already in the QA history, so nothing to do here
    },
    // onSpeechStart is handled internally by VoiceNotifier
    // which triggers state change to userSpeaking
    // QAScreenCoordinator listens and pauses video
  );
}
