import 'package:flutter/material.dart';
import '../models/qa_history_entry.dart';

/// Question and answer bubbles for Q&A history
class QABubble extends StatelessWidget {
  final QAHistoryEntry entry;

  const QABubble({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionBubble(),
        const SizedBox(height: 8),
        _buildAnswerBubble(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestionBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(entry.question),
      ),
    );
  }

  Widget _buildAnswerBubble() {
    if (entry.hasError) {
      return _buildErrorBubble();
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.answer!),
            const SizedBox(height: 4),
            Text(
              'Tokens: ${entry.tokensUsed}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(child: Text(entry.error!)),
          ],
        ),
      ),
    );
  }
}
