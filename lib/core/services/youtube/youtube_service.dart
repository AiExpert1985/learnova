import 'dart:convert';
import 'package:http/http.dart' as http;
import 'youtube_models.dart';

/// Service for fetching YouTube video information and transcripts
/// Uses YouTube Innertube API (no API key required, more reliable)
class YouTubeService {
  static const _apiKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8'; // Public web client key
  final http.Client _httpClient;

  YouTubeService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Fetch video info and transcript from YouTube URL
  Future<YouTubeResult> fetchVideo(String url) async {
    try {
      print('Processing URL: $url');

      final videoId = _extractVideoId(url);
      if (videoId == null) {
        print('Invalid URL');
        return YouTubeResult.failure('Invalid YouTube URL');
      }

      print('Video ID: $videoId');

      // Fetch video metadata
      final videoInfo = await _fetchVideoMetadata(videoId);
      if (videoInfo == null) {
        return YouTubeResult.failure('Could not load video information');
      }

      print('Title: ${videoInfo['title']}');
      print('Duration: ${videoInfo['duration']}');

      // Fetch transcript
      final transcript = await _fetchTranscript(videoId);
      if (transcript == null) {
        return YouTubeResult.failure(
          'No captions available for this video. Try another video with subtitles.',
        );
      }

      return YouTubeResult.success(VideoInfo(
        id: videoId,
        title: videoInfo['title'] as String,
        duration: Duration(seconds: videoInfo['duration'] as int),
        transcript: transcript,
      ));
    } catch (e) {
      print('Error: $e');
      return YouTubeResult.failure('Failed to load video: ${e.toString()}');
    }
  }

  /// Extract video ID from various YouTube URL formats
  String? _extractVideoId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/v/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }

    // If URL is already just the ID
    if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(url)) {
      return url;
    }

    return null;
  }

  /// Fetch video metadata using Innertube API
  Future<Map<String, dynamic>?> _fetchVideoMetadata(String videoId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('https://www.youtube.com/youtubei/v1/player?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB',
              'clientVersion': '2.20250201.00.00',
            }
          },
          'videoId': videoId,
        }),
      );

      if (response.statusCode != 200) {
        print('Metadata fetch failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final videoDetails = data['videoDetails'] as Map<String, dynamic>?;

      if (videoDetails == null) return null;

      return {
        'title': videoDetails['title'] as String? ?? 'Unknown',
        'duration': int.tryParse(videoDetails['lengthSeconds'] as String? ?? '0') ?? 0,
      };
    } catch (e) {
      print('Metadata error: $e');
      return null;
    }
  }

  /// Fetch transcript using Innertube API
  Future<String?> _fetchTranscript(String videoId) async {
    try {
      print('Fetching captions...');

      // Get caption tracks list
      final tracksResponse = await _httpClient.post(
        Uri.parse('https://www.youtube.com/youtubei/v1/player?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        body: jsonEncode({
          'context': {
            'client': {
              'clientName': 'WEB',
              'clientVersion': '2.20250201.00.00',
            }
          },
          'videoId': videoId,
        }),
      );

      if (tracksResponse.statusCode != 200) {
        print('Failed to fetch caption tracks');
        return null;
      }

      final data = jsonDecode(tracksResponse.body) as Map<String, dynamic>;
      final captions = data['captions'] as Map<String, dynamic>?;

      if (captions == null) {
        print('No captions available');
        return null;
      }

      final playerCaptionsRenderer = captions['playerCaptionsTracklistRenderer'] as Map<String, dynamic>?;
      if (playerCaptionsRenderer == null) {
        print('No caption renderer');
        return null;
      }

      final captionTracks = playerCaptionsRenderer['captionTracks'] as List?;
      if (captionTracks == null || captionTracks.isEmpty) {
        print('No caption tracks');
        return null;
      }

      print('Found ${captionTracks.length} tracks');

      // Prioritize: English manual > English auto > any language
      String? bestTrackUrl;

      // Try manual English first
      for (final track in captionTracks) {
        final trackMap = track as Map<String, dynamic>;
        final langCode = trackMap['languageCode'] as String?;
        final kind = trackMap['kind'] as String?;

        if (langCode != null && langCode.startsWith('en') && kind != 'asr') {
          bestTrackUrl = trackMap['baseUrl'] as String?;
          print('Using manual English track');
          break;
        }
      }

      // Try auto-generated English
      if (bestTrackUrl == null) {
        for (final track in captionTracks) {
          final trackMap = track as Map<String, dynamic>;
          final langCode = trackMap['languageCode'] as String?;

          if (langCode != null && langCode.startsWith('en')) {
            bestTrackUrl = trackMap['baseUrl'] as String?;
            print('Using auto-generated English track');
            break;
          }
        }
      }

      // Use any available track
      if (bestTrackUrl == null && captionTracks.isNotEmpty) {
        final firstTrack = captionTracks.first as Map<String, dynamic>;
        bestTrackUrl = firstTrack['baseUrl'] as String?;
        print('Using first available track');
      }

      if (bestTrackUrl == null) {
        print('No usable track found');
        return null;
      }

      // Fetch the actual transcript
      final transcriptResponse = await _httpClient.get(Uri.parse(bestTrackUrl));

      if (transcriptResponse.statusCode != 200) {
        print('Failed to fetch transcript content');
        return null;
      }

      // Parse XML response
      final xml = transcriptResponse.body;
      final textPattern = RegExp(r'<text[^>]*>([^<]*)</text>');
      final matches = textPattern.allMatches(xml);

      final texts = matches
          .map((m) => m.group(1) ?? '')
          .where((t) => t.isNotEmpty)
          .map((t) => _decodeHtmlEntities(t))
          .join(' ');

      if (texts.isEmpty) {
        print('No text extracted from transcript');
        return null;
      }

      print('✓ Transcript: ${texts.length} chars');
      return texts;
    } catch (e) {
      print('Transcript error: $e');
      return null;
    }
  }

  /// Decode HTML entities in transcript text
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// Clean up resources
  void dispose() {
    _httpClient.close();
  }
}
