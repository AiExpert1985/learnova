import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidorion/core/services/voice/state/voice_state.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/voice/voice_models.dart';
import '../state/qa_state.dart';
import '../utils/qa_actions.dart';
import '../widgets/video_player.dart';

/// State for QA screen coordination
/// Tracks lifecycle and auto-enable flags for cross-feature coordination
class QAScreenCoordinatorState {
  /// True if continuous mode was active before app went to background
  final bool wasInContinuousMode;

  /// True if we've already auto-enabled continuous mode for current video
  final bool hasAutoEnabledForCurrentVideo;

  /// Video ID we last auto-enabled for (prevents duplicate auto-enable)
  final String? lastAutoEnabledVideoId;

  /// True if resume dialog should be shown
  final bool shouldShowResumeDialog;

  const QAScreenCoordinatorState({
    this.wasInContinuousMode = false,
    this.hasAutoEnabledForCurrentVideo = false,
    this.lastAutoEnabledVideoId,
    this.shouldShowResumeDialog = false,
  });

  QAScreenCoordinatorState copyWith({
    bool? wasInContinuousMode,
    bool? hasAutoEnabledForCurrentVideo,
    String? lastAutoEnabledVideoId,
    bool? shouldShowResumeDialog,
  }) {
    return QAScreenCoordinatorState(
      wasInContinuousMode: wasInContinuousMode ?? this.wasInContinuousMode,
      hasAutoEnabledForCurrentVideo:
          hasAutoEnabledForCurrentVideo ?? this.hasAutoEnabledForCurrentVideo,
      lastAutoEnabledVideoId:
          lastAutoEnabledVideoId ?? this.lastAutoEnabledVideoId,
      shouldShowResumeDialog:
          shouldShowResumeDialog ?? this.shouldShowResumeDialog,
    );
  }

  /// Reset auto-enable tracking (called when video cleared)
  QAScreenCoordinatorState resetAutoEnable() {
    return copyWith(
      hasAutoEnabledForCurrentVideo: false,
      lastAutoEnabledVideoId: null,
    );
  }
}

/// Coordinates interactions between QA, Voice, and Video features.
/// Handles reactive logic that spans multiple providers.
class QAScreenCoordinator extends StateNotifier<QAScreenCoordinatorState> {
  final Ref _ref;

  QAScreenCoordinator(this._ref) : super(const QAScreenCoordinatorState()) {
    _setupListeners();
  }

  /// Set up all reactive listeners for cross-feature coordination
  void _setupListeners() {
    // Listen to voice state changes for video control
    _ref.listen(voiceNotifierProvider, _onVoiceStateChanged);

    // Listen to QA state changes for auto-speak and auto-enable
    _ref.listen(qaNotifierProvider, _onQAStateChanged);
  }

  // ============================================================
  // Voice State Reactions
  // ============================================================

  void _onVoiceStateChanged(VoiceState? previous, VoiceState next) {
    _syncVideoWithVoiceState(previous, next);
  }

  /// Pause video when speaking, resume when returning to listening
  void _syncVideoWithVoiceState(VoiceState? previous, VoiceState next) {
    final controller = _ref.read(youtubeControllerProvider);
    if (controller == null) return;

    // Resume video: waiting -> listening transition
    if (next.continuousListeningState == ContinuousListeningState.listening &&
        previous?.continuousListeningState ==
            ContinuousListeningState.waitingForNextQuestion) {
      controller.playVideo();
    }

    // Pause video: started speaking
    if (next.isSpeaking && !(previous?.isSpeaking ?? false)) {
      controller.pauseVideo();
    }
  }

  // ============================================================
  // QA State Reactions
  // ============================================================

  void _onQAStateChanged(QAState? previous, QAState next) {
    _handleAutoSpeak(previous, next);
    _handleAutoEnableContinuousMode(previous, next);
    _handleVideoCleared(next);
  }

