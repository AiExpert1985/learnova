import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qa_history_entry.dart';
import '../services/qa_service.dart';
import '../../../core/services/youtube/youtube_service.dart';
import '../../history/services/history_service.dart';
import '../../history/data/models/qa_entry.dart' as history_models;
import 'qa_state.dart';

/// StateNotifier for Q&A feature
/// Centralizes all business logic for asking questions and managing history
class QANotifier extends StateNotifier<QAState> {
  final QAService _qaService;
  final YouTubeService _youtubeService;
  final HistoryService _historyService;

  QANotifier({
    required QAService qaService,
    required YouTubeService youtubeService,
    required HistoryService historyService,
  }) : _qaService = qaService,
       _youtubeService = youtubeService,
       _historyService = historyService,
       super(const QAState());

  /// Load video from YouTube URL
  Future<void> loadVideo(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;

    // Clear previous error and data, then start loading
    state = state.clearVideoData();

    final result = await _youtubeService.fetchVideo(trimmedUrl);

    if (result.isSuccess) {
      final video = result.video!;

      // Print transcript to console for debugging (only in debug mode)
      if (kDebugMode) {
        final fullTranscript = video.getFullTranscript();
        print('=== YouTube Transcript ===');
        print('Video: ${video.title}');
        print('Duration: ${video.duration}');
        print('Segments: ${video.transcriptSegments.length}');
        print('Transcript length: ${fullTranscript.length} characters');

        // Show first 3 segments with timestamps to verify they're captured
        print('\nFirst 3 segments with timestamps:');
        final sampleSegments = video.transcriptSegments.take(3);
        for (final seg in sampleSegments) {
          print('  [${seg.start.inSeconds}s - ${seg.end.inSeconds}s] ${seg.text}');
        }

        print('\nFull transcript content:');
        print(fullTranscript);
        print('=== End Transcript ===\n');
      }

      state = state.copyWith(
        videoInfo: video,
        isLoadingVideo: false,
      );
    } else {
      state = state.copyWith(isLoadingVideo: false, videoError: result.error);
    }
  }

  /// Update video playback position
  /// Called by video player widget when position changes
  void updatePosition(Duration position) {
    state = state.copyWith(currentPosition: position);
  }

  /// Ask a question and update state with result
  /// Uses current video position to determine context
  Future<void> askQuestion(String questionText) async {
    final trimmedQuestion = questionText.trim();
    if (trimmedQuestion.isEmpty) return;

    // Check if video is loaded
    if (!state.hasVideo) {
      return;
    }

    // Capture video position WHEN question is asked
    final videoPositionAtQuestion = state.currentPosition.inSeconds.toDouble();
    final questionTimestamp = DateTime.now();

    state = state.copyWith(isLoadingAnswer: true);

    // Get transcript based on current video position
    // Use position-aware transcript only if user has watched past 10 seconds
    final transcript = state.currentPosition.inSeconds > 10
        ? state.videoInfo!.getTranscriptUpTo(state.currentPosition)
        : state.videoInfo!.getFullTranscript();

    final result = await _qaService.askQuestion(
      transcript: transcript,
      questionText: trimmedQuestion,
    );

    final newEntry = QAHistoryEntry(
      question: trimmedQuestion,
      answer: result.answer?.text,
      error: result.error,
      tokensUsed: result.answer?.tokensUsed ?? 0,
      timestamp: questionTimestamp,
      videoPosition: videoPositionAtQuestion,
    );

    state = state.copyWith(
      isLoadingAnswer: false,
      history: [...state.history, newEntry],
    );

    // Auto-save conversation to history after successful Q&A
    if (newEntry.hasAnswer) {
      await _saveConversationToHistory();
    }
  }

  /// Save current conversation to history storage
  /// Called automatically after each successful Q&A interaction
  Future<void> _saveConversationToHistory() async {
    if (!state.hasVideo || state.history.isEmpty) return;

    // Convert QA history entries to history models
    final historyQAEntries = state.history
        .where((entry) => entry.hasAnswer) // Only save successful answers
        .map((entry) => history_models.QAEntry(
              question: entry.question,
              answer: entry.answer!,
              timestamp: entry.timestamp, // Use actual Q&A timestamp
              videoPosition: entry.videoPosition, // Use position when question was asked
              tokensUsed: entry.tokensUsed,
            ))
        .toList();

    final result = await _historyService.saveConversation(
      videoId: state.videoId!,
      videoTitle: state.videoTitle!,
      qaHistory: historyQAEntries,
    );

    // Silent failure - don't interrupt user experience if history save fails
    if (result.isFailure && kDebugMode) {
      print('Failed to save conversation to history: ${result.failure}');
    }
  }

  /// Load conversation from history and restore state
  /// Used when user selects a conversation from history
  Future<void> loadConversationFromHistory(String conversationId) async {
    final result = await _historyService.loadConversationById(conversationId);

    if (result.isSuccess && result.data != null) {
      final conversation = result.data!;

      // Load the video first
      await loadVideo('https://www.youtube.com/watch?v=${conversation.videoId}');

      // Restore Q&A history after video loads
      if (state.hasVideo) {
        final qaHistoryEntries = conversation.qaHistory
            .map((entry) => QAHistoryEntry(
                  question: entry.question,
                  answer: entry.answer,
                  error: null,
                  tokensUsed: entry.tokensUsed,
                  timestamp: entry.timestamp,
                  videoPosition: entry.videoPosition,
                ))
            .toList();

        state = state.copyWith(history: qaHistoryEntries);
      }
    }
  }
}
