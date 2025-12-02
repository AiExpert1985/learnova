import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/routes/app_router.dart';
import 'core/providers/app_providers.dart';
import 'features/history/providers/history_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Create provider container to initialize history service
  final container = ProviderContainer();

  // Initialize history storage
  await container.read(historyNotifierProvider.notifier).initialize();

  runApp(ProviderScope(parent: container, child: const LearnovaApp()));
}

class LearnovaApp extends StatelessWidget {
  const LearnovaApp({super.key});

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
