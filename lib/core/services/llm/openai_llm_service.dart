import 'dart:convert';
import 'package:http/http.dart' as http;
import 'llm_service.dart';

/// OpenAI implementation of LLM service
/// Uses GPT-4o-mini for cost-effective Q&A
class OpenAILLMService implements LLMService {
  final String apiKey;
  final http.Client _client;

  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';
  static const Duration _timeout = Duration(seconds: 30);

  OpenAILLMService({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  Future<LLMResponse> askQuestion({
    required String context,
    required String question,
  }) async {
    if (apiKey.isEmpty) {
      throw LLMException('API key is empty');
    }

    final prompt = _buildPrompt(context, question);
    final requestBody = _buildRequestBody(prompt);

    try {
      final response = await _makeRequest(requestBody);
      return _parseResponse(response);
    } on LLMException {
      rethrow;
    } catch (e) {
      throw LLMException('Unexpected error: $e');
    }
  }

  String _buildPrompt(String context, String question) {
    return '''You are a learning assistant. Answer the user's question based on the video transcript provided.

Transcript:
$context

Question: $question

Provide a clear, concise answer (2-3 sentences). If the answer isn't in the transcript, say "I don't have enough information from this video to answer that."''';
  }

  Map<String, dynamic> _buildRequestBody(String prompt) {
    return {
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.7,
      'max_tokens': 150,
    };
  }

  Future<http.Response> _makeRequest(Map<String, dynamic> body) async {
    final response = await _client
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      _handleErrorResponse(response);
    }

    return response;
  }

  void _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    String message;

    if (statusCode == 401) {
      message = 'Invalid API key';
    } else if (statusCode == 429) {
      message = 'Rate limit exceeded. Please try again later.';
    } else if (statusCode >= 500) {
      message = 'OpenAI service unavailable. Please try again later.';
    } else {
      message = 'Request failed with status $statusCode';
    }

    throw LLMException(message, statusCode: statusCode);
  }

  LLMResponse _parseResponse(http.Response response) {
    final Map<String, dynamic> data;

    try {
      data = jsonDecode(response.body);
    } catch (e) {
      throw LLMException('Failed to parse response: $e');
    }

    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw LLMException('No response from AI');
    }

    final message = choices[0]['message'];
    final text = message['content'] as String?;

    if (text == null || text.isEmpty) {
      throw LLMException('Empty response from AI');
    }

    final usage = data['usage'] as Map<String, dynamic>?;
    final tokensUsed = usage?['total_tokens'] as int? ?? 0;

    return LLMResponse(
      text: text.trim(),
      tokensUsed: tokensUsed,
    );
  }
}
