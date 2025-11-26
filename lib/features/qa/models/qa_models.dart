/// Data models for Question & Answer feature

class Question {
  final String text;
  final DateTime timestamp;

  Question({
    required this.text,
    required this.timestamp,
  });

  bool get isEmpty => text.trim().isEmpty;
}

class Answer {
  final String text;
  final DateTime timestamp;
  final int tokensUsed;

  Answer({
    required this.text,
    required this.timestamp,
    required this.tokensUsed,
  });
}

class QAResult {
  final Answer? answer;
  final String? error;

  QAResult.success(this.answer) : error = null;
  QAResult.failure(this.error) : answer = null;

  bool get isSuccess => answer != null;
  bool get isFailure => error != null;
}
