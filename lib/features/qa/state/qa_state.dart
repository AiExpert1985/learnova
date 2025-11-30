import '../models/qa_history_entry.dart';
import '../../../core/services/youtube/youtube_models.dart';

/// State for Q&A feature
/// Manages video info, question history, and loading status
class QAState {
  final VideoInfo? videoInfo;
  final Duration currentPosition;
  final List<QAHistoryEntry> history;
  final bool isLoadingAnswer;
  final bool isLoadingVideo;
  final String? videoError;

  const QAState({
    this.videoInfo,
    this.currentPosition = Duration.zero,
    this.history = const [],
    this.isLoadingAnswer = false,
    this.isLoadingVideo = false,
    this.videoError,
  });

  // Computed properties for backward compatibility
  String? get videoTitle => videoInfo?.title;
  Duration? get videoDuration => videoInfo?.duration;
  String? get transcript => videoInfo?.getFullTranscript();
  String? get videoId => videoInfo?.id;

  bool get hasVideo => videoInfo != null;

  QAState copyWith({
    VideoInfo? videoInfo,
    Duration? currentPosition,
    List<QAHistoryEntry>? history,
    bool? isLoadingAnswer,
    bool? isLoadingVideo,
    String? videoError,
  }) {
    return QAState(
      videoInfo: videoInfo ?? this.videoInfo,
      currentPosition: currentPosition ?? this.currentPosition,
      history: history ?? this.history,
      isLoadingAnswer: isLoadingAnswer ?? this.isLoadingAnswer,
      isLoadingVideo: isLoadingVideo ?? this.isLoadingVideo,
      videoError: videoError ?? this.videoError,
    );
  }

  QAState clearVideoData() {
    return QAState(
      videoInfo: null,
      currentPosition: Duration.zero,
      history: [],
      isLoadingAnswer: isLoadingAnswer, // Keep this
      isLoadingVideo: true, // Set to true as we are about to load
      videoError: '', // Clear error
    );
  }
}
