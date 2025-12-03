/// Hive type adapters for storage layer
library;

import 'package:hive/hive.dart';
import '../models/conversation_history.dart';
import '../models/qa_entry.dart';

part 'hive_adapters.g.dart';

/// Hive adapter for ConversationHistory
@HiveType(typeId: 0)
class ConversationHistoryAdapter {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String videoId;

  @HiveField(2)
  final String videoTitle;

  @HiveField(3)
  final List<QAEntryAdapter> qaHistory;

  @HiveField(4)
  final int lastUpdatedMs;

  @HiveField(5)
  final int createdAtMs;

  ConversationHistoryAdapter({
    required this.id,
    required this.videoId,
    required this.videoTitle,
    required this.qaHistory,
    required this.lastUpdatedMs,
    required this.createdAtMs,
  });

  /// Convert from domain model to storage model
  factory ConversationHistoryAdapter.fromDomain(ConversationHistory domain) {
    return ConversationHistoryAdapter(
      id: domain.id,
      videoId: domain.videoId,
      videoTitle: domain.videoTitle,
      qaHistory: domain.qaHistory
          .map((entry) => QAEntryAdapter.fromDomain(entry))
          .toList(),
      lastUpdatedMs: domain.lastUpdated.millisecondsSinceEpoch,
      createdAtMs: domain.createdAt.millisecondsSinceEpoch,
    );
  }

  /// Convert from storage model to domain model
  ConversationHistory toDomain() {
    return ConversationHistory(
      id: id,
      videoId: videoId,
      videoTitle: videoTitle,
      qaHistory: qaHistory.map((adapter) => adapter.toDomain()).toList(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(lastUpdatedMs),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
    );
  }
}

/// Hive adapter for QAEntry
@HiveType(typeId: 1)
class QAEntryAdapter {
  @HiveField(0)
  final String question;

  @HiveField(1)
  final String answer;

  @HiveField(2)
  final int timestampMs;

  @HiveField(3)
  final double? videoPosition;

  @HiveField(4)
  final int tokensUsed;

  QAEntryAdapter({
    required this.question,
    required this.answer,
    required this.timestampMs,
    this.videoPosition,
    required this.tokensUsed,
  });

  /// Convert from domain model to storage model
  factory QAEntryAdapter.fromDomain(QAEntry domain) {
    return QAEntryAdapter(
      question: domain.question,
      answer: domain.answer,
      timestampMs: domain.timestamp.millisecondsSinceEpoch,
      videoPosition: domain.videoPosition,
      tokensUsed: domain.tokensUsed,
    );
  }

  /// Convert from storage model to domain model
  QAEntry toDomain() {
    return QAEntry(
      question: question,
      answer: answer,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
      videoPosition: videoPosition,
      tokensUsed: tokensUsed,
    );
  }
}
