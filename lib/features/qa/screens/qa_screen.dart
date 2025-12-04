import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/empty_state.dart';
import '../widgets/transcript_header.dart';
import '../widgets/error_banner.dart';
import '../widgets/video_player.dart';
import '../widgets/continuous_listening_indicator.dart';
import '../widgets/headphone_required_dialog.dart';
import '../widgets/chat_bottom_sheet.dart';
import '../widgets/bottom_action_bar.dart';
import '../widgets/listening_toggle_button.dart';
import '../state/qa_state.dart';
import '../../history/ui/widgets/history_bottom_sheet.dart';
import '../../history/providers/history_providers.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/services/voice/voice_models.dart';

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

    // Set up callbacks immediately
    Future.microtask(() => _setupCallbacks());
  }

  /// Set up all voice and QA callbacks
  void _setupCallbacks() {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final qaNotifier = ref.read(qaNotifierProvider.notifier);

    // Headphone required callback
    voiceNotifier.setHeadphoneRequiredCallback(() {
      showHeadphoneRequiredDialog(context);
    });

    // Auto-speak callback for voice input answers
    qaNotifier.setAutoSpeakCallback((answer) {
      voiceNotifier.speak(answer);
    });

    // Continuous mode callback for speaking answers
    _setupContinuousModeCallback();
  }

  /// Set up continuous mode callback (called once during init)
  void _setupContinuousModeCallback() {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final qaNotifier = ref.read(qaNotifierProvider.notifier);
    final videoController = ref.read(youtubeControllerProvider);

    qaNotifier.setContinuousModeCallback((answer) async {
      // Speak answer and start grace period (video remains paused)
      await voiceNotifier.speakAnswerAndResume(answer);

      // Wait for grace period (5s) + buffer (2s) = 7s total
      await Future.delayed(const Duration(seconds: 7));

      if (videoController != null) {
        final voiceState = ref.read(voiceNotifierProvider);
        // Only resume if still in continuous mode and listening state
        if (voiceState.isContinuousModeEnabled &&
            voiceState.continuousListeningState ==
                ContinuousListeningState.listening) {
          await videoController.playVideo();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Auto-enable continuous mode when video becomes ready (only if headphones connected)
    final qaState = ref.watch(qaNotifierProvider);
    final voiceState = ref.watch(voiceNotifierProvider);

    if (qaState.isFullyInitialized &&
        !voiceState.isContinuousModeEnabled &&
        !_autoEnabledContinuousMode) {
      _autoEnabledContinuousMode = true;
      // Check headphones and enable continuous mode if connected
      Future.microtask(() => _autoEnableListeningMode());
    }

    // Reset flag when video is cleared
    if (!qaState.hasVideo) {
      _autoEnabledContinuousMode = false;
    }
  }

  /// Auto-enable listening mode based on headphone connection
  Future<void> _autoEnableListeningMode() async {
    final audioDeviceService = ref.read(audioDeviceServiceProvider);
    final areHeadphonesConnected = await audioDeviceService
        .areHeadphonesConnected();

    if (areHeadphonesConnected) {
      // Headphones connected - enable continuous mode automatically
      _handleContinuousModeToggle();
    }
    // If no headphones, listening mode stays off (user can manually enable later)
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final voiceState = ref.read(voiceNotifierProvider);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App going to background - pause continuous mode
        if (voiceState.isContinuousModeEnabled) {
          _wasInContinuousMode = true;
          voiceNotifier.stopContinuousMode();
        }
        break;
      case AppLifecycleState.resumed:
        // App returning to foreground - optionally resume
        if (_wasInContinuousMode && mounted) {
          _wasInContinuousMode = false;
          _showResumeDialog();
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleContinuousModeToggle();
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

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

  void _showSessionHistoryDrawer(BuildContext context) async {
    // Stop continuous listening mode if active
    final voiceState = ref.read(voiceNotifierProvider);
    if (voiceState.isContinuousModeEnabled) {
      await ref.read(voiceNotifierProvider.notifier).stopContinuousMode();
    }

    // Pause video when chat opens
    final videoController = ref.read(youtubeControllerProvider);
    bool wasPlaying = false;
    if (videoController != null) {
      final playerState = await videoController.playerState;
      wasPlaying = playerState == PlayerState.playing;
      if (wasPlaying) {
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

    // Video remains paused after chat closes (user can manually resume)
  }

  void _handleBottomBarAction(BottomBarState newState) {
    ref.read(qaNotifierProvider.notifier).setBottomBarState(newState);
  }

  void _handleContinuousModeToggle() async {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final qaNotifier = ref.read(qaNotifierProvider.notifier);
    final videoController = ref.read(youtubeControllerProvider);

    await voiceNotifier.toggleContinuousMode(
      onQuestion: (question) async {
        // Pause video when user speaks
        if (videoController != null) {
          final playerState = await videoController.playerState;
          if (playerState == PlayerState.playing) {
            await videoController.pauseVideo();
          }
        }

        // Process question through QA service
        qaNotifier.askQuestion(question, isContinuousMode: true);
      },
      onAnswerReady: (answer) {
        // This is called if TTS fails, to display answer as text
        // The answer is already in the QA history, so nothing to do here
      },
    );
  }

  Widget _buildVideoSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      ),
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
        bottom: false, // Bottom bar handles its own safe area
        child: Column(
          children: [
            // Video player with loading skeleton
            if (qaState.isLoadingVideo)
              _buildVideoSkeleton()
            else if (qaState.hasVideo)
              VideoPlayer(videoId: qaState.videoId!),
            if (qaState.hasVideo && !qaState.isLoadingVideo)
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
            // Empty space for clean UI - history accessed via bottom bar
            Expanded(
              child: qaState.hasVideo
                  ? Center(
                      child: ListeningToggleButton(
                        onToggle: _handleContinuousModeToggle,
                      ),
                    )
                  : EmptyState(
                      icon: Icons.video_library_outlined,
                      message: 'Add YouTube URL to Start the Learning Journey',
                    ),
            ),
            // Bottom action bar
            BottomActionBar(
              onUrlPressed: () =>
                  _handleBottomBarAction(BottomBarState.urlExpanded),
              onChatPressed: () => _showSessionHistoryDrawer(context),
            ),
          ],
        ),
      ),
    );
  }
}
