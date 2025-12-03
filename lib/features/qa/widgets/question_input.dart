import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../state/qa_state.dart';
import 'voice_input_button.dart';

/// Input field for asking questions
/// Voice-first design with optional text input fallback
class QuestionInput extends ConsumerStatefulWidget {
  const QuestionInput({super.key});

  @override
  ConsumerState<QuestionInput> createState() => _QuestionInputState();
}

class _QuestionInputState extends ConsumerState<QuestionInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref
        .read(qaNotifierProvider.notifier)
        .askQuestion(text, inputMethod: InputMethod.text);
    _controller.clear();
  }

  void _handleVoiceQuestion(String text) {
    // Voice input submits directly
    if (text.trim().isEmpty) return;
    ref
        .read(qaNotifierProvider.notifier)
        .askQuestion(text, inputMethod: InputMethod.voice);
  }

  @override
  Widget build(BuildContext context) {
    final qaState = ref.watch(qaNotifierProvider);
    final isLoading = qaState.isLoadingAnswer;
    final isTextInputVisible = qaState.isTextInputVisible;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice input button (always visible, prominent)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VoiceInputButton(onTextRecognized: _handleVoiceQuestion),
              if (!isTextInputVisible) ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(qaNotifierProvider.notifier)
                        .toggleTextInputVisibility();
                  },
                  icon: const Icon(Icons.keyboard, size: 18),
                  label: const Text('Type instead?'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
          // Text input (shown when user requests it)
          if (isTextInputVisible) ...[
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type your question...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      enabled: !isLoading,
                      onSubmitted: (_) => _handleSubmit(),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    icon: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    color: Colors.blue,
                  ),
                  IconButton(
                    onPressed: () {
                      ref
                          .read(qaNotifierProvider.notifier)
                          .toggleTextInputVisibility();
                      _controller.clear();
                    },
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
