import '../models/qa_models.dart';
import '../../../core/services/llm/llm_service.dart';

/// Business logic for Question & Answer feature
/// Coordinates between UI and LLM service
class QAService {
  final LLMService _llmService;

  QAService({required LLMService llmService}) : _llmService = llmService;

  /// Process a user question with transcript context
  /// Returns QAResult with either answer or error
  Future<QAResult> askQuestion({
    required String transcript,
    required String questionText,
  }) async {
    final validationError = _validateInput(transcript, questionText);
    if (validationError != null) {
      return QAResult.failure(validationError);
    }

    try {
      final response = await _llmService.askQuestion(
        context: transcript,
        question: questionText,
      );

      final answer = Answer(
        text: response.text,
        timestamp: DateTime.now(),
        tokensUsed: response.tokensUsed,
      );

      return QAResult.success(answer);
    } on LLMException catch (e) {
      return QAResult.failure(e.message);
    } catch (e) {
      return QAResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  String? _validateInput(String transcript, String questionText) {
    if (questionText.trim().isEmpty) {
      return 'Please enter a question';
    }

    if (transcript.trim().isEmpty) {
      return 'No transcript available';
    }

    return null;
  }
}
