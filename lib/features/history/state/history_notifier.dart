/// StateNotifier for history feature
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/history_service.dart';
import 'history_state.dart';

class HistoryNotifier extends StateNotifier<HistoryState> {
  final HistoryService _historyService;

  HistoryNotifier({
    required HistoryService historyService,
  })  : _historyService = historyService,
        super(const HistoryState());

  /// Initialize storage on app start
  Future<void> initialize() async {
    final result = await _historyService.initialize();

    if (result.isFailure) {
      state = state.setError(result.failure!);
      return;
    }

    // Load initial conversations after initialization
    await loadHistory();
  }

  /// Load all conversations from storage
  Future<void> loadHistory() async {
    state = state.setLoading();

    final result = await _historyService.loadAllConversations();

    if (result.isSuccess) {
      state = state.setConversations(result.data!);
    } else {
      state = state.setError(result.failure!);
    }
  }

  /// Delete conversation by ID
  Future<void> deleteConversation(String id) async {
    final result = await _historyService.deleteConversation(id);

    if (result.isSuccess) {
      // Reload history after deletion
      await loadHistory();
    } else {
      state = state.setError(result.failure!);
    }
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    final result = await _historyService.clearAllHistory();

    if (result.isSuccess) {
      state = state.setConversations([]);
    } else {
      state = state.setError(result.failure!);
    }
  }

  /// Clear error state
  void clearError() {
    state = state.clearError();
  }
}
