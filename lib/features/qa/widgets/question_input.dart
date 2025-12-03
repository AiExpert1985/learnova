import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import 'voice_input_button.dart';

/// Input field for asking questions
/// Calls QANotifier directly without callbacks
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

    ref.read(qaNotifierProvider.notifier).askQuestion(text);
    _controller.clear();
  }

  void _handleVoiceText(String text) {
    _controller.text = text;
    // Optionally auto-submit
    // _handleSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      qaNotifierProvider.select((state) => state.isLoadingAnswer),
    );

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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Ask a question...',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
              onSubmitted: (_) => _handleSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          VoiceInputButton(onTextRecognized: _handleVoiceText),
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
        ],
      ),
    );
  }
}
