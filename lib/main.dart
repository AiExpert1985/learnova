import 'package:flutter/material.dart';
import 'core/services/config_service.dart';
import 'core/services/openai/openai_service_impl.dart';
import 'features/qa/services/qa_service.dart';
import 'features/qa/screens/qa_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService.load();
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
    // Get API key from config file
    final apiKey = ConfigService.get('OPENAI_API_KEY');

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
                '1. Create config.json in project root\n'
                '2. Add: {"OPENAI_API_KEY": "your-key-here"}\n'
                '3. Restart the app',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
