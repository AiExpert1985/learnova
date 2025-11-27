import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/providers/app_providers.dart';
import '../models/qa_history_entry.dart';
import '../widgets/transcript_header.dart';
import '../widgets/qa_bubble.dart';
import '../widgets/question_input.dart';

/// Main Q&A screen for Step 1 MVP
/// Uses hardcoded transcript for testing
class QAScreen extends ConsumerStatefulWidget {
  const QAScreen({super.key});

  @override
  ConsumerState<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends ConsumerState<QAScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController(); // auto scrolling

  final List<QAHistoryEntry> _qaHistory = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learnova - Q&A Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          TranscriptHeader(
            title: MockData.videoTitle,
            duration: MockData.videoDuration,
          ),
          Expanded(child: _buildQAHistory()),
          QuestionInput(
            controller: _questionController,
            isLoading: _isLoading,
            onSubmit: _handleAskQuestion,
          ),
        ],
      ),
    );
  }

  Widget _buildQAHistory() {
    if (_qaHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Ask a question about the video above!',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _qaHistory.length,
      itemBuilder: (context, index) => QABubble(entry: _qaHistory[index]),
    );
  }

  Future<void> _handleAskQuestion() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    _questionController.clear();

    final qaService = ref.read(qaServiceProvider);
    final result = await qaService.askQuestion(
      transcript: MockData.sampleTranscript,
      questionText: questionText,
    );

    setState(() {
      _isLoading = false;
      _qaHistory.add(
        QAHistoryEntry(
          question: questionText,
          answer: result.answer?.text,
          error: result.error,
          tokensUsed: result.answer?.tokensUsed ?? 0,
        ),
      );
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
