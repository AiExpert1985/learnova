import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:learnova/core/services/llm/openai_llm_service.dart';
import 'package:learnova/core/services/llm/llm_service.dart';

/// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final http.Response Function(http.Request request)? mockResponse;

  MockHttpClient({this.mockResponse});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (mockResponse == null) {
      throw Exception('No mock response configured');
    }

    final response = mockResponse!(request as http.Request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

void main() {
  group('OpenAILLMService', () {
    test('returns response for successful API call', () async {
      final mockClient = MockHttpClient(
        mockResponse: (request) => http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'content': 'This is about learning strategies.'}
              }
            ],
            'usage': {'total_tokens': 150}
          }),
          200,
        ),
      );

      final service = OpenAILLMService(
        apiKey: 'test-key',
        client: mockClient,
      );

      final response = await service.askQuestion(
        context: 'Sample transcript',
        question: 'What is this about?',
      );

      expect(response.text, 'This is about learning strategies.');
      expect(response.tokensUsed, 150);
    });

    test('throws exception for empty API key', () async {
      final service = OpenAILLMService(apiKey: '');

      expect(
        () => service.askQuestion(
          context: 'Sample',
          question: 'Question',
        ),
        throwsA(isA<LLMException>()),
      );
    });

    test('throws exception for 401 unauthorized', () async {
      final mockClient = MockHttpClient(
        mockResponse: (request) => http.Response('Unauthorized', 401),
      );

      final service = OpenAILLMService(
        apiKey: 'invalid-key',
        client: mockClient,
      );

      expect(
        () => service.askQuestion(
          context: 'Sample',
          question: 'Question',
        ),
        throwsA(
          isA<LLMException>().having(
            (e) => e.message,
            'message',
            'Invalid API key',
          ),
        ),
      );
    });

    test('throws exception for 429 rate limit', () async {
      final mockClient = MockHttpClient(
        mockResponse: (request) => http.Response('Rate limited', 429),
      );

      final service = OpenAILLMService(
        apiKey: 'test-key',
        client: mockClient,
      );

      expect(
        () => service.askQuestion(
          context: 'Sample',
          question: 'Question',
        ),
        throwsA(
          isA<LLMException>().having(
            (e) => e.message,
            'message',
            contains('Rate limit'),
          ),
        ),
      );
    });

    test('builds correct request body', () async {
      http.Request? capturedRequest;

      final mockClient = MockHttpClient(
        mockResponse: (request) {
          capturedRequest = request;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Answer'}
                }
              ],
              'usage': {'total_tokens': 100}
            }),
            200,
          );
        },
      );

      final service = OpenAILLMService(
        apiKey: 'test-key',
        client: mockClient,
      );

      await service.askQuestion(
        context: 'Transcript context',
        question: 'User question',
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.headers['Authorization'], 'Bearer test-key');
      expect(capturedRequest!.headers['Content-Type'], 'application/json');

      final body = jsonDecode(capturedRequest!.body);
      expect(body['model'], 'gpt-4o-mini');
      expect(body['max_tokens'], 150);
      expect(body['temperature'], 0.7);
    });
  });
}
