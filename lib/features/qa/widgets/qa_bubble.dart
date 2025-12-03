import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qa_history_entry.dart';
import '../../../core/providers/app_providers.dart';

/// Question and answer bubbles for Q&A history
class QABubble extends ConsumerStatefulWidget {
  final QAHistoryEntry entry;

  const QABubble({
    super.key,
    required this.entry,
  });

  @override
  ConsumerState<QABubble> createState() => _QABubbleState();
}

class _QABubbleState extends ConsumerState<QABubble> {
  String? _speakingText;

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceNotifierProvider);

    // Check if this bubble's answer is currently being spoken
    final isSpeakingThisAnswer = voiceState.isSpeaking &&
        _speakingText == widget.entry.answer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionBubble(),
        const SizedBox(height: 8),
        _buildAnswerBubble(isSpeakingThisAnswer),
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
        child: Text(widget.entry.question),
      ),
    );
  }

  Widget _buildAnswerBubble(bool isSpeaking) {
    if (widget.entry.hasError) {
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
            Text(widget.entry.answer!),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _handleVoiceOutput(isSpeaking),
                  icon: Icon(
                    isSpeaking ? Icons.stop : Icons.volume_up,
                    size: 20,
                  ),
                  color: isSpeaking ? Colors.red : Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isSpeaking ? 'Stop speaking' : 'Speak answer',
                ),
                const SizedBox(width: 8),
                Text(
                  'Tokens: ${widget.entry.tokensUsed}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleVoiceOutput(bool isSpeaking) {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);

    if (isSpeaking) {
      voiceNotifier.stopSpeaking();
      _speakingText = null;
    } else {
      _speakingText = widget.entry.answer;
      voiceNotifier.speak(widget.entry.answer!);
    }
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
            Flexible(child: Text(widget.entry.error!)),
          ],
        ),
      ),
    );
  }
}
