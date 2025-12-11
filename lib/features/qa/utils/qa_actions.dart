import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/video_player.dart';

/// Toggles continuous listening mode with video integration
/// Pauses video when speaking, resumes via callback (handled in initialization)
Future<void> toggleContinuousModeWithVideo(WidgetRef ref) async {
  final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
  final qaNotifier = ref.read(qaNotifierProvider.notifier);
  final videoController = ref.read(youtubeControllerProvider);

  await voiceNotifier.toggleContinuousMode(
    onQuestion: (question) async {
      // Pause video when user speaks
      if (videoController != null) {
        final playerState = await videoController.playerState;
        if (playerState == PlayerState.playing) {
          await videoController.pauseVideo();
        }
      }

      // Process question through QA service
      qaNotifier.askQuestion(question, isContinuousMode: true);
    },
    onAnswerReady: (answer) {
      // This is called if TTS fails, to display answer as text
      // The answer is already in the QA history, so nothing to do here
    },
  );
}
