/// Abstract interface for OpenAI API integration
/// Allows testing and potential provider switching
library;

abstract class OpenAIService {
  /// Ask a question given a transcript context
  /// Returns the AI response text and token count
  /// Throws OpenAIException on errors
  Future<OpenAIResponse> askQuestion({
    required String context,
    required String question,
  });
}

class OpenAIResponse {
  final String text;
  final int tokensUsed;

  OpenAIResponse({
    required this.text,
    required this.tokensUsed,
  });
}

class OpenAIException implements Exception {
  final String message;
  final int? statusCode;

  OpenAIException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenAIException: $message';
}
