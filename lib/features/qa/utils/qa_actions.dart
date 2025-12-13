import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

/// Toggles continuous listening mode with video integration
Future<void> toggleContinuousModeWithVideo(WidgetRef ref) async {
  final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
  final qaNotifier = ref.read(qaNotifierProvider.notifier);

  await voiceNotifier.toggleContinuousMode(
    onQuestion: (question) async {
      // Process question through QA service
      qaNotifier.askQuestion(question, isContinuousMode: true);
    },
    onAnswerReady: (answer) {
      // This is called if TTS fails, to display answer as text
      // The answer is already in the QA history, so nothing to do here
    },
  );
}
