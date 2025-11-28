import '../models/qa_history_entry.dart';

/// State for Q&A feature
/// Manages video info, question history, and loading status
class QAState {
  final String? videoTitle;
  final Duration? videoDuration;
  final String? transcript;
  final List<QAHistoryEntry> history;
  final bool isLoading;
  final bool isLoadingVideo;
  final String? videoError;

  const QAState({
    this.videoTitle,
    this.videoDuration,
    this.transcript,
    this.history = const [],
    this.isLoading = false,
    this.isLoadingVideo = false,
    this.videoError,
  });

  bool get hasVideo => transcript != null;

  QAState copyWith({
    String? videoTitle,
    Duration? videoDuration,
    String? transcript,
    List<QAHistoryEntry>? history,
    bool? isLoading,
    bool? isLoadingVideo,
    String? videoError,
  }) {
    return QAState(
      videoTitle: videoTitle ?? this.videoTitle,
      videoDuration: videoDuration ?? this.videoDuration,
      transcript: transcript ?? this.transcript,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isLoadingVideo: isLoadingVideo ?? this.isLoadingVideo,
      videoError: videoError ?? this.videoError,
    );
  }

  QAState clearVideoError() {
    return QAState(
      videoTitle: videoTitle,
      videoDuration: videoDuration,
      transcript: transcript,
      history: history,
      isLoading: isLoading,
      isLoadingVideo: isLoadingVideo,
      videoError: null,
    );
  }
}
