/// Hive implementation of HistoryRepository
library;

import 'package:hive_flutter/hive_flutter.dart';
import '../models/conversation_history.dart';
import '../models/history_failures.dart';
import '../models/history_result.dart';
import '../adapters/hive_adapters.dart';
import 'history_repository.dart';

class HiveHistoryRepository implements HistoryRepository {
  static const String _boxName = 'conversation_history';
  Box<ConversationHistoryAdapter>? _box;

  @override
  Future<HistoryResult<void>> initialize() async {
    try {
      // Initialize Hive if not already initialized
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ConversationHistoryAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(QAEntryAdapterAdapter());
      }

      // Open box
      _box = await Hive.openBox<ConversationHistoryAdapter>(_boxName);
      return HistoryResult.success(null);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to initialize storage: $e'),
      );
    }
  }

  @override
  Future<HistoryResult<void>> close() async {
    try {
      await _box?.close();
      _box = null;
      return HistoryResult.success(null);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to close storage: $e'),
      );
    }
  }

  @override
  Future<HistoryResult<List<ConversationHistory>>> getAll() async {
    try {
      if (_box == null) {
        return HistoryResult.failure(
          StorageFailure('Storage not initialized'),
        );
      }

      final adapters = _box!.values.toList();
      final conversations = adapters.map((adapter) => adapter.toDomain()).toList();

      // Sort by lastUpdated (newest first)
      conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      return HistoryResult.success(conversations);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to retrieve conversations: $e'),
      );
    }
  }

  @override
  Future<HistoryResult<ConversationHistory?>> getById(String id) async {
    try {
      if (_box == null) {
        return HistoryResult.failure(
          StorageFailure('Storage not initialized'),
        );
      }

      final adapter = _box!.get(id);
      if (adapter == null) {
        return HistoryResult.success(null);
      }

      return HistoryResult.success(adapter.toDomain());
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to retrieve conversation: $e'),
      );
    }
  }

  @override
  Future<HistoryResult<ConversationHistory?>> getByVideoId(String videoId) async {
    try {
      if (_box == null) {
        return HistoryResult.failure(
          StorageFailure('Storage not initialized'),
        );
      }

      // Find all conversations for this video
      final adapters = _box!.values
          .where((adapter) => adapter.videoId == videoId)
          .toList();

      if (adapters.isEmpty) {
        return HistoryResult.success(null);
      }

      // Return most recent
      final conversations = adapters.map((adapter) => adapter.toDomain()).toList();
      conversations.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

      return HistoryResult.success(conversations.first);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to retrieve conversation by video ID: $e'),
      );
    }
  }

  @override
  Future<HistoryResult<void>> save(ConversationHistory conversation) async {
    try {
      if (_box == null) {
        return HistoryResult.failure(
          StorageFailure('Storage not initialized'),
        );
      }

      final adapter = ConversationHistoryAdapter.fromDomain(conversation);
      await _box!.put(conversation.id, adapter);

      return HistoryResult.success(null);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to save conversation: $e'),
      );
    }
  }

  @override
  Future<HistoryResult<void>> delete(String id) async {
    try {
      if (_box == null) {
        return HistoryResult.failure(
          StorageFailure('Storage not initialized'),
        );
      }

      await _box!.delete(id);
      return HistoryResult.success(null);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to delete conversation: $e'),
      );
    }
  }

  @override
  Future<HistoryResult<void>> clear() async {
    try {
      if (_box == null) {
        return HistoryResult.failure(
          StorageFailure('Storage not initialized'),
        );
      }

      await _box!.clear();
      return HistoryResult.success(null);
    } catch (e) {
      return HistoryResult.failure(
        StorageFailure('Failed to clear all conversations: $e'),
      );
    }
  }
}
