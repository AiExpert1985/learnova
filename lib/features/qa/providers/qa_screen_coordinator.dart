import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/voice/voice_models.dart';
import '../state/qa_state.dart';
import '../utils/qa_actions.dart';
import '../widgets/video_player.dart';

/// Coordinator for QA screen interactions between Voice, QA, and Video features.
/// Handles reactive coordination logic that was previously in the screen widget.
class QAScreenCoordinator {
  final WidgetRef _ref;

  // Lifecycle state - tracks if we were in continuous mode before app paused
  bool wasInContinuousMode = false;

  // Auto-enable flag - prevents multiple auto-enable attempts per video
  bool _autoEnabledContinuousMode = false;

  // Track last video ID to detect video changes
  String? _lastVideoId;

  QAScreenCoordinator(this._ref);

  /// Set up all reactive listeners for state coordination.
  /// Call this in the build method - Riverpod handles deduplication.
  void setupListeners() {
    _listenForVoiceStateChanges();
    _listenForQAStateChanges();
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleChange(AppLifecycleState state) {
    final voiceNotifier = _ref.read(voiceNotifierProvider.notifier);
    final voiceState = _ref.read(voiceNotifierProvider);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (voiceState.isContinuousModeEnabled) {
        wasInContinuousMode = true;
        voiceNotifier.stopContinuousMode();
      }
    }
  }

  /// Check if should show resume dialog after app resume
  bool shouldShowResumeDialog() {
    if (wasInContinuousMode) {
      wasInContinuousMode = false;
      return true;
    }
    return false;
  }

  /// Resume continuous mode (called from dialog confirmation)
  void resumeContinuousMode() {
    toggleContinuousModeWithVideo(_ref);
  }

  void _listenForVoiceStateChanges() {
    _ref.listen(voiceNotifierProvider, (previous, next) {
      // Video control: Resume video when transitioning from waiting to listening
      if (next.continuousListeningState == ContinuousListeningState.listening &&
          previous?.continuousListeningState ==
              ContinuousListeningState.waitingForNextQuestion) {
        _ref.read(youtubeControllerProvider)?.playVideo();
      }

      // Video control: Pause video when speaking starts
      if (next.isSpeaking && !(previous?.isSpeaking ?? false)) {
        _ref.read(youtubeControllerProvider)?.pauseVideo();
      }
    });
  }

  void _listenForQAStateChanges() {
    _ref.listen(qaNotifierProvider, (previous, next) {
      _handleAutoSpeak(previous, next);
      _handleAutoEnableContinuousMode(previous, next);
      _handleVideoCleared(next);
    });
  }

  void _handleAutoSpeak(QAState? previous, QAState next) {
    final prevLen = previous?.history.length ?? 0;
    if (next.history.length > prevLen) {
      final lastEntry = next.history.last;
      if (lastEntry.hasAnswer) {
        final voiceState = _ref.read(voiceNotifierProvider);
        // Speak if continuous mode OR if input was voice
        if (voiceState.isContinuousModeEnabled) {
          _ref
              .read(voiceNotifierProvider.notifier)
              .speakAnswerAndResume(lastEntry.answer!);
        } else if (next.lastInputMethod == InputMethod.voice) {
          _ref.read(voiceNotifierProvider.notifier).speak(lastEntry.answer!);
        }
      }
    }
  }

  void _handleAutoEnableContinuousMode(QAState? previous, QAState next) {
    // Only trigger on video becoming ready
    if (!next.hasVideo || next.isLoadingVideo) return;

    // Detect if this is a new video load
    final isNewVideo = previous?.hasVideo == false ||
        (previous?.videoId != next.videoId && next.videoId != _lastVideoId);

    if (isNewVideo && !_autoEnabledContinuousMode) {
      _autoEnabledContinuousMode = true;
      _lastVideoId = next.videoId;

      // Use microtask to avoid building-phase side effects
      Future.microtask(() async {
        // Check headphones silently - no dialog on auto-start
        final audioService = _ref.read(audioDeviceServiceProvider);
        if (await audioService.areHeadphonesConnected()) {
          toggleContinuousModeWithVideo(_ref);
        }
      });
    }
  }

  void _handleVideoCleared(QAState next) {
    if (!next.hasVideo) {
      _autoEnabledContinuousMode = false;
      _lastVideoId = null;
    }
  }
}
