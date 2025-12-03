/// Public API for history feature - used by other features
library;

import '../data/models/conversation_history.dart';
import '../data/models/qa_entry.dart';
import '../data/models/history_result.dart';
import '../data/models/history_failures.dart';
import '../data/repositories/history_repository.dart';

class HistoryService {
  final HistoryRepository _repository;

  HistoryService(this._repository);

  /// Initialize storage
  Future<HistoryResult<void>> initialize() async {
    return await _repository.initialize();
  }

  /// Save or update conversation
  /// Creates new conversation if videoId doesn't exist,
  /// otherwise updates existing conversation
  Future<HistoryResult<ConversationHistory>> saveConversation({
    required String videoId,
    required String videoTitle,
    required List<QAEntry> qaHistory,
  }) async {
    try {
      // Check if conversation exists for this video
      final existingResult = await _repository.getByVideoId(videoId);

      if (existingResult.isFailure) {
        return HistoryResult.failure(existingResult.failure!);
      }

      final ConversationHistory conversation;

      if (existingResult.data != null) {
        // Update existing conversation
        conversation = existingResult.data!.updateQAHistory(qaHistory);
      } else {
        // Create new conversation
        conversation = ConversationHistory.create(
          videoId: videoId,
          videoTitle: videoTitle,
          initialQAHistory: qaHistory,
        );
      }

      final saveResult = await _repository.save(conversation);

      if (saveResult.isFailure) {
        return HistoryResult.failure(saveResult.failure!);
      }

      return HistoryResult.success(conversation);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to save conversation: $e'),
      );
    }
  }

  /// Get all conversations sorted by most recent
  Future<HistoryResult<List<ConversationHistory>>> loadAllConversations() async {
    return await _repository.getAll();
  }

  /// Load specific conversation by ID
  Future<HistoryResult<ConversationHistory?>> loadConversationById(
    String id,
  ) async {
    return await _repository.getById(id);
  }

  /// Load conversation by video ID (returns most recent)
  Future<HistoryResult<ConversationHistory?>> loadConversationByVideoId(
    String videoId,
  ) async {
    return await _repository.getByVideoId(videoId);
  }

  /// Delete conversation
  Future<HistoryResult<void>> deleteConversation(String id) async {
    return await _repository.delete(id);
  }

  /// Clear all history
  Future<HistoryResult<void>> clearAllHistory() async {
    return await _repository.clear();
  }

  /// Close storage
  Future<HistoryResult<void>> close() async {
    return await _repository.close();
  }
}
