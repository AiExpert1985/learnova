import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/providers/app_providers.dart';
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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qaState = ref.watch(qaNotifierProvider);

    // Auto-scroll when history changes
    ref.listen(qaNotifierProvider, (previous, next) {
      if (previous?.history.length != next.history.length) {
        _scrollToBottom();
      }
    });

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
          Expanded(child: _buildQAHistory(qaState.history)),
          QuestionInput(isLoading: qaState.isLoading),
        ],
      ),
    );
  }

  Widget _buildQAHistory(List qaHistory) {
    if (qaHistory.isEmpty) {
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
      itemCount: qaHistory.length,
      itemBuilder: (context, index) => QABubble(entry: qaHistory[index]),
    );
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
