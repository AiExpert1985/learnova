import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import 'qa_bubble.dart';

class QAHistoryList extends ConsumerStatefulWidget {
  const QAHistoryList({super.key});

  @override
  ConsumerState<QAHistoryList> createState() => _QAHistoryListState();
}

class _QAHistoryListState extends ConsumerState<QAHistoryList> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(qaNotifierProvider.select((s) => s.history));

    // Listen for history changes to scroll to bottom
    ref.listen(qaNotifierProvider.select((s) => s.history), (previous, next) {
      if (next.length > (previous?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    if (history.isEmpty) {
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
      itemCount: history.length,
      itemBuilder: (context, index) => QABubble(entry: history[index]),
    );
  }
}
