import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learnova/core/services/youtube/youtube_service.dart';

/// Mock HTTP client for testing
class MockHttpClient extends http.BaseClient {
  final Map<String, dynamic>? mockPlayerResponse;
  final String? mockTranscriptXml;
  final int statusCode;

  MockHttpClient({
    this.mockPlayerResponse,
    this.mockTranscriptXml,
    this.statusCode = 200,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path.contains('/player')) {
      // Player API response
      final body = mockPlayerResponse != null
          ? jsonEncode(mockPlayerResponse)
          : '{}';
      return http.StreamedResponse(
        Stream.value(body.codeUnits),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    } else {
      // Transcript XML response
      final body = mockTranscriptXml ?? '';
      return http.StreamedResponse(
        Stream.value(body.codeUnits),
        statusCode,
        headers: {'content-type': 'text/xml'},
      );
    }
  }
}

void main() {
  group('YouTubeService', () {
    test('extracts video ID from standard YouTube URL', () async {
      final mockClient = MockHttpClient(
        mockPlayerResponse: {
          'videoDetails': {'title': 'Test', 'lengthSeconds': '120'},
          'captions': {
            'playerCaptionsTracklistRenderer': {
              'captionTracks': [
                {
                  'languageCode': 'en',
                  'baseUrl': 'http://example.com/transcript',
                },
              ],
            },
          },
        },
        mockTranscriptXml: '<transcript><text start="0.0" dur="2.0">Test</text></transcript>',
      );
      final service = YouTubeService(httpClient: mockClient);

      final result = await service.fetchVideo(
        'https://www.youtube.com/watch?v=abc12345678',
      );

      expect(result.isSuccess, true);
      service.dispose();
    });

    test('extracts video ID from short YouTube URL', () async {
      final mockClient = MockHttpClient(
        mockPlayerResponse: {
          'videoDetails': {'title': 'Test', 'lengthSeconds': '120'},
          'captions': {
            'playerCaptionsTracklistRenderer': {
              'captionTracks': [
                {
                  'languageCode': 'en',
                  'baseUrl': 'http://example.com/transcript',
                },
              ],
            },
          },
        },
        mockTranscriptXml: '<transcript><text start="0.0" dur="2.0">Test</text></transcript>',
      );
      final service = YouTubeService(httpClient: mockClient);

      final result = await service.fetchVideo('https://youtu.be/abc12345678');

      expect(result.isSuccess, true);
      service.dispose();
    });

    test('returns failure for invalid URL', () async {
      final mockClient = MockHttpClient();
      final service = YouTubeService(httpClient: mockClient);

      final result = await service.fetchVideo('not-a-valid-url');

      expect(result.isFailure, true);
      expect(result.error, 'Invalid YouTube URL');
      service.dispose();
    });

    test('fetches video metadata successfully', () async {
      final mockClient = MockHttpClient(
        mockPlayerResponse: {
          'videoDetails': {'title': 'Test Video Title', 'lengthSeconds': '300'},
          'captions': {
            'playerCaptionsTracklistRenderer': {
              'captionTracks': [
                {
                  'languageCode': 'en',
                  'baseUrl': 'http://example.com/transcript',
                },
              ],
            },
          },
        },
        mockTranscriptXml:
            '<transcript><text start="0.0" dur="2.0">Hello world</text><text start="2.0" dur="3.0">Test transcript</text></transcript>',
      );
      final service = YouTubeService(httpClient: mockClient);

      final result = await service.fetchVideo(
        'https://www.youtube.com/watch?v=abc12345678',
      );

      expect(result.isSuccess, true);
      expect(result.video?.title, 'Test Video Title');
      expect(result.video?.duration, const Duration(seconds: 300));
      expect(result.video?.transcriptSegments.length, 2);
      expect(result.video?.getFullTranscript(), contains('Hello world'));
      service.dispose();
    });

    test('returns failure when no captions available', () async {
      final mockClient = MockHttpClient(
        mockPlayerResponse: {
          'videoDetails': {'title': 'Test', 'lengthSeconds': '120'},
          // No captions field
        },
      );
      final service = YouTubeService(httpClient: mockClient);

      final result = await service.fetchVideo(
        'https://www.youtube.com/watch?v=abc12345678',
      );

      expect(result.isFailure, true);
      expect(result.error, contains('No captions available'));
      service.dispose();
    });

    test('handles HTTP errors gracefully', () async {
      final mockClient = MockHttpClient(statusCode: 400);
      final service = YouTubeService(httpClient: mockClient);

      final result = await service.fetchVideo(
        'https://www.youtube.com/watch?v=abc12345678',
      );

      expect(result.isFailure, true);
      expect(result.error, contains('Could not load video information'));
      service.dispose();
    });

    test('decodes HTML entities in transcript', () async {
      final mockClient = MockHttpClient(
        mockPlayerResponse: {
          'videoDetails': {'title': 'Test', 'lengthSeconds': '120'},
          'captions': {
            'playerCaptionsTracklistRenderer': {
              'captionTracks': [
                {
                  'languageCode': 'en',
                  'baseUrl': 'http://example.com/transcript',
                },
              ],
            },
          },
        },
        mockTranscriptXml:
            '<transcript><text start="0.0" dur="2.0">Hello &amp; welcome</text><text start="2.0" dur="2.0">It&#39;s great</text></transcript>',
      );
      final service = YouTubeService(httpClient: mockClient);

      final result = await service.fetchVideo(
        'https://www.youtube.com/watch?v=abc12345678',
      );

      expect(result.isSuccess, true);
      final transcript = result.video?.getFullTranscript() ?? '';
      expect(transcript, contains('Hello & welcome'));
      expect(transcript, contains("It's great"));
      service.dispose();
    });
  });
}
