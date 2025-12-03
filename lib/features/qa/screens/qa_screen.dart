import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../widgets/transcript_header.dart';
import '../widgets/question_input.dart';
import '../widgets/url_input.dart';
import '../widgets/error_banner.dart';
import '../widgets/qa_history_list.dart';
import '../widgets/video_player.dart';
import '../../history/ui/widgets/history_bottom_sheet.dart';
import '../../history/providers/history_providers.dart';

/// Main Q&A screen with YouTube integration
class QAScreen extends ConsumerWidget {
  const QAScreen({super.key});

  void _showHistoryBottomSheet(BuildContext context, WidgetRef ref) {
    // Refresh history before showing
    ref.read(historyNotifierProvider.notifier).loadHistory();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const HistoryBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qaState = ref.watch(qaNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learnova'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Conversation History',
            onPressed: () => _showHistoryBottomSheet(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            const UrlInput(),
            if (qaState.hasVideo) VideoPlayer(videoId: qaState.videoId!),
            if (qaState.hasVideo)
              TranscriptHeader(
                title: qaState.videoTitle!,
                duration: qaState.videoDuration!,
              ),
            if (qaState.videoError != null && qaState.videoError!.isNotEmpty)
              ErrorBanner(error: qaState.videoError!),
            if (qaState.hasVideo)
              const Expanded(child: QAHistoryList())
            else
              Expanded(
                child: EmptyState(
                  icon: Icons.video_library_outlined,
                  message: 'Paste a YouTube URL and press play to start',
                ),
              ),
            if (qaState.hasVideo) const QuestionInput(),
          ],
        ),
      ),
    );
  }
}
