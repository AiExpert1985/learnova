import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:audio_session/audio_session.dart';
import 'core/routes/app_router.dart';
import 'core/utils/debug_logger.dart';
import 'features/history/providers/history_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  runApp(const ProviderScope(child: LearnovaApp()));
}

class LearnovaApp extends ConsumerStatefulWidget {
  const LearnovaApp({super.key});

  @override
  ConsumerState<LearnovaApp> createState() => _LearnovaAppState();
}

class _LearnovaAppState extends ConsumerState<LearnovaApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize audio session and other services after widget tree is ready
    Future.microtask(() async {
      // Configure audio session for simultaneous playback and recording
      try {
        final session = await AudioSession.instance;
        await session.configure(AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.allowBluetooth,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
        ));
        DebugLogger.log('[Audio] Session configured');
      } catch (e) {
        DebugLogger.log('[Audio] Config failed: $e');
      }

      // Initialize history storage
      ref.read(historyNotifierProvider.notifier).initialize();

      // Set up debug logger with scaffold messenger key
      DebugLogger.setScaffoldMessengerKey(_scaffoldMessengerKey);

      // Enable debug mode for testing (set to false in production)
      DebugLogger.setDebugMode(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Close Hive boxes on app dispose
    ref.read(historyNotifierProvider.notifier).clearError();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
    if (state == AppLifecycleState.paused) {
      // Optional: Perform cleanup when app goes to background
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Learnova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
      scaffoldMessengerKey: _scaffoldMessengerKey,
    );
  }
}
