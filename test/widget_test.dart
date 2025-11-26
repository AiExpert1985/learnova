// Basic Flutter widget test for Learnova

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnova/main.dart';
import 'package:learnova/core/services/config_service.dart';

void main() {
  testWidgets('App launches and shows API key missing screen',
      (WidgetTester tester) async {
    // Initialize config service (empty config for test)
    await ConfigService.load();

    // Build app wrapped in ProviderScope
    await tester.pumpWidget(const ProviderScope(child: LearnovaApp()));

    // Wait for initial route
    await tester.pumpAndSettle();

    // Verify API key missing screen is shown (since no key in test)
    expect(find.text('OpenAI API Key Required'), findsOneWidget);
    expect(find.text('Configuration Required'), findsOneWidget);
  });
}
