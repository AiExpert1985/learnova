import 'package:flutter/material.dart';
import 'core/services/openai/openai_service_impl.dart';
import 'features/qa/services/qa_service.dart';
import 'features/qa/screens/qa_screen.dart';

void main() {
  runApp(const LearnovaApp());
}

class LearnovaApp extends StatelessWidget {
  const LearnovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learnova',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    // Get API key from environment
    const apiKey = String.fromEnvironment('OPENAI_API_KEY');

    if (apiKey.isEmpty) {
      return const _ApiKeyMissingScreen();
    }

    // Manual dependency injection
    final openAIService = OpenAIServiceImpl(apiKey: apiKey);
    final qaService = QAService(openAIService: openAIService);

    return QAScreen(qaService: qaService);
  }
}

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
              'Run the app with:',
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
                'flutter run --dart-define=OPENAI_API_KEY=your_key_here',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
