/// Abstract repository interface for history storage (DB-agnostic)
library;

import '../models/conversation_history.dart';
import '../models/history_result.dart';

abstract class HistoryRepository {
  /// Get all conversations sorted by lastUpdated (newest first)
  Future<HistoryResult<List<ConversationHistory>>> getAll();

  /// Get conversation by ID
  Future<HistoryResult<ConversationHistory?>> getById(String id);

  /// Get conversation by video ID (returns most recent if multiple exist)
  Future<HistoryResult<ConversationHistory?>> getByVideoId(String videoId);

  /// Save or update conversation
  Future<HistoryResult<void>> save(ConversationHistory conversation);

  /// Delete conversation by ID
  Future<HistoryResult<void>> delete(String id);

  /// Delete all conversations
  Future<HistoryResult<void>> clear();

  /// Initialize storage (e.g., open Hive box)
  Future<HistoryResult<void>> initialize();

  /// Close storage (e.g., close Hive box)
  Future<HistoryResult<void>> close();
}
