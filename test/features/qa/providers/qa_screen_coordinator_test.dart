import 'package:flutter_test/flutter_test.dart';
import 'package:vidorion/features/qa/providers/qa_screen_coordinator.dart';

void main() {
  group('QAScreenCoordinatorState', () {
    test('initial state has correct defaults', () {
      const state = QAScreenCoordinatorState();

      expect(state.wasInContinuousMode, false);
      expect(state.hasAutoEnabledForCurrentVideo, false);
      expect(state.lastAutoEnabledVideoId, null);
      expect(state.shouldShowResumeDialog, false);
    });

    test('copyWith preserves unchanged values', () {
      const state = QAScreenCoordinatorState(
        wasInContinuousMode: true,
        hasAutoEnabledForCurrentVideo: true,
        lastAutoEnabledVideoId: 'video1',
        shouldShowResumeDialog: true,
      );

      final newState = state.copyWith(wasInContinuousMode: false);

      expect(newState.wasInContinuousMode, false);
      expect(newState.hasAutoEnabledForCurrentVideo, true);
      expect(newState.lastAutoEnabledVideoId, 'video1');
      expect(newState.shouldShowResumeDialog, true);
    });

    test('copyWith updates single field', () {
      const state = QAScreenCoordinatorState();

      final newState = state.copyWith(shouldShowResumeDialog: true);

      expect(newState.shouldShowResumeDialog, true);
      expect(newState.wasInContinuousMode, false);
      expect(newState.hasAutoEnabledForCurrentVideo, false);
      expect(newState.lastAutoEnabledVideoId, null);
    });

    test('copyWith updates multiple fields', () {
      const state = QAScreenCoordinatorState();

      final newState = state.copyWith(
        wasInContinuousMode: true,
        hasAutoEnabledForCurrentVideo: true,
        lastAutoEnabledVideoId: 'video123',
      );

      expect(newState.wasInContinuousMode, true);
      expect(newState.hasAutoEnabledForCurrentVideo, true);
      expect(newState.lastAutoEnabledVideoId, 'video123');
      expect(newState.shouldShowResumeDialog, false);
    });

    test('resetAutoEnable clears auto-enable tracking', () {
      const state = QAScreenCoordinatorState(
        hasAutoEnabledForCurrentVideo: true,
        lastAutoEnabledVideoId: 'video1',
        wasInContinuousMode: true,
        shouldShowResumeDialog: true,
      );

      final newState = state.resetAutoEnable();

      expect(newState.hasAutoEnabledForCurrentVideo, false);
      expect(newState.lastAutoEnabledVideoId, null);
      // Other fields preserved
      expect(newState.wasInContinuousMode, true);
      expect(newState.shouldShowResumeDialog, true);
    });

    test('resetAutoEnable works on default state', () {
      const state = QAScreenCoordinatorState();

      final newState = state.resetAutoEnable();

      expect(newState.hasAutoEnabledForCurrentVideo, false);
      expect(newState.lastAutoEnabledVideoId, null);
      expect(newState.wasInContinuousMode, false);
      expect(newState.shouldShowResumeDialog, false);
    });
  });
}
