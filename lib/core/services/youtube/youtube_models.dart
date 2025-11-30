/// A single segment of transcript with timing information
class TranscriptSegment {
  final String text;
  final Duration start;
  final Duration duration;

  const TranscriptSegment({
    required this.text,
    required this.start,
    required this.duration,
  });

  Duration get end => start + duration;
}

/// Video information from YouTube
class VideoInfo {
  final String id;
  final String title;
  final Duration duration;
  final List<TranscriptSegment> transcriptSegments;

  const VideoInfo({
    required this.id,
    required this.title,
    required this.duration,
    required this.transcriptSegments,
  });

  /// Get full transcript as plain text (current use case)
  String getFullTranscript() {
    return transcriptSegments.map((seg) => seg.text).join(' ');
  }

  /// Get transcript up to a specific timestamp (future use case)
  /// This will be used when we track video playback position
  String getTranscriptUpTo(Duration position) {
    final segments = transcriptSegments
        .where((seg) => seg.start < position)
        .toList();
    return segments.map((seg) => seg.text).join(' ');
  }
}

/// Result wrapper for YouTube operations
class YouTubeResult {
  final VideoInfo? video;
  final String? error;

  const YouTubeResult._({this.video, this.error});

  factory YouTubeResult.success(VideoInfo video) {
    return YouTubeResult._(video: video);
  }

  factory YouTubeResult.failure(String error) {
    return YouTubeResult._(error: error);
  }

  bool get isSuccess => video != null;
  bool get isFailure => error != null;
}
