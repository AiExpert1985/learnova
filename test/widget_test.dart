// Basic Flutter widget test for Learnova

import 'package:flutter_test/flutter_test.dart';

import 'package:learnova/main.dart';

void main() {
  testWidgets('App launches and shows API key missing screen',
      (WidgetTester tester) async {
    // Build app without API key
    await tester.pumpWidget(const LearnovaApp());

    // Verify API key missing screen is shown
    expect(find.text('OpenAI API Key Required'), findsOneWidget);
    expect(find.text('Configuration Required'), findsOneWidget);
  });
}
