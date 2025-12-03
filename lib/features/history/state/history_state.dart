/// State for history feature
library;

import '../data/models/conversation_history.dart';
import '../data/models/history_failures.dart';

class HistoryState {
  final List<ConversationHistory> conversations;
  final bool isLoading;
  final HistoryFailure? error;

  const HistoryState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  bool get hasConversations => conversations.isNotEmpty;
  bool get hasError => error != null;

  HistoryState copyWith({
    List<ConversationHistory>? conversations,
    bool? isLoading,
    HistoryFailure? error,
  }) {
    return HistoryState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  HistoryState setLoading() {
    return HistoryState(
      conversations: conversations,
      isLoading: true,
      error: null,
    );
  }

  HistoryState setError(HistoryFailure failure) {
    return copyWith(isLoading: false, error: failure);
  }

  HistoryState setConversations(List<ConversationHistory> conversations) {
    return HistoryState(
      conversations: conversations,
      isLoading: false,
      error: null,
    );
  }

  HistoryState clearError() {
    return HistoryState(
      conversations: conversations,
      isLoading: isLoading,
      error: null,
    );
  }
}
