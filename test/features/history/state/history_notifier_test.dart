import 'package:flutter_test/flutter_test.dart';
import 'package:learnova/features/history/data/models/conversation_history.dart';
import 'package:learnova/features/history/data/models/history_failures.dart';
import 'package:learnova/features/history/data/models/history_result.dart';
import 'package:learnova/features/history/data/models/qa_entry.dart';
import 'package:learnova/features/history/services/history_service.dart';
import 'package:learnova/features/history/state/history_notifier.dart';

/// Mock service for testing
class MockHistoryService implements HistoryService {
  final List<ConversationHistory> _mockConversations = [];
  bool _shouldFail = false;

  void setShouldFail(bool value) => _shouldFail = value;

  void addMockConversation(ConversationHistory conversation) {
    _mockConversations.add(conversation);
  }

  @override
  Future<HistoryResult<void>> initialize() async {
    if (_shouldFail) {
      return HistoryResult.failure(
        StorageFailure('Mock initialization failed'),
      );
    }
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<List<ConversationHistory>>> loadAllConversations() async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock load failed'));
    }
    return HistoryResult.success(List.from(_mockConversations));
  }

  @override
  Future<HistoryResult<void>> deleteConversation(String id) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock delete failed'));
    }
    _mockConversations.removeWhere((conv) => conv.id == id);
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<void>> clearAllHistory() async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock clear failed'));
    }
    _mockConversations.clear();
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<ConversationHistory>> saveConversation({
    required String videoId,
    required String videoTitle,
    required List<QAEntry> qaHistory,
  }) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock save failed'));
    }
    final conversation = ConversationHistory.create(
      videoId: videoId,
      videoTitle: videoTitle,
      initialQAHistory: qaHistory,
    );
    _mockConversations.add(conversation);
    return HistoryResult.success(conversation);
  }

  @override
  Future<HistoryResult<ConversationHistory?>> loadConversationById(String id) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock load failed'));
    }
    final conversation = _mockConversations.where((c) => c.id == id).firstOrNull;
    return HistoryResult.success(conversation);
  }

  @override
  Future<HistoryResult<ConversationHistory?>> loadConversationByVideoId(String videoId) async {
    if (_shouldFail) {
      return HistoryResult.failure(StorageFailure('Mock load failed'));
    }
    final conversation = _mockConversations.where((c) => c.videoId == videoId).firstOrNull;
    return HistoryResult.success(conversation);
  }

  @override
  Future<HistoryResult<void>> close() async {
    return HistoryResult.success(null);
  }
}

void main() {
  late HistoryNotifier notifier;
  late MockHistoryService mockService;

  setUp(() {
    mockService = MockHistoryService();
    notifier = HistoryNotifier(historyService: mockService);
  });

  group('HistoryNotifier', () {
    test('initialize should load conversations on success', () async {
      final conversation = ConversationHistory.create(
        videoId: 'video123',
        videoTitle: 'Test Video',
      );
      mockService.addMockConversation(conversation);

      await notifier.initialize();

      expect(notifier.state.hasConversations, true);
      expect(notifier.state.conversations.length, 1);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.hasError, false);
    });

    test('initialize should set error on failure', () async {
      mockService.setShouldFail(true);

      await notifier.initialize();

      expect(notifier.state.hasError, true);
      expect(notifier.state.hasConversations, false);
    });

    test('loadHistory should update state with conversations', () async {
      final conversations = [
        ConversationHistory.create(
          videoId: 'video1',
          videoTitle: 'Video 1',
        ),
        ConversationHistory.create(
          videoId: 'video2',
          videoTitle: 'Video 2',
        ),
      ];

      for (final conv in conversations) {
        mockService.addMockConversation(conv);
      }

      await notifier.loadHistory();

      expect(notifier.state.conversations.length, 2);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.hasError, false);
    });

    test('loadHistory should set error on failure', () async {
      mockService.setShouldFail(true);

      await notifier.loadHistory();

      expect(notifier.state.hasError, true);
      expect(notifier.state.isLoading, false);
    });

    test('deleteConversation should remove conversation and reload', () async {
      final conv1 = ConversationHistory.create(
        videoId: 'video1',
        videoTitle: 'Video 1',
      );
      final conv2 = ConversationHistory.create(
        videoId: 'video2',
        videoTitle: 'Video 2',
      );

      mockService.addMockConversation(conv1);
      mockService.addMockConversation(conv2);

      await notifier.loadHistory();
      expect(notifier.state.conversations.length, 2);

      await notifier.deleteConversation(conv1.id);
      expect(notifier.state.conversations.length, 1);
      expect(notifier.state.conversations.first.id, conv2.id);
    });

    test('deleteConversation should set error on failure', () async {
      mockService.setShouldFail(true);

      await notifier.deleteConversation('any_id');

      expect(notifier.state.hasError, true);
    });

    test('clearAllHistory should remove all conversations', () async {
      mockService.addMockConversation(
        ConversationHistory.create(
          videoId: 'video1',
          videoTitle: 'Video 1',
        ),
      );

      await notifier.loadHistory();
      expect(notifier.state.hasConversations, true);

      await notifier.clearAllHistory();
      expect(notifier.state.hasConversations, false);
    });

    test('clearError should remove error from state', () async {
      mockService.setShouldFail(true);
      await notifier.loadHistory();
      expect(notifier.state.hasError, true);

      notifier.clearError();
      expect(notifier.state.hasError, false);
    });
  });
}
