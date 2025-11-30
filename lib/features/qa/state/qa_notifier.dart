import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qa_history_entry.dart';
import '../services/qa_service.dart';
import '../../../core/services/youtube/youtube_service.dart';
import 'qa_state.dart';

/// StateNotifier for Q&A feature
/// Centralizes all business logic for asking questions and managing history
class QANotifier extends StateNotifier<QAState> {
  final QAService _qaService;
  final YouTubeService _youtubeService;

  QANotifier({
    required QAService qaService,
    required YouTubeService youtubeService,
  }) : _qaService = qaService,
       _youtubeService = youtubeService,
       super(const QAState());

  /// Load video from YouTube URL
  Future<void> loadVideo(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;

    // Clear previous error if any
    state = state.clearVideoError();
    state = state.copyWith(isLoadingVideo: true);

    final result = await _youtubeService.fetchVideo(trimmedUrl);

    if (result.isSuccess) {
      final video = result.video!;

      // Print transcript to console for debugging
      print('=== YouTube Transcript ===');
      print('Video: ${video.title}');
      print('Duration: ${video.duration}');
      print('Transcript length: ${video.transcript.length} characters');
      print('\nTranscript content:');
      print(video.transcript);
      print('=== End Transcript ===\n');

      state = state.copyWith(
        videoTitle: video.title,
        videoDuration: video.duration,
        transcript: video.transcript,
        isLoadingVideo: false,
        history: [], // Clear history when loading new video
      );
    } else {
      state = state.copyWith(isLoadingVideo: false, videoError: result.error);
    }
  }

  /// Ask a question and update state with result
  Future<void> askQuestion(String questionText) async {
    final trimmedQuestion = questionText.trim();
    if (trimmedQuestion.isEmpty) return;

    // Check if video is loaded
    if (!state.hasVideo) {
      return;
    }

    state = state.copyWith(isLoadingAnswer: true);

    final result = await _qaService.askQuestion(
      transcript: state.transcript!,
      questionText: trimmedQuestion,
    );

    final newEntry = QAHistoryEntry(
      question: trimmedQuestion,
      answer: result.answer?.text,
      error: result.error,
      tokensUsed: result.answer?.tokensUsed ?? 0,
    );

    state = state.copyWith(
      isLoadingAnswer: false,
      history: [...state.history, newEntry],
    );
  }
}
