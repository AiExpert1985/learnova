import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/routes/app_router.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize history storage after widget tree is ready
    Future.microtask(() {
      ref.read(historyNotifierProvider.notifier).initialize();
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
    );
  }
}
