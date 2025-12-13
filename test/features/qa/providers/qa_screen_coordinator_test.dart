import 'package:flutter_test/flutter_test.dart';
import 'package:vidorion/features/qa/providers/qa_screen_coordinator.dart';

void main() {
  group('QAScreenCoordinatorState', () {
    test('initial state has correct defaults', () {
      const state = QAScreenCoordinatorState();

      expect(state.wasInContinuousMode, false);
      expect(state.shouldShowResumeDialog, false);
      expect(state.wasVideoPlaying, false);
    });

    test('copyWith preserves unchanged values', () {
      const state = QAScreenCoordinatorState(
        wasInContinuousMode: true,
        shouldShowResumeDialog: true,
        wasVideoPlaying: true,
      );

      final newState = state.copyWith(wasInContinuousMode: false);

      expect(newState.wasInContinuousMode, false);
      expect(newState.shouldShowResumeDialog, true);
      expect(newState.wasVideoPlaying, true);
    });

    test('copyWith updates single field', () {
      const state = QAScreenCoordinatorState();

      final newState = state.copyWith(shouldShowResumeDialog: true);

      expect(newState.shouldShowResumeDialog, true);
      expect(newState.wasInContinuousMode, false);
      expect(newState.wasVideoPlaying, false);
    });

    test('copyWith updates multiple fields', () {
      const state = QAScreenCoordinatorState();

      final newState = state.copyWith(
        wasInContinuousMode: true,
        wasVideoPlaying: true,
      );

      expect(newState.wasInContinuousMode, true);
      expect(newState.shouldShowResumeDialog, false);
      expect(newState.wasVideoPlaying, true);
    });

    test('copyWith updates wasVideoPlaying field', () {
      const state = QAScreenCoordinatorState();

      final newState = state.copyWith(wasVideoPlaying: true);

      expect(newState.wasVideoPlaying, true);
      expect(newState.wasInContinuousMode, false);
      expect(newState.shouldShowResumeDialog, false);
    });
  });

  group('QAScreenCoordinatorState - Lifecycle Scenarios', () {
    test('state transitions for app pause/resume with continuous mode', () {
      // Initial state
      const state = QAScreenCoordinatorState();

      // When app is paused while continuous mode is active
      final pausedState = state.copyWith(wasInContinuousMode: true);
      expect(pausedState.wasInContinuousMode, true);
      expect(pausedState.shouldShowResumeDialog, false);

      // When app is resumed after being paused
      final resumedState = pausedState.copyWith(
        wasInContinuousMode: false,
        shouldShowResumeDialog: true,
      );
      expect(resumedState.wasInContinuousMode, false);
      expect(resumedState.shouldShowResumeDialog, true);

      // After user dismisses the dialog
      final clearedState = resumedState.copyWith(shouldShowResumeDialog: false);
      expect(clearedState.shouldShowResumeDialog, false);
    });

    test('state transitions for video pause/resume during speaking', () {
      // Initial state
      const state = QAScreenCoordinatorState();

      // When video is paused for user speaking
      final videoPausedState = state.copyWith(wasVideoPlaying: true);
      expect(videoPausedState.wasVideoPlaying, true);

      // When TTS completes and video should resume
      final videoResumedState = videoPausedState.copyWith(
        wasVideoPlaying: false,
      );
      expect(videoResumedState.wasVideoPlaying, false);
    });

    test('state tracks multiple flags independently', () {
      const state = QAScreenCoordinatorState();

      // Set multiple flags
      var updatedState = state.copyWith(
        wasInContinuousMode: true,
        wasVideoPlaying: true,
      );
      expect(updatedState.wasInContinuousMode, true);
      expect(updatedState.wasVideoPlaying, true);
      expect(updatedState.shouldShowResumeDialog, false);

      // Update one flag
      updatedState = updatedState.copyWith(wasVideoPlaying: false);
      expect(updatedState.wasInContinuousMode, true); // Preserved
      expect(updatedState.wasVideoPlaying, false); // Updated
      expect(updatedState.shouldShowResumeDialog, false); // Preserved

      // Update another flag
      updatedState = updatedState.copyWith(shouldShowResumeDialog: true);
      expect(updatedState.wasInContinuousMode, true); // Preserved
      expect(updatedState.wasVideoPlaying, false); // Preserved
      expect(updatedState.shouldShowResumeDialog, true); // Updated
    });
  });

  group('QAScreenCoordinatorState - Edge Cases', () {
    test('repeated copyWith without changes returns equivalent state', () {
      const state = QAScreenCoordinatorState(
        wasInContinuousMode: true,
        shouldShowResumeDialog: true,
        wasVideoPlaying: true,
      );

      // copyWith with no args should return equivalent state
      final sameState = state.copyWith();

      expect(sameState.wasInContinuousMode, state.wasInContinuousMode);
      expect(sameState.shouldShowResumeDialog, state.shouldShowResumeDialog);
      expect(sameState.wasVideoPlaying, state.wasVideoPlaying);
    });

    test('setting same value twice is idempotent', () {
      const state = QAScreenCoordinatorState();

      final state1 = state.copyWith(wasVideoPlaying: true);
      final state2 = state1.copyWith(wasVideoPlaying: true);

      expect(state1.wasVideoPlaying, state2.wasVideoPlaying);
    });

    test('all flags can be reset to default', () {
      const activeState = QAScreenCoordinatorState(
        wasInContinuousMode: true,
        shouldShowResumeDialog: true,
        wasVideoPlaying: true,
      );

      final resetState = activeState.copyWith(
        wasInContinuousMode: false,
        shouldShowResumeDialog: false,
        wasVideoPlaying: false,
      );

      expect(resetState.wasInContinuousMode, false);
      expect(resetState.shouldShowResumeDialog, false);
      expect(resetState.wasVideoPlaying, false);
    });
  });
}
