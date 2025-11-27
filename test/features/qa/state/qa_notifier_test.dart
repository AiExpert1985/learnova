import 'package:flutter_test/flutter_test.dart';
import 'package:learnova/features/qa/state/qa_notifier.dart';
import 'package:learnova/features/qa/services/qa_service.dart';
import 'package:learnova/features/qa/models/qa_models.dart';
import 'package:learnova/core/services/llm/llm_service.dart';

/// Mock QAService for testing
class MockQAService implements QAService {
  final QAResult mockResult;

  MockQAService({required this.mockResult});

  @override
  Future<QAResult> askQuestion({
    required String transcript,
    required String questionText,
  }) async {
    return mockResult;
  }

  @override
  LLMService get llmService => throw UnimplementedError();
}

void main() {
  group('QANotifier', () {
    test('initial state is empty', () {
      final mockService = MockQAService(
        mockResult: QAResult.success(Answer(
          text: 'Test',
          timestamp: DateTime.now(),
          tokensUsed: 100,
        )),
      );
      final notifier = QANotifier(
        qaService: mockService,
        transcript: 'Test transcript',
      );

      expect(notifier.state.history.isEmpty, true);
      expect(notifier.state.isLoading, false);
    });

    test('askQuestion updates state with successful result', () async {
      final mockAnswer = Answer(
        text: 'Test answer',
        timestamp: DateTime.now(),
        tokensUsed: 150,
      );
      final mockService = MockQAService(
        mockResult: QAResult.success(mockAnswer),
      );
      final notifier = QANotifier(
        qaService: mockService,
        transcript: 'Test transcript',
      );

      await notifier.askQuestion('What is this about?');

      expect(notifier.state.history.length, 1);
      expect(notifier.state.history.first.question, 'What is this about?');
      expect(notifier.state.history.first.answer, 'Test answer');
      expect(notifier.state.history.first.tokensUsed, 150);
      expect(notifier.state.history.first.hasError, false);
      expect(notifier.state.isLoading, false);
    });

    test('askQuestion updates state with error result', () async {
      final mockService = MockQAService(
        mockResult: QAResult.failure('Rate limit exceeded'),
      );
      final notifier = QANotifier(
        qaService: mockService,
        transcript: 'Test transcript',
      );

      await notifier.askQuestion('What is this about?');

      expect(notifier.state.history.length, 1);
      expect(notifier.state.history.first.question, 'What is this about?');
      expect(notifier.state.history.first.hasError, true);
      expect(notifier.state.history.first.error, 'Rate limit exceeded');
      expect(notifier.state.isLoading, false);
    });

    test('askQuestion ignores empty or whitespace questions', () async {
      final mockService = MockQAService(
        mockResult: QAResult.success(Answer(
          text: 'Test',
          timestamp: DateTime.now(),
          tokensUsed: 100,
        )),
      );
      final notifier = QANotifier(
        qaService: mockService,
        transcript: 'Test transcript',
      );

      await notifier.askQuestion('');
      expect(notifier.state.history.isEmpty, true);

      await notifier.askQuestion('   ');
      expect(notifier.state.history.isEmpty, true);
    });

    test('askQuestion trims whitespace from questions', () async {
      final mockAnswer = Answer(
        text: 'Test answer',
        timestamp: DateTime.now(),
        tokensUsed: 100,
      );
      final mockService = MockQAService(
        mockResult: QAResult.success(mockAnswer),
      );
      final notifier = QANotifier(
        qaService: mockService,
        transcript: 'Test transcript',
      );

      await notifier.askQuestion('  What is this?  ');

      expect(notifier.state.history.length, 1);
      expect(notifier.state.history.first.question, 'What is this?');
    });

    test('multiple questions accumulate in history', () async {
      final mockAnswer = Answer(
        text: 'Test answer',
        timestamp: DateTime.now(),
        tokensUsed: 100,
      );
      final mockService = MockQAService(
        mockResult: QAResult.success(mockAnswer),
      );
      final notifier = QANotifier(
        qaService: mockService,
        transcript: 'Test transcript',
      );

      await notifier.askQuestion('Question 1');
      await notifier.askQuestion('Question 2');
      await notifier.askQuestion('Question 3');

      expect(notifier.state.history.length, 3);
      expect(notifier.state.history[0].question, 'Question 1');
      expect(notifier.state.history[1].question, 'Question 2');
      expect(notifier.state.history[2].question, 'Question 3');
    });
  });
}
