import '../models/qa_history_entry.dart';

/// State for Q&A feature
/// Manages question history and loading status
class QAState {
  final List<QAHistoryEntry> history;
  final bool isLoading;

  const QAState({
    this.history = const [],
    this.isLoading = false,
  });

  QAState copyWith({
    List<QAHistoryEntry>? history,
    bool? isLoading,
  }) {
    return QAState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
