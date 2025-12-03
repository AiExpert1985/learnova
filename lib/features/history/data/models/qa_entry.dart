/// Q&A entry for conversation history (DB-agnostic domain model)
library;

class QAEntry {
  final String question;
  final String answer;
  final DateTime timestamp;
  final double? videoPosition; // Video position in seconds when question was asked
  final int tokensUsed;

  const QAEntry({
    required this.question,
    required this.answer,
    required this.timestamp,
    this.videoPosition,
    required this.tokensUsed,
  });

  /// Create from QA feature's history entry
  factory QAEntry.fromQAHistory({
    required String question,
    required String answer,
    required DateTime timestamp,
    double? videoPosition,
    required int tokensUsed,
  }) {
    return QAEntry(
      question: question,
      answer: answer,
      timestamp: timestamp,
      videoPosition: videoPosition,
      tokensUsed: tokensUsed,
    );
  }

  QAEntry copyWith({
    String? question,
    String? answer,
    DateTime? timestamp,
    double? videoPosition,
    int? tokensUsed,
  }) {
    return QAEntry(
      question: question ?? this.question,
      answer: answer ?? this.answer,
      timestamp: timestamp ?? this.timestamp,
      videoPosition: videoPosition ?? this.videoPosition,
      tokensUsed: tokensUsed ?? this.tokensUsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QAEntry &&
          question == other.question &&
          answer == other.answer &&
          timestamp == other.timestamp &&
          videoPosition == other.videoPosition &&
          tokensUsed == other.tokensUsed;

  @override
  int get hashCode =>
      question.hashCode ^
      answer.hashCode ^
      timestamp.hashCode ^
      videoPosition.hashCode ^
      tokensUsed.hashCode;
}
