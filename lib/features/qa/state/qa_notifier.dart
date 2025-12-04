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

  // Callback for continuous mode to speak answers
  Function(String answer)? _onAnswerReadyForSpeech;

  // Callback for auto-speaking answers from voice input
  Function(String answer)? _onAutoSpeakCallback;

  // Debug snackbar callback for troubleshooting
  Function(String message)? _onDebugMessage;

  QANotifier({
    required QAService qaService,
    required YouTubeService youtubeService,
    required HistoryService historyService,
  }) : _qaService = qaService,
       _youtubeService = youtubeService,
       _historyService = historyService,
       super(const QAState());

  /// Set callback for debug messages (snackbars)
  void setDebugMessageCallback(Function(String message) callback) {
    _onDebugMessage = callback;
  }

  /// Set video player initialization status
  void setVideoInitialized(bool initialized) {
    state = state.copyWith(isVideoInitialized: initialized);
  }

  /// Load video from YouTube URL
  /// If conversation history exists for this video, loads it instead of starting fresh
  Future<void> loadVideo(String url) async {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;

    // Clear previous error and data, then start loading
    state = state.clearVideoData();

    final result = await _youtubeService.fetchVideo(trimmedUrl);

    if (result.isSuccess) {
      final video = result.video!;

      // Check if conversation history exists for this video
      final historyResult = await _historyService.loadConversationByVideoId(video.id);

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

        // Log if existing conversation was found
        if (historyResult.isSuccess && historyResult.data != null) {
          print('Found existing conversation with ${historyResult.data!.qaHistory.length} Q&As');
        }
      }

      state = state.copyWith(
        videoInfo: video,
        isLoadingVideo: false,
        isTranscriptLoaded: true, // Transcript is loaded with video
      );

      // Load existing conversation history if found
      if (historyResult.isSuccess && historyResult.data != null) {
        final conversation = historyResult.data!;
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
    } else {
      state = state.copyWith(isLoadingVideo: false, videoError: result.error);
    }
  }

  /// Update video playback position
  /// Called by video player widget when position changes
  void updatePosition(Duration position) {
    state = state.copyWith(currentPosition: position);
  }

  /// Toggle text input visibility
  void toggleTextInputVisibility() {
    state = state.copyWith(isTextInputVisible: !state.isTextInputVisible);
  }

  /// Ask a question and update state with result
  /// Uses current video position to determine context
  Future<void> askQuestion(
    String questionText, {
    bool isContinuousMode = false,
    InputMethod? inputMethod,
  }) async {
    debugPrint('[QANotifier] 🎯 askQuestion called with: "$questionText"');
    debugPrint('[QANotifier]   - isContinuousMode: $isContinuousMode');
    debugPrint('[QANotifier]   - inputMethod: $inputMethod');

    final trimmedQuestion = questionText.trim();
    if (trimmedQuestion.isEmpty) {
      debugPrint('[QANotifier] ⚠️  Question is empty, ignoring');
      return;
    }

    // Check if video is loaded
    if (!state.hasVideo) {
      debugPrint('[QANotifier] ❌ No video loaded, cannot ask question');
      return;
    }

    debugPrint('[QANotifier] ✅ Video loaded: ${state.videoTitle}');

    // Capture video position WHEN question is asked
    final videoPositionAtQuestion = state.currentPosition.inSeconds.toDouble();
    final questionTimestamp = DateTime.now();
    debugPrint('[QANotifier] 📍 Video position: ${videoPositionAtQuestion}s');

    // Track input method
    final method = inputMethod ?? state.lastInputMethod;
    state = state.copyWith(
      isLoadingAnswer: true,
      lastInputMethod: method,
    );

    // Get transcript based on current video position
    // Use position-aware transcript only if user has watched past 10 seconds
    final transcript = state.currentPosition.inSeconds > 10
        ? state.videoInfo!.getTranscriptUpTo(state.currentPosition)
        : state.videoInfo!.getFullTranscript();
    debugPrint('[QANotifier] 📄 Using transcript length: ${transcript.length} chars');

    _onDebugMessage?.call('📤 Sending question to LLM API...');
    debugPrint('[QANotifier] 🌐 Calling QA service...');
    final result = await _qaService.askQuestion(
      transcript: transcript,
      questionText: trimmedQuestion,
    );
    debugPrint('[QANotifier] 📥 QA service response received');

    if (result.answer != null) {
      debugPrint('[QANotifier] ✅ Answer: "${result.answer!.text.substring(0, result.answer!.text.length > 50 ? 50 : result.answer!.text.length)}..."');
      _onDebugMessage?.call('✅ LLM response received successfully');
    } else if (result.error != null) {
      debugPrint('[QANotifier] ❌ Error: ${result.error}');
      _onDebugMessage?.call('❌ LLM error: ${result.error}');
    }

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
    debugPrint('[QANotifier] 📝 Added to history (total: ${state.history.length} entries)');

    // Auto-save conversation to history after successful Q&A
    if (newEntry.hasAnswer) {
      await _saveConversationToHistory();

      // In continuous mode, trigger TTS for the answer
      if (isContinuousMode && _onAnswerReadyForSpeech != null) {
        debugPrint('[QANotifier] 🔊 Triggering TTS for continuous mode');
        _onAnswerReadyForSpeech!(newEntry.answer!);
      }
      // Auto-speak for voice input (not continuous mode)
      else if (!isContinuousMode &&
          method == InputMethod.voice &&
          _onAutoSpeakCallback != null) {
        debugPrint('[QANotifier] 🔊 Triggering auto-speak for voice input');
        _onAutoSpeakCallback!(newEntry.answer!);
      } else {
        debugPrint('[QANotifier] 🔇 No TTS triggered (method: $method, callbacks set: ${_onAutoSpeakCallback != null})');
      }
    }
  }

  /// Set callback for continuous mode
  void setContinuousModeCallback(Function(String answer)? callback) {
    _onAnswerReadyForSpeech = callback;
  }

  /// Set callback for auto-speaking voice input answers
  void setAutoSpeakCallback(Function(String answer)? callback) {
    _onAutoSpeakCallback = callback;
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

  /// Toggle bottom bar state
  void setBottomBarState(BottomBarState newState) {
    state = state.copyWith(bottomBarState: newState);
  }

  /// Collapse bottom bar
  void collapseBottomBar() {
    state = state.copyWith(bottomBarState: BottomBarState.collapsed);
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
