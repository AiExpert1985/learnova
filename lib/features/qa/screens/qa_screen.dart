import 'package:flutter/material.dart';
import '../services/qa_service.dart';
import '../../../core/constants/mock_data.dart';

/// Main Q&A screen for Step 1 MVP
/// Uses hardcoded transcript for testing
class QAScreen extends StatefulWidget {
  final QAService qaService;

  const QAScreen({
    super.key,
    required this.qaService,
  });

  @override
  State<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends State<QAScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_QAEntry> _qaHistory = [];
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
          _buildTranscriptHeader(),
          Expanded(child: _buildQAHistory()),
          _buildQuestionInput(),
        ],
      ),
    );
  }

  Widget _buildTranscriptHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MockData.videoTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Duration: ${MockData.videoDuration.inMinutes}:${(MockData.videoDuration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
      itemBuilder: (context, index) {
        final entry = _qaHistory[index];
        return _buildQAEntryWidget(entry);
      },
    );
  }

  Widget _buildQAEntryWidget(_QAEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuestionBubble(entry.question),
        const SizedBox(height: 8),
        _buildAnswerBubble(entry),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuestionBubble(String question) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(question),
      ),
    );
  }

  Widget _buildAnswerBubble(_QAEntry entry) {
    if (entry.error != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Flexible(child: Text(entry.error!)),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.answer!),
            const SizedBox(height: 4),
            Text(
              'Tokens: ${entry.tokensUsed}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                hintText: 'Ask a question...',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _handleAskQuestion(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _handleAskQuestion,
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Future<void> _handleAskQuestion() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    _questionController.clear();

    final result = await widget.qaService.askQuestion(
      transcript: MockData.sampleTranscript,
      questionText: questionText,
    );

    setState(() {
      _isLoading = false;
      _qaHistory.add(_QAEntry(
        question: questionText,
        answer: result.answer?.text,
        error: result.error,
        tokensUsed: result.answer?.tokensUsed ?? 0,
      ));
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

class _QAEntry {
  final String question;
  final String? answer;
  final String? error;
  final int tokensUsed;

  _QAEntry({
    required this.question,
    this.answer,
    this.error,
    required this.tokensUsed,
  });
}
