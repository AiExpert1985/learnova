import 'package:flutter_test/flutter_test.dart';
import 'package:learnova/features/qa/services/qa_service.dart';
import 'package:learnova/core/services/llm/llm_service.dart';

/// Mock LLM service for testing
class MockLLMService implements LLMService {
  final String? mockResponse;
  final LLMException? mockError;

  MockLLMService({this.mockResponse, this.mockError});

  @override
  Future<LLMResponse> askQuestion({
    required String context,
    required String question,
  }) async {
    if (mockError != null) {
      throw mockError!;
    }

    return LLMResponse(text: mockResponse ?? 'Mock answer', tokensUsed: 100);
  }
}

void main() {
  group('QAService', () {
    test('returns success with valid question and transcript', () async {
      final mockLLM = MockLLMService(mockResponse: 'Test answer');
      final qaService = QAService(llmService: mockLLM);

      final result = await qaService.askQuestion(
        transcript: 'Sample transcript about learning',
        questionText: 'What is this about?',
      );

      expect(result.isSuccess, true);
      expect(result.answer?.text, 'Test answer');
      expect(result.answer?.tokensUsed, 100);
    });

    test('returns error for empty question', () async {
      final mockLLM = MockLLMService();
      final qaService = QAService(llmService: mockLLM);

      final result = await qaService.askQuestion(
        transcript: 'Sample transcript',
        questionText: '',
      );

      expect(result.isFailure, true);
      expect(result.error, 'Please enter a question');
    });

    test('returns error for empty transcript', () async {
      final mockLLM = MockLLMService();
      final qaService = QAService(llmService: mockLLM);

      final result = await qaService.askQuestion(
        transcript: '',
        questionText: 'Valid question',
      );

      expect(result.isFailure, true);
      expect(result.error, 'No transcript available');
    });

    test('handles LLM exceptions gracefully', () async {
      final mockLLM = MockLLMService(
        mockError: LLMException('Rate limit exceeded'),
      );
      final qaService = QAService(llmService: mockLLM);

      final result = await qaService.askQuestion(
        transcript: 'Sample transcript',
        questionText: 'Valid question',
      );

      expect(result.isFailure, true);
      expect(result.error, 'Rate limit exceeded');
    });

    test('handles unexpected exceptions', () async {
      final mockLLM = _ThrowingMockLLM();
      final qaService = QAService(llmService: mockLLM);

      final result = await qaService.askQuestion(
        transcript: 'Sample transcript',
        questionText: 'Valid question',
      );

      expect(result.isFailure, true);
      expect(result.error, 'An unexpected error occurred. Please try again.');
    });
  });
}

class _ThrowingMockLLM implements LLMService {
  @override
  Future<LLMResponse> askQuestion({
    required String context,
    required String question,
  }) async {
    throw Exception('Unexpected error');
  }
}
