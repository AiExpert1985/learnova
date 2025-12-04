import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../state/qa_state.dart';

/// Bottom action bar with expandable states
/// Shows 3 buttons (collapsed) or expanded input fields
class BottomActionBar extends ConsumerWidget {
  final VoidCallback onUrlPressed;
  final VoidCallback onAskPressed;
  final VoidCallback onChatPressed;

  const BottomActionBar({
    super.key,
    required this.onUrlPressed,
    required this.onAskPressed,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qaState = ref.watch(qaNotifierProvider);
    final barState = qaState.bottomBarState;
    final hasVideo = qaState.hasVideo;
    final isLoading = qaState.isLoadingVideo;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: barState == BottomBarState.collapsed
              ? _buildCollapsedBar(hasVideo, isLoading)
              : barState == BottomBarState.urlExpanded
                  ? const UrlInputBar()
                  : const AskInputBar(),
        ),
      ),
    );
  }

  Widget _buildCollapsedBar(bool hasVideo, bool isLoading) {
    // All buttons disabled except URL when no video or loading
    final buttonsEnabled = hasVideo && !isLoading;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add,
            label: 'URL',
            enabled: true, // Always enabled
            onPressed: onUrlPressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Ask',
            enabled: buttonsEnabled,
            onPressed: buttonsEnabled ? onAskPressed : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.history,
            label: 'Chat',
            enabled: buttonsEnabled,
            onPressed: buttonsEnabled ? onChatPressed : null,
          ),
        ),
      ],
    );
  }
}

/// Individual action button in collapsed state
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// URL input bar (expanded state)
class UrlInputBar extends ConsumerStatefulWidget {
  const UrlInputBar({super.key});

  @override
  ConsumerState<UrlInputBar> createState() => _UrlInputBarState();
}

class _UrlInputBarState extends ConsumerState<UrlInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    ref.read(qaNotifierProvider.notifier).loadVideo(url);
    _controller.clear();
    ref.read(qaNotifierProvider.notifier).collapseBottomBar();
  }

  void _handleCollapse() {
    _controller.clear();
    ref.read(qaNotifierProvider.notifier).collapseBottomBar();
  }

  @override
  Widget build(BuildContext context) {
    final qaState = ref.watch(qaNotifierProvider);
    final isLoading = qaState.isLoadingVideo;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Paste YouTube URL...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
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
        ElevatedButton(
          onPressed: isLoading ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Go'),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _handleCollapse,
          icon: const Icon(Icons.close),
          tooltip: 'Collapse',
        ),
      ],
    );
  }
}

/// Ask input bar (expanded state) with text and mic
class AskInputBar extends ConsumerStatefulWidget {
  const AskInputBar({super.key});

  @override
  ConsumerState<AskInputBar> createState() => _AskInputBarState();
}

class _AskInputBarState extends ConsumerState<AskInputBar> {
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
    ref.read(qaNotifierProvider.notifier).collapseBottomBar();
  }

  Future<void> _handleVoiceInput() async {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);

    // Start listening and get result
    final recognizedText = await voiceNotifier.startListening();

    if (recognizedText != null && recognizedText.isNotEmpty) {
      ref
          .read(qaNotifierProvider.notifier)
          .askQuestion(recognizedText, inputMethod: InputMethod.voice);
      ref.read(qaNotifierProvider.notifier).collapseBottomBar();
    }
  }

  void _handleCollapse() {
    _controller.clear();
    ref.read(qaNotifierProvider.notifier).collapseBottomBar();
  }

  @override
  Widget build(BuildContext context) {
    final qaState = ref.watch(qaNotifierProvider);
    final voiceState = ref.watch(voiceNotifierProvider);
    final isLoading = qaState.isLoadingAnswer;
    final isListening = voiceState.isListening;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Type your question...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            enabled: !isLoading && !isListening,
            onSubmitted: (_) => _handleSubmit(),
            autofocus: true,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isLoading || isListening ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Icon(Icons.send, size: 20),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: isLoading ? null : _handleVoiceInput,
          style: ElevatedButton.styleFrom(
            backgroundColor: isListening
                ? Colors.red.shade600
                : Colors.teal.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(
            isListening ? Icons.mic : Icons.mic_none,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _handleCollapse,
          icon: const Icon(Icons.close),
          tooltip: 'Collapse',
        ),
      ],
    );
  }
}
