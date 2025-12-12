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

/// Main Q&A screen with YouTube integration
class QAScreen extends ConsumerStatefulWidget {
  const QAScreen({super.key});

  @override
  ConsumerState<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends ConsumerState<QAScreen>
    with WidgetsBindingObserver {
  late final QAScreenCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = QAScreenCoordinator(ref);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _coordinator.handleAppLifecycleChange(state);

    if (state == AppLifecycleState.resumed) {
      if (_coordinator.shouldShowResumeDialog() && mounted) {
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
              _coordinator.resumeContinuousMode();
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

  void _listenForHeadphoneError() {
    ref.listen(voiceNotifierProvider, (previous, next) {
      if (next.error == 'headphone_required' &&
          previous?.error != 'headphone_required') {
        showHeadphoneRequiredDialog(context);
        ref.read(voiceNotifierProvider.notifier).clearError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set up coordination listeners
    _coordinator.setupListeners();
    _listenForHeadphoneError();

    final qaState = ref.watch(qaNotifierProvider);

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
}
