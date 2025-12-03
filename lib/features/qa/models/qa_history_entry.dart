/// History entry for Q&A interaction
class QAHistoryEntry {
  final String question;
  final String? answer;
  final String? error;
  final int tokensUsed;
  final DateTime timestamp;
  final double? videoPosition; // Video position in seconds when question was asked

  QAHistoryEntry({
    required this.question,
    this.answer,
    this.error,
    required this.tokensUsed,
    DateTime? timestamp,
    this.videoPosition,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get hasError => error != null;
  bool get hasAnswer => answer != null;
}
