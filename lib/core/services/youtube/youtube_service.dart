import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'youtube_models.dart';

/// Service for fetching YouTube video information and transcripts
/// Uses youtube_explode_dart (no API key required)
class YouTubeService {
  final _youtubeExplode = YoutubeExplode();

  /// Fetch video info and transcript from YouTube URL
  Future<YouTubeResult> fetchVideo(String url) async {
    try {
      // Validate and parse URL
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        return YouTubeResult.failure('Invalid YouTube URL');
      }

      // Fetch video metadata
      final video = await _youtubeExplode.videos.get(videoId);

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
      final trackManifest = await _youtubeExplode.videos.closedCaptions
          .getManifest(videoId);

      // Get English transcript or first available
      final track = trackManifest.tracks.firstWhere(
        (t) => t.language.code == 'en',
        orElse: () => trackManifest.tracks.first,
      );

      final captions = await _youtubeExplode.videos.closedCaptions.get(track);

      // Combine all caption text
      return captions.captions.map((c) => c.text).join(' ');
    } catch (e) {
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _youtubeExplode.close();
  }
}
