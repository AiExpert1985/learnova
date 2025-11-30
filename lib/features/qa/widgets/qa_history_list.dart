import 'package:flutter/material.dart';
import '../models/qa_history_entry.dart';
import 'qa_bubble.dart';

class QAHistoryList extends StatefulWidget {
  final List<QAHistoryEntry> history;

  const QAHistoryList({super.key, required this.history});

  @override
  State<QAHistoryList> createState() => _QAHistoryListState();
}

class _QAHistoryListState extends State<QAHistoryList> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QAHistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.history.length > oldWidget.history.length) {
      _scrollToBottom();
    }
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
    if (widget.history.isEmpty) {
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
      itemCount: widget.history.length,
      itemBuilder: (context, index) => QABubble(entry: widget.history[index]),
    );
  }
}
