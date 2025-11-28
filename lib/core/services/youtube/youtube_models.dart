/// Video information from YouTube
class VideoInfo {
  final String id;
  final String title;
  final Duration duration;
  final String transcript;

  const VideoInfo({
    required this.id,
    required this.title,
    required this.duration,
    required this.transcript,
  });
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
