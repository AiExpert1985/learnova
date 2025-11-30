import 'package:flutter_test/flutter_test.dart';
import 'package:learnova/features/qa/state/qa_notifier.dart';
import 'package:learnova/features/qa/services/qa_service.dart';
import 'package:learnova/features/qa/models/qa_models.dart';
import 'package:learnova/core/services/youtube/youtube_service.dart';
import 'package:learnova/core/services/youtube/youtube_models.dart';

/// Mock QAService for testing
class MockQAService implements QAService {
  final QAResult mockResult;

  MockQAService({required this.mockResult});

  @override
  Future<QAResult> askQuestion({
    required String transcript,
    required String questionText,
  }) async {
    return mockResult;
  }
}

/// Mock YouTubeService for testing
class MockYouTubeService implements YouTubeService {
  final YouTubeResult mockResult;

  MockYouTubeService({required this.mockResult});

  @override
  Future<YouTubeResult> fetchVideo(String url) async {
    return mockResult;
  }

  @override
  void dispose() {}
}

void main() {
  group('QANotifier', () {
    test('initial state is empty', () {
      final mockQAService = MockQAService(
        mockResult: QAResult.success(
          Answer(text: 'Test', timestamp: DateTime.now(), tokensUsed: 100),
        ),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      expect(notifier.state.history.isEmpty, true);
      expect(notifier.state.isLoadingAnswer, false);
      expect(notifier.state.hasVideo, false);
      expect(notifier.state.videoTitle, null);
    });

    test('loadVideo updates state with video info', () async {
      final mockQAService = MockQAService(
        mockResult: QAResult.success(
          Answer(text: 'Test', timestamp: DateTime.now(), tokensUsed: 100),
        ),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test123',
            title: 'How to Code',
            duration: Duration(minutes: 10),
            transcript: 'This is a transcript about coding',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      await notifier.loadVideo('https://youtube.com/watch?v=test123');

      expect(notifier.state.hasVideo, true);
      expect(notifier.state.videoTitle, 'How to Code');
      expect(notifier.state.videoDuration, const Duration(minutes: 10));
      expect(notifier.state.transcript, 'This is a transcript about coding');
      expect(notifier.state.isLoadingVideo, false);
    });

    test('loadVideo handles errors gracefully', () async {
      final mockQAService = MockQAService(
        mockResult: QAResult.success(
          Answer(text: 'Test', timestamp: DateTime.now(), tokensUsed: 100),
        ),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.failure('Invalid YouTube URL'),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      await notifier.loadVideo('invalid-url');

      expect(notifier.state.hasVideo, false);
      expect(notifier.state.videoError, 'Invalid YouTube URL');
      expect(notifier.state.isLoadingVideo, false);
    });

    test('askQuestion updates state with successful result', () async {
      final mockAnswer = Answer(
        text: 'Test answer',
        timestamp: DateTime.now(),
        tokensUsed: 150,
      );
      final mockQAService = MockQAService(
        mockResult: QAResult.success(mockAnswer),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      // Load video first
      await notifier.loadVideo('https://youtube.com/watch?v=test');

      // Then ask question
      await notifier.askQuestion('What is this about?');

      expect(notifier.state.history.length, 1);
      expect(notifier.state.history.first.question, 'What is this about?');
      expect(notifier.state.history.first.answer, 'Test answer');
      expect(notifier.state.history.first.tokensUsed, 150);
      expect(notifier.state.history.first.hasError, false);
      expect(notifier.state.isLoadingAnswer, false);
    });

    test('askQuestion updates state with error result', () async {
      final mockQAService = MockQAService(
        mockResult: QAResult.failure('Rate limit exceeded'),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      // Load video first
      await notifier.loadVideo('https://youtube.com/watch?v=test');

      // Then ask question
      await notifier.askQuestion('What is this about?');

      expect(notifier.state.history.length, 1);
      expect(notifier.state.history.first.question, 'What is this about?');
      expect(notifier.state.history.first.hasError, true);
      expect(notifier.state.history.first.error, 'Rate limit exceeded');
      expect(notifier.state.isLoadingAnswer, false);
    });

    test('askQuestion does nothing when no video loaded', () async {
      final mockQAService = MockQAService(
        mockResult: QAResult.success(
          Answer(text: 'Test', timestamp: DateTime.now(), tokensUsed: 100),
        ),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      // Try to ask question without loading video
      await notifier.askQuestion('What is this about?');

      // History should remain empty
      expect(notifier.state.history.isEmpty, true);
    });

    test('askQuestion ignores empty or whitespace questions', () async {
      final mockQAService = MockQAService(
        mockResult: QAResult.success(
          Answer(text: 'Test', timestamp: DateTime.now(), tokensUsed: 100),
        ),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      // Load video first
      await notifier.loadVideo('https://youtube.com/watch?v=test');

      await notifier.askQuestion('');
      expect(notifier.state.history.isEmpty, true);

      await notifier.askQuestion('   ');
      expect(notifier.state.history.isEmpty, true);
    });

    test('askQuestion trims whitespace from questions', () async {
      final mockAnswer = Answer(
        text: 'Test answer',
        timestamp: DateTime.now(),
        tokensUsed: 100,
      );
      final mockQAService = MockQAService(
        mockResult: QAResult.success(mockAnswer),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      // Load video first
      await notifier.loadVideo('https://youtube.com/watch?v=test');

      await notifier.askQuestion('  What is this?  ');

      expect(notifier.state.history.length, 1);
      expect(notifier.state.history.first.question, 'What is this?');
    });

    test('multiple questions accumulate in history', () async {
      final mockAnswer = Answer(
        text: 'Test answer',
        timestamp: DateTime.now(),
        tokensUsed: 100,
      );
      final mockQAService = MockQAService(
        mockResult: QAResult.success(mockAnswer),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      // Load video first
      await notifier.loadVideo('https://youtube.com/watch?v=test');

      await notifier.askQuestion('Question 1');
      await notifier.askQuestion('Question 2');
      await notifier.askQuestion('Question 3');

      expect(notifier.state.history.length, 3);
      expect(notifier.state.history[0].question, 'Question 1');
      expect(notifier.state.history[1].question, 'Question 2');
      expect(notifier.state.history[2].question, 'Question 3');
    });

    test('loading new video clears previous history', () async {
      final mockAnswer = Answer(
        text: 'Test answer',
        timestamp: DateTime.now(),
        tokensUsed: 100,
      );
      final mockQAService = MockQAService(
        mockResult: QAResult.success(mockAnswer),
      );
      final mockYouTubeService = MockYouTubeService(
        mockResult: YouTubeResult.success(
          const VideoInfo(
            id: 'test',
            title: 'Test Video',
            duration: Duration(minutes: 5),
            transcript: 'Test transcript',
          ),
        ),
      );
      final notifier = QANotifier(
        qaService: mockQAService,
        youtubeService: mockYouTubeService,
      );

      // Load video and ask questions
      await notifier.loadVideo('https://youtube.com/watch?v=test1');
      await notifier.askQuestion('Question 1');
      await notifier.askQuestion('Question 2');

      expect(notifier.state.history.length, 2);

      // Load new video - should clear history
      await notifier.loadVideo('https://youtube.com/watch?v=test2');

      expect(notifier.state.history.isEmpty, true);
    });
  });
}
