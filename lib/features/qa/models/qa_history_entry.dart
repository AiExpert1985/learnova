/// History entry for Q&A interaction
class QAHistoryEntry {
  final String question;
  final String? answer;
  final String? error;
  final int tokensUsed;

  QAHistoryEntry({
    required this.question,
    this.answer,
    this.error,
    required this.tokensUsed,
  });

  bool get hasError => error != null;
  bool get hasAnswer => answer != null;
}
