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
import '../widgets/continuous_mode_toggle.dart';
import '../widgets/continuous_listening_indicator.dart';
import '../../history/ui/widgets/history_bottom_sheet.dart';
import '../../history/providers/history_providers.dart';

/// Main Q&A screen with YouTube integration
class QAScreen extends ConsumerStatefulWidget {
  const QAScreen({super.key});

  @override
  ConsumerState<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends ConsumerState<QAScreen> {
  void _showHistoryBottomSheet(BuildContext context) {
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

  void _handleContinuousModeToggle() async {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final qaNotifier = ref.read(qaNotifierProvider.notifier);

    // Set up the callback for QA notifier to speak answers
    qaNotifier.setContinuousModeCallback((answer) {
      voiceNotifier.speakAnswerAndResume(answer);
    });

    await voiceNotifier.toggleContinuousMode(
      onQuestion: (question) {
        // Process question through QA service
        qaNotifier.askQuestion(question, isContinuousMode: true);
      },
      onAnswerReady: (answer) {
        // This is called if TTS fails, to display answer as text
        // The answer is already in the QA history, so nothing to do here
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final qaState = ref.watch(qaNotifierProvider);
    final voiceState = ref.watch(voiceNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learnova'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Conversation History',
            onPressed: () => _showHistoryBottomSheet(context),
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
            // Continuous listening indicator
            if (qaState.hasVideo && voiceState.isContinuousModeEnabled)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ContinuousListeningIndicator(),
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
            if (qaState.hasVideo)
              Column(
                children: [
                  // Continuous mode toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ContinuousModeToggle(
                        onToggle: _handleContinuousModeToggle,
                      ),
                    ),
                  ),
                  const QuestionInput(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
