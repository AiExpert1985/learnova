import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
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
          UrlInput(
            isLoading: qaState.isLoadingVideo,
            onLoad: (url) =>
                ref.read(qaNotifierProvider.notifier).loadVideo(url),
          ),
          if (qaState.hasVideo)
            TranscriptHeader(
              title: qaState.videoTitle!,
              duration: qaState.videoDuration!,
            ),
          if (qaState.videoError != null)
            ErrorBanner(error: qaState.videoError!),
          Expanded(
            child: QAHistoryList(
              hasVideo: qaState.hasVideo,
              isLoadingVideo: qaState.isLoadingVideo,
              history: qaState.history,
            ),
          ),
          if (qaState.hasVideo) QuestionInput(isLoading: qaState.isLoading),
        ],
      ),
    );
  }
}
