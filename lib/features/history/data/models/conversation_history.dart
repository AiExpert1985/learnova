/// Conversation history for a video (DB-agnostic domain model)
library;

import 'qa_entry.dart';

class ConversationHistory {
  final String id;
  final String videoId;
  final String videoTitle;
  final List<QAEntry> qaHistory;
  final DateTime lastUpdated;
  final DateTime createdAt;

  const ConversationHistory({
    required this.id,
    required this.videoId,
    required this.videoTitle,
    required this.qaHistory,
    required this.lastUpdated,
    required this.createdAt,
  });

  /// Create new conversation
  factory ConversationHistory.create({
    required String videoId,
    required String videoTitle,
    List<QAEntry>? initialQAHistory,
  }) {
    final now = DateTime.now();
    return ConversationHistory(
      id: _generateId(videoId, now),
      videoId: videoId,
      videoTitle: videoTitle,
      qaHistory: initialQAHistory ?? [],
      lastUpdated: now,
      createdAt: now,
    );
  }

  /// Generate unique ID based on video and timestamp
  static String _generateId(String videoId, DateTime timestamp) {
    return '${videoId}_${timestamp.millisecondsSinceEpoch}';
  }

  /// Add new Q&A entry
  ConversationHistory addQAEntry(QAEntry entry) {
    return copyWith(
      qaHistory: [...qaHistory, entry],
      lastUpdated: DateTime.now(),
    );
  }

  /// Update existing conversation with new Q&A list
  ConversationHistory updateQAHistory(List<QAEntry> newQAHistory) {
    return copyWith(
      qaHistory: newQAHistory,
      lastUpdated: DateTime.now(),
    );
  }

  ConversationHistory copyWith({
    String? id,
    String? videoId,
    String? videoTitle,
    List<QAEntry>? qaHistory,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return ConversationHistory(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      videoTitle: videoTitle ?? this.videoTitle,
      qaHistory: qaHistory ?? this.qaHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationHistory &&
          id == other.id &&
          videoId == other.videoId &&
          videoTitle == other.videoTitle;

  @override
  int get hashCode => id.hashCode ^ videoId.hashCode ^ videoTitle.hashCode;
}
