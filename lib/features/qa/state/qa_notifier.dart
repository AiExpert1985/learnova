import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qa_history_entry.dart';
import '../services/qa_service.dart';
import 'qa_state.dart';

/// StateNotifier for Q&A feature
/// Centralizes all business logic for asking questions and managing history
class QANotifier extends StateNotifier<QAState> {
  final QAService _qaService;
  final String _transcript;

  QANotifier({
    required QAService qaService,
    required String transcript,
  })  : _qaService = qaService,
        _transcript = transcript,
        super(const QAState());

  /// Ask a question and update state with result
  Future<void> askQuestion(String questionText) async {
    final trimmedQuestion = questionText.trim();
    if (trimmedQuestion.isEmpty) return;

    state = state.copyWith(isLoading: true);

    final result = await _qaService.askQuestion(
      transcript: _transcript,
      questionText: trimmedQuestion,
    );

    final newEntry = QAHistoryEntry(
      question: trimmedQuestion,
      answer: result.answer?.text,
      error: result.error,
      tokensUsed: result.answer?.tokensUsed ?? 0,
    );

    state = state.copyWith(
      isLoading: false,
      history: [...state.history, newEntry],
    );
  }
}
