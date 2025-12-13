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
}
