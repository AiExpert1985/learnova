import '../models/qa_history_entry.dart';
import '../../../core/services/youtube/youtube_models.dart';

/// Input method for questions
enum InputMethod { voice, text }

/// Bottom action bar state
enum BottomBarState {
  collapsed, // Shows 2 buttons: URL, Chat
  urlExpanded, // Shows URL input field
}

/// State for Q&A feature
/// Manages video info, question history, and loading status
class QAState {
  final VideoInfo? videoInfo;
  final Duration currentPosition;
  final List<QAHistoryEntry> history;
  final bool isLoadingAnswer;
  final bool isLoadingVideo;
  final String? videoError;
  final bool isVideoInitialized;
  final bool isTranscriptLoaded;
  final bool isTextInputVisible;
  final InputMethod lastInputMethod;
  final BottomBarState bottomBarState;

  const QAState({
    this.videoInfo,
    this.currentPosition = Duration.zero,
    this.history = const [],
    this.isLoadingAnswer = false,
    this.isLoadingVideo = false,
    this.videoError,
    this.isVideoInitialized = false,
    this.isTranscriptLoaded = false,
    this.isTextInputVisible = false,
    this.lastInputMethod = InputMethod.voice,
    this.bottomBarState = BottomBarState.collapsed,
  });

  // Computed properties for backward compatibility
  String? get videoTitle => videoInfo?.title;
  Duration? get videoDuration => videoInfo?.duration;
  String? get transcript => videoInfo?.getFullTranscript();
  String? get videoId => videoInfo?.id;

  bool get hasVideo => videoInfo != null;

  /// True when video player and transcript are both ready for interaction
  bool get isFullyInitialized => isVideoInitialized && isTranscriptLoaded;

  QAState copyWith({
    VideoInfo? videoInfo,
    Duration? currentPosition,
    List<QAHistoryEntry>? history,
    bool? isLoadingAnswer,
    bool? isLoadingVideo,
    String? videoError,
    bool? isVideoInitialized,
    bool? isTranscriptLoaded,
    bool? isTextInputVisible,
    InputMethod? lastInputMethod,
    BottomBarState? bottomBarState,
  }) {
    return QAState(
      videoInfo: videoInfo ?? this.videoInfo,
      currentPosition: currentPosition ?? this.currentPosition,
      history: history ?? this.history,
      isLoadingAnswer: isLoadingAnswer ?? this.isLoadingAnswer,
      isLoadingVideo: isLoadingVideo ?? this.isLoadingVideo,
      videoError: videoError ?? this.videoError,
      isVideoInitialized: isVideoInitialized ?? this.isVideoInitialized,
      isTranscriptLoaded: isTranscriptLoaded ?? this.isTranscriptLoaded,
      isTextInputVisible: isTextInputVisible ?? this.isTextInputVisible,
      lastInputMethod: lastInputMethod ?? this.lastInputMethod,
      bottomBarState: bottomBarState ?? this.bottomBarState,
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
      isVideoInitialized: false, // Reset initialization flags
      isTranscriptLoaded: false,
    );
  }
}
