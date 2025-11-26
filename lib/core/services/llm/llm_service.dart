/// Abstract interface for LLM (Large Language Model) API integration
/// Provider-agnostic: supports OpenAI, Gemini, Claude, etc.
library;

abstract class LLMService {
  /// Ask a question given a transcript context
  /// Returns the AI response text and token count
  /// Throws LLMException on errors
  Future<LLMResponse> askQuestion({
    required String context,
    required String question,
  });
}

class LLMResponse {
  final String text;
  final int tokensUsed;

  LLMResponse({
    required this.text,
    required this.tokensUsed,
  });
}

class LLMException implements Exception {
  final String message;
  final int? statusCode;

  LLMException(this.message, {this.statusCode});

  @override
  String toString() => 'LLMException: $message';
}
