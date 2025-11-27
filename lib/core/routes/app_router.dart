import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/qa/screens/qa_screen.dart';
import '../screens/api_key_missing_screen.dart';
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
      builder: (context, state) => const ApiKeyMissingScreen(),
    ),
  ],
  redirect: (context, state) {
    // Redirect to API key missing screen if no key configured
    final isApiKeyMissing = !ConfigService.hasApiKey;
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
