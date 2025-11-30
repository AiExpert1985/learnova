import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../widgets/transcript_header.dart';
import '../widgets/question_input.dart';
import '../widgets/url_input.dart';
import '../widgets/error_banner.dart';
import '../widgets/qa_history_list.dart';

/// Main Q&A screen with YouTube integration
class QAScreen extends ConsumerWidget {
  const QAScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qaState = ref.watch(qaNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learnova'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          const UrlInput(),
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
    );
  }
}
