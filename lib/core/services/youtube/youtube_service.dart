import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'youtube_models.dart';

/// Service for fetching YouTube video information and transcripts
/// Uses youtube_explode_dart (no API key required)
class YouTubeService {
  final _youtubeExplode = YoutubeExplode();

  /// Fetch video info and transcript from YouTube URL
  Future<YouTubeResult> fetchVideo(String url) async {
    try {
      print('Processing URL: $url');

      // Validate and parse URL
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        print('Failed to extract video ID from URL');
        return YouTubeResult.failure('Invalid YouTube URL');
      }

      print('Extracted video ID: $videoId');

      // Fetch video metadata
      print('Fetching video metadata...');
      final video = await _youtubeExplode.videos.get(videoId);
      print('Video title: ${video.title}');
      print('Video duration: ${video.duration}');

      // Fetch transcript
      final transcript = await _fetchTranscript(videoId);
      if (transcript == null) {
        return YouTubeResult.failure(
          'No transcript available for this video. Please try another video with captions.',
        );
      }

      return YouTubeResult.success(VideoInfo(
        id: videoId,
        title: video.title,
        duration: video.duration ?? Duration.zero,
        transcript: transcript,
      ));
    } catch (e) {
      print('Error in fetchVideo: $e');
      return YouTubeResult.failure(
        'Failed to load video: ${e.toString()}',
      );
    }
  }

  /// Extract video ID from various YouTube URL formats
  String? _extractVideoId(String url) {
    try {
      return VideoId.parseVideoId(url);
    } catch (e) {
      return null;
    }
  }

  /// Fetch transcript/captions for a video
  Future<String?> _fetchTranscript(String videoId) async {
    try {
      print('Fetching transcript for video: $videoId');

      final trackManifest = await _youtubeExplode.videos.closedCaptions
          .getManifest(videoId);

      print('Found ${trackManifest.tracks.length} caption tracks');

      if (trackManifest.tracks.isEmpty) {
        print('No caption tracks available');
        return null;
      }

      // Print available tracks for debugging
      for (final track in trackManifest.tracks) {
        print('Available track: ${track.language.name} (${track.language.code})');
      }

      // Try to get English transcript first
      final track = trackManifest.tracks.firstWhere(
        (t) => t.language.code.toLowerCase().startsWith('en'),
        orElse: () {
          print('No English track found, using first available: ${trackManifest.tracks.first.language.name}');
          return trackManifest.tracks.first;
        },
      );

      print('Fetching captions for track: ${track.language.name}');
      final captions = await _youtubeExplode.videos.closedCaptions.get(track);

      print('Retrieved ${captions.captions.length} caption segments');

      // Combine all caption text
      final transcript = captions.captions.map((c) => c.text).join(' ');
      print('Total transcript length: ${transcript.length} characters');

      return transcript;
    } catch (e) {
      print('Error fetching transcript: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _youtubeExplode.close();
  }
}