  /// Speak answer aloud if input was voice or in continuous mode
  void _handleAutoSpeak(QAState? previous, QAState next) {
    final previousLength = previous?.history.length ?? 0;
    if (next.history.length <= previousLength) return;

    final lastEntry = next.history.last;
    if (!lastEntry.hasAnswer) return;

    final voiceState = _ref.read(voiceNotifierProvider);
    final voiceNotifier = _ref.read(voiceNotifierProvider.notifier);

    if (voiceState.isContinuousModeEnabled) {
      voiceNotifier.speakAnswerAndResume(lastEntry.answer!);
    } else if (next.lastInputMethod == InputMethod.voice) {
      voiceNotifier.speak(lastEntry.answer!);
    }
  }

  /// Auto-enable continuous mode when video loads (if headphones connected)
  void _handleAutoEnableContinuousMode(QAState? previous, QAState next) {
    if (!next.hasVideo || next.isLoadingVideo) return;

    final isNewVideo = _isNewVideoLoaded(previous, next);
    if (!isNewVideo || state.hasAutoEnabledForCurrentVideo) return;

    // Mark as attempted for this video
    state = state.copyWith(
      hasAutoEnabledForCurrentVideo: true,
      lastAutoEnabledVideoId: next.videoId,
    );

    // Check headphones and enable (async, no dialog on failure)
    Future.microtask(() async {
      final audioService = _ref.read(audioDeviceServiceProvider);
      if (await audioService.areHeadphonesConnected()) {
        _enableContinuousMode();
      }
    });
  }

  bool _isNewVideoLoaded(QAState? previous, QAState next) {
    if (previous?.hasVideo == false) return true;
    if (previous?.videoId != next.videoId &&
        next.videoId != state.lastAutoEnabledVideoId) {
      return true;
    }
    return false;
  }

  /// Reset auto-enable tracking when video cleared
  void _handleVideoCleared(QAState next) {
    if (!next.hasVideo && state.hasAutoEnabledForCurrentVideo) {
      state = state.resetAutoEnable();
    }
  }

  // ============================================================
  // App Lifecycle Handling
  // ============================================================

  /// Call from widget's didChangeAppLifecycleState
  void handleAppLifecycleChange(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive) {
      _handleAppPaused();
    } else if (lifecycleState == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppPaused() {
    final voiceState = _ref.read(voiceNotifierProvider);
    if (voiceState.isContinuousModeEnabled) {
      state = state.copyWith(wasInContinuousMode: true);
      _ref.read(voiceNotifierProvider.notifier).stopContinuousMode();
    }
  }

  void _handleAppResumed() {
    if (state.wasInContinuousMode) {
      state = state.copyWith(
        wasInContinuousMode: false,
        shouldShowResumeDialog: true,
      );
    }
  }

  /// Call after showing resume dialog
  void clearResumeDialogFlag() {
    state = state.copyWith(shouldShowResumeDialog: false);
  }

  /// Resume continuous mode (called from dialog confirmation)
  void resumeContinuousMode() {
    _enableContinuousMode();
  }

  void _enableContinuousMode() {
    // Uses WidgetRef-based helper for video integration callbacks
    // This is called via the screen which has WidgetRef access
    _ref.read(_continuousModeCallbackProvider)?.call();
  }
}

/// Callback provider for continuous mode toggle (set by screen)
/// Allows coordinator to trigger continuous mode without WidgetRef
final _continuousModeCallbackProvider = StateProvider<void Function()?>(
  (_) => null,
);

/// Provider for QA screen coordinator
final qaScreenCoordinatorProvider =
    StateNotifierProvider<QAScreenCoordinator, QAScreenCoordinatorState>(
      (ref) => QAScreenCoordinator(ref),
    );

/// Call this from the screen's initState to set up the continuous mode callback
void setupContinuousModeCallback(WidgetRef ref) {
  ref.read(_continuousModeCallbackProvider.notifier).state = () {
    toggleContinuousModeWithVideo(ref);
  };
}
