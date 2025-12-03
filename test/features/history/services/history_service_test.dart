import 'package:flutter_test/flutter_test.dart';
import 'package:learnova/features/history/data/models/conversation_history.dart';
import 'package:learnova/features/history/data/models/qa_entry.dart';
import 'package:learnova/features/history/data/models/history_result.dart';
import 'package:learnova/features/history/data/repositories/history_repository.dart';
import 'package:learnova/features/history/services/history_service.dart';

/// Mock repository for testing
class MockHistoryRepository implements HistoryRepository {
  final Map<String, ConversationHistory> _storage = {};

  @override
  Future<HistoryResult<void>> initialize() async {
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<void>> close() async {
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<List<ConversationHistory>>> getAll() async {
    final conversations = _storage.values.toList();
    conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return HistoryResult.success(conversations);
  }

  @override
  Future<HistoryResult<ConversationHistory?>> getById(String id) async {
    return HistoryResult.success(_storage[id]);
  }

  @override
  Future<HistoryResult<ConversationHistory?>> getByVideoId(String videoId) async {
    final conversations = _storage.values
        .where((conv) => conv.videoId == videoId)
        .toList();

    if (conversations.isEmpty) {
      return HistoryResult.success(null);
    }

    conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return HistoryResult.success(conversations.first);
  }

  @override
  Future<HistoryResult<void>> save(ConversationHistory conversation) async {
    _storage[conversation.id] = conversation;
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<void>> delete(String id) async {
    _storage.remove(id);
    return HistoryResult.success(null);
  }

  @override
  Future<HistoryResult<void>> clear() async {
    _storage.clear();
    return HistoryResult.success(null);
  }
}

void main() {
  late HistoryService service;
  late MockHistoryRepository mockRepository;

  setUp(() {
    mockRepository = MockHistoryRepository();
    service = HistoryService(mockRepository);
  });

  group('HistoryService', () {
    test('saveConversation should create new conversation for new video', () async {
      final qaHistory = [
        QAEntry(
          question: 'What is this?',
          answer: 'This is a test',
          timestamp: DateTime.now(),
          tokensUsed: 10,
        ),
      ];

      final result = await service.saveConversation(
        videoId: 'video123',
        videoTitle: 'Test Video',
        qaHistory: qaHistory,
      );

      expect(result.isSuccess, true);
      expect(result.data!.videoId, 'video123');
      expect(result.data!.videoTitle, 'Test Video');
      expect(result.data!.qaHistory.length, 1);
    });

    test('saveConversation should update existing conversation for same video', () async {
      // Create initial conversation
      final initialQA = [
        QAEntry(
          question: 'First question',
          answer: 'First answer',
          timestamp: DateTime.now(),
          tokensUsed: 10,
        ),
      ];

      final firstResult = await service.saveConversation(
        videoId: 'video123',
        videoTitle: 'Test Video',
        qaHistory: initialQA,
      );

      expect(firstResult.isSuccess, true);
      final firstId = firstResult.data!.id;

      // Update with new Q&A
      await Future.delayed(Duration(milliseconds: 10));
      final updatedQA = [
        ...initialQA,
        QAEntry(
          question: 'Second question',
          answer: 'Second answer',
          timestamp: DateTime.now(),
          tokensUsed: 15,
        ),
      ];

      final secondResult = await service.saveConversation(
        videoId: 'video123',
        videoTitle: 'Test Video',
        qaHistory: updatedQA,
      );

      expect(secondResult.isSuccess, true);
      expect(secondResult.data!.id, firstId); // Same conversation
      expect(secondResult.data!.qaHistory.length, 2);
    });

    test('loadAllConversations should return sorted conversations', () async {
      await service.saveConversation(
        videoId: 'video1',
        videoTitle: 'Video 1',
        qaHistory: [],
      );

      await Future.delayed(Duration(milliseconds: 10));
      await service.saveConversation(
        videoId: 'video2',
        videoTitle: 'Video 2',
        qaHistory: [],
      );

      final result = await service.loadAllConversations();

      expect(result.isSuccess, true);
      expect(result.data!.length, 2);
      expect(result.data!.first.videoId, 'video2'); // Most recent first
    });

    test('loadConversationById should return specific conversation', () async {
      final saveResult = await service.saveConversation(
        videoId: 'video123',
        videoTitle: 'Test Video',
        qaHistory: [],
      );

      final conversationId = saveResult.data!.id;
      final loadResult = await service.loadConversationById(conversationId);

      expect(loadResult.isSuccess, true);
      expect(loadResult.data, isNotNull);
      expect(loadResult.data!.id, conversationId);
    });

    test('deleteConversation should remove conversation', () async {
      final saveResult = await service.saveConversation(
        videoId: 'video123',
        videoTitle: 'Test Video',
        qaHistory: [],
      );

      final conversationId = saveResult.data!.id;
      final deleteResult = await service.deleteConversation(conversationId);

      expect(deleteResult.isSuccess, true);

      final loadResult = await service.loadConversationById(conversationId);
      expect(loadResult.data, isNull);
    });

    test('clearAllHistory should remove all conversations', () async {
      await service.saveConversation(
        videoId: 'video1',
        videoTitle: 'Video 1',
        qaHistory: [],
      );
      await service.saveConversation(
        videoId: 'video2',
        videoTitle: 'Video 2',
        qaHistory: [],
      );

      final clearResult = await service.clearAllHistory();
      expect(clearResult.isSuccess, true);

      final loadResult = await service.loadAllConversations();
      expect(loadResult.data!.length, 0);
    });
  });
}
