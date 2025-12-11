import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../widgets/headphone_required_dialog.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/listening_toggle_button.dart';
import '../widgets/qa_video_section.dart';
import '../widgets/video_player.dart';
import '../../history/ui/widgets/history_bottom_sheet.dart';
import '../../history/providers/history_providers.dart';
import '../../../core/services/voice/voice_models.dart';
import '../state/qa_state.dart';
import '../utils/qa_actions.dart';

/// Main Q&A screen with YouTube integration
class QAScreen extends ConsumerStatefulWidget {
  const QAScreen({super.key});

  @override
  ConsumerState<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends ConsumerState<QAScreen>
    with WidgetsBindingObserver {
  bool _wasInContinuousMode = false;
  bool _autoEnabledContinuousMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Simplified lifecycle handler - delegating most logic would be better but keeping simple here
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final voiceState = ref.read(voiceNotifierProvider);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (voiceState.isContinuousModeEnabled) {
        _wasInContinuousMode = true;
        voiceNotifier.stopContinuousMode();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasInContinuousMode && mounted) {
        _wasInContinuousMode = false;
        _showResumeDialog();
      }
    }
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Continuous Mode?'),
        content: const Text(
          'Continuous listening was paused when you left the app. Would you like to resume?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              toggleContinuousModeWithVideo(ref);
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context) {
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

  void _listenToStateChanges() {
    // 1. Listen for Headphone Requirements
    ref.listen(voiceNotifierProvider, (previous, next) {
      if (next.error == 'headphone_required' &&
          previous?.error != 'headphone_required') {
        showHeadphoneRequiredDialog(context);
        ref.read(voiceNotifierProvider.notifier).clearError();
      }

      // 2. Video Control Synchronization (Resume Video)
      if (next.continuousListeningState == ContinuousListeningState.listening &&
          previous?.continuousListeningState ==
              ContinuousListeningState.waitingForNextQuestion) {
        ref.read(youtubeControllerProvider)?.playVideo();
      }

      // 3. Video Control Synchronization (Pause Video)
      if (next.isSpeaking && !(previous?.isSpeaking ?? false)) {
        ref.read(youtubeControllerProvider)?.pauseVideo();
      }
    });

    // 4. Listen for New Answers (Auto-Speak)
    ref.listen(qaNotifierProvider, (previous, next) {
      final prevLen = previous?.history.length ?? 0;
      if (next.history.length > prevLen) {
        final lastEntry = next.history.last;
        if (lastEntry.hasAnswer) {
          final voiceState = ref.read(voiceNotifierProvider);
          // Logic: Speak if continuous mode OR if input was voice
          if (voiceState.isContinuousModeEnabled) {
            ref
                .read(voiceNotifierProvider.notifier)
                .speakAnswerAndResume(lastEntry.answer!);
          } else if (next.lastInputMethod == InputMethod.voice) {
            ref.read(voiceNotifierProvider.notifier).speak(lastEntry.answer!);
          }
        }
      }

      // 5. Auto-Enable Continuous Mode Logic
      if (next.hasVideo &&
          !next.isLoadingVideo &&
          !_autoEnabledContinuousMode) {
        // Check if this is a fresh load (video changed or first load)
        // Assuming hasVideo becomes true.
        // We need to trigger this ONCE per video load.
        // checking equality of videoId might be safer but this flag works if reset properly.
        if (previous?.hasVideo == false || previous?.videoId != next.videoId) {
          // New video loaded
          _autoEnabledContinuousMode = true;
          // Use microtask to avoid building-phase side effects
          Future.microtask(() async {
            // Try to enable continuous mode (will fail if no headphones, handled by error listener)
            // Actually, we should check implicitly to avoid error dialog on auto-start?
            // The design says: "If connected: Auto-enable. If no headphones: Stay off (no dialog)."
            // So we need to check manually here to avoid the "Required" dialog.
            final audioService = ref.read(audioDeviceServiceProvider);
            if (await audioService.areHeadphonesConnected()) {
              toggleContinuousModeWithVideo(ref);
            }
          });
        }
      }

      // Reset flag if video cleared
      if (!next.hasVideo) {
        _autoEnabledContinuousMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _listenToStateChanges();

    final qaState = ref.watch(qaNotifierProvider);

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
        bottom: false,
        child: Column(
          children: [
            QAVideoSection(qaState: qaState),
            Expanded(
              child: qaState.hasVideo
                  ? const Center(child: ListeningToggleButton())
                  : EmptyState(
                      icon: Icons.video_library_outlined,
                      message: 'Add YouTube URL to Start the Learning Journey',
                    ),
            ),
            const BottomActionBar(),
          ],
        ),
      ),
    );
  }
}
