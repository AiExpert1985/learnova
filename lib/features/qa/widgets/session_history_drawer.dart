import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../models/qa_history_entry.dart';
import 'package:intl/intl.dart';

/// Collapsible drawer for current session Q&A history
/// Allows quick review without leaving QA screen
class SessionHistoryDrawer extends ConsumerWidget {
  final VoidCallback onClose;

  const SessionHistoryDrawer({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qaState = ref.watch(qaNotifierProvider);
    final history = qaState.history;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Session History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${history.length} Q&A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // History list
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No questions yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask a question to start',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return _HistoryItem(entry: entry, index: index + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Individual Q&A history item
class _HistoryItem extends StatelessWidget {
  final QAHistoryEntry entry;
  final int index;

  const _HistoryItem({
    required this.entry,
    required this.index,
  });

  String _formatTime(DateTime timestamp) {
    return DateFormat.jm().format(timestamp);
  }

  String _formatPosition(double? seconds) {
    if (seconds == null) return '';
    final minutes = (seconds ~/ 60);
    final secs = (seconds % 60).toInt();
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.question,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(entry.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (entry.videoPosition != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.play_circle_outline,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatPosition(entry.videoPosition),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Answer or error
            if (entry.hasAnswer || entry.hasError) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: entry.hasError
                      ? Colors.red.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      entry.hasError ? Icons.error_outline : Icons.lightbulb_outline,
                      size: 16,
                      color: entry.hasError
                          ? Colors.red.shade700
                          : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.hasError ? entry.error! : entry.answer!,
                        style: TextStyle(
                          fontSize: 13,
                          color: entry.hasError
                              ? Colors.red.shade900
                              : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
