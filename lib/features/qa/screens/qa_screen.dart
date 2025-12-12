import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/qa_screen_coordinator.dart';
import '../widgets/headphone_required_dialog.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/listening_toggle_button.dart';
import '../widgets/qa_video_section.dart';
import '../../history/ui/widgets/history_bottom_sheet.dart';
import '../../history/providers/history_providers.dart';

/// Main Q&A screen with YouTube integration.
/// Thin UI layer - all coordination logic is in QAScreenCoordinator.
class QAScreen extends ConsumerStatefulWidget {
  const QAScreen({super.key});

  @override
  ConsumerState<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends ConsumerState<QAScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set up callback for coordinator to trigger continuous mode
    // Delayed to avoid "modifying provider during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setupContinuousModeCallback(ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref
        .read(qaScreenCoordinatorProvider.notifier)
        .handleAppLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    final qaState = ref.watch(qaNotifierProvider);
    final coordinatorState = ref.watch(qaScreenCoordinatorProvider);

    // React to coordinator state changes (UI-only reactions)
    _handleCoordinatorStateChanges(coordinatorState);
    _listenForHeadphoneError();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learnova'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Conversation History',
            onPressed: _showHistoryBottomSheet,
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

  void _handleCoordinatorStateChanges(QAScreenCoordinatorState state) {
    if (state.shouldShowResumeDialog) {
      // Clear flag first to prevent multiple dialogs
      ref.read(qaScreenCoordinatorProvider.notifier).clearResumeDialogFlag();
      // Show dialog after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showResumeDialog();
      });
    }
  }

  void _listenForHeadphoneError() {
    ref.listen(voiceNotifierProvider, (previous, next) {
      if (next.error == 'headphone_required' &&
          previous?.error != 'headphone_required') {
        showHeadphoneRequiredDialog(context);
        ref.read(voiceNotifierProvider.notifier).clearError();
      }
    });
  }

  void _showResumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume Continuous Mode?'),
        content: const Text(
          'Continuous listening was paused when you left the app. '
          'Would you like to resume?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(qaScreenCoordinatorProvider.notifier)
                  .resumeContinuousMode();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  void _showHistoryBottomSheet() {
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
}
