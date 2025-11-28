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
          'Could not load captions for this video. The caption format may not be supported. Try a different video.',
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

      // Remove duplicate tracks by using a Set with unique URL
      final uniqueTracks = <String, dynamic>{};
      for (final track in trackManifest.tracks) {
        uniqueTracks[track.url.toString()] = track;
      }

      // Prioritize tracks: manual English > auto English > any language
      final uniqueTrackList = uniqueTracks.values.toList();
      final manualEnglish = uniqueTrackList.where(
        (t) => t.language.code.toLowerCase().startsWith('en') &&
               !t.language.name.toLowerCase().contains('auto'),
      ).toList();

      final autoEnglish = uniqueTrackList.where(
        (t) => t.language.code.toLowerCase().startsWith('en') &&
               t.language.name.toLowerCase().contains('auto'),
      ).toList();

      final others = uniqueTrackList.where(
        (t) => !t.language.code.toLowerCase().startsWith('en'),
      ).toList();

      final trackPriority = [...manualEnglish, ...autoEnglish, ...others];

      print('Trying ${trackPriority.length} unique tracks...');

      // Try each track until one works
      for (final track in trackPriority) {
        try {
          print('Attempting: ${track.language.name}');
          final captions = await _youtubeExplode.videos.closedCaptions.get(track);

          print('✓ Success! ${captions.captions.length} segments');

          final transcript = captions.captions.map((c) => c.text).join(' ');
          print('Transcript length: ${transcript.length} characters');

          return transcript;
        } catch (trackError) {
          print('✗ Failed: ${trackError.runtimeType}');
          continue;
        }
      }

      print('All tracks failed - video format not supported');
      return null;
    } catch (e) {
      print('Error fetching transcript: $e');
      return null;
    }
  }

  /// Clean up resources
  void dispose() {
    _youtubeExplode.close();
  }
}
