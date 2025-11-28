import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../widgets/transcript_header.dart';
import '../widgets/qa_bubble.dart';
import '../widgets/question_input.dart';

/// Main Q&A screen with YouTube integration
class QAScreen extends ConsumerStatefulWidget {
  const QAScreen({super.key});

  @override
  ConsumerState<QAScreen> createState() => _QAScreenState();
}

class _QAScreenState extends ConsumerState<QAScreen> {
  final _scrollController = ScrollController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _urlController.dispose();
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
        title: const Text('Learnova'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildUrlInput(qaState),
          if (qaState.hasVideo)
            TranscriptHeader(
              title: qaState.videoTitle!,
              duration: qaState.videoDuration!,
            ),
          if (qaState.videoError != null) _buildErrorMessage(qaState.videoError!),
          Expanded(child: _buildContent(qaState)),
          if (qaState.hasVideo) QuestionInput(isLoading: qaState.isLoading),
        ],
      ),
    );
  }

  Widget _buildUrlInput(qaState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'Paste YouTube URL...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              enabled: !qaState.isLoadingVideo,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: qaState.isLoadingVideo ? null : _handleLoadVideo,
            icon: qaState.isLoadingVideo
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            color: Colors.green,
            iconSize: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(qaState) {
    if (!qaState.hasVideo && !qaState.isLoadingVideo) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Paste a YouTube URL and press play to start',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildQAHistory(qaState.history);
  }

  Widget _buildQAHistory(List qaHistory) {
    if (qaHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Ask a question about the video!',
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

  void _handleLoadVideo() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    ref.read(qaNotifierProvider.notifier).loadVideo(url);
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
