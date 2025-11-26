import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/qa/screens/qa_screen.dart';
import '../services/config_service.dart';

/// Route names
class Routes {
  static const String qa = '/';
  static const String apiKeyMissing = '/api-key-missing';
}

/// App router configuration
final appRouter = GoRouter(
  initialLocation: Routes.qa,
  routes: [
    GoRoute(
      path: Routes.qa,
      name: 'qa',
      builder: (context, state) => const QAScreen(),
    ),
    GoRoute(
      path: Routes.apiKeyMissing,
      name: 'apiKeyMissing',
      builder: (context, state) => const _ApiKeyMissingScreen(),
    ),
  ],
  redirect: (context, state) {
    // Redirect to API key missing screen if no key configured
    final apiKey = ConfigService.apiKey;
    final isApiKeyMissing = apiKey.isEmpty;
    final goingToApiKeyMissing = state.matchedLocation == Routes.apiKeyMissing;

    if (isApiKeyMissing && !goingToApiKeyMissing) {
      return Routes.apiKeyMissing;
    }

    if (!isApiKeyMissing && goingToApiKeyMissing) {
      return Routes.qa;
    }

    return null; // No redirect needed
  },
);

class _ApiKeyMissingScreen extends StatelessWidget {
  const _ApiKeyMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Required'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'OpenAI API Key Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To run this app, you need to provide an OpenAI API key.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Steps to fix:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Run with API key:\n\n'
                'flutter run --dart-define=OPENAI_API_KEY=your-key',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
