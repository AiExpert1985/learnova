import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/providers/app_providers.dart';
import '../state/qa_state.dart';
import 'chat_bottom_sheet.dart';
import 'video_player.dart';

/// Bottom action bar with expandable states
/// Shows 2 buttons (collapsed) or expanded input fields
class BottomActionBar extends ConsumerWidget {
  const BottomActionBar({super.key});

  void _handleUrlPressed(WidgetRef ref) {
    ref
        .read(qaNotifierProvider.notifier)
        .setBottomBarState(BottomBarState.urlExpanded);
  }

  Future<void> _handleChatPressed(BuildContext context, WidgetRef ref) async {
    // Stop continuous listening mode if active
    final voiceState = ref.read(voiceNotifierProvider);
    if (voiceState.isContinuousModeEnabled) {
      await ref.read(voiceNotifierProvider.notifier).stopContinuousMode();
    }

    // Pause video when chat opens
    final videoController = ref.read(youtubeControllerProvider);
    if (videoController != null) {
      final playerState = await videoController.playerState;
      if (playerState == PlayerState.playing) {
        await videoController.pauseVideo();
      }
    }

    // Check if widget is still mounted before using context
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ChatBottomSheet(onClose: () => Navigator.of(context).pop()),
    );
  }

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
              ? _buildCollapsedBar(context, ref, hasVideo, isLoading)
              : const UrlInputBar(),
        ),
      ),
    );
  }

  Widget _buildCollapsedBar(
    BuildContext context,
    WidgetRef ref,
    bool hasVideo,
    bool isLoading,
  ) {
    // Chat button disabled when no video or loading
    final buttonsEnabled = hasVideo && !isLoading;

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.add,
            label: 'URL',
            enabled: true, // Always enabled
            onPressed: () => _handleUrlPressed(ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            enabled: buttonsEnabled,
            onPressed: buttonsEnabled
                ? () => _handleChatPressed(context, ref)
                : null,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
