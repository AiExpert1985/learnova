/// Bottom sheet to display conversation history
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/history_providers.dart';
import '../../../../core/providers/app_providers.dart';

class HistoryBottomSheet extends ConsumerWidget {
  const HistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyNotifierProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conversation History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (historyState.isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (historyState.hasError)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${historyState.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(historyNotifierProvider.notifier).loadHistory();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (!historyState.hasConversations)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No history yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your conversations will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: historyState.conversations.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final conversation = historyState.conversations[index];
                  return _HistoryListTile(
                    videoTitle: conversation.videoTitle,
                    lastUpdated: conversation.lastUpdated,
                    qaCount: conversation.qaHistory.length,
                    onTap: () {
                      Navigator.pop(context);
                      ref
                          .read(qaNotifierProvider.notifier)
                          .loadConversationFromHistory(conversation.id);
                    },
                    onDelete: () {
                      ref
                          .read(historyNotifierProvider.notifier)
                          .deleteConversation(conversation.id);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryListTile extends StatelessWidget {
  final String videoTitle;
  final DateTime lastUpdated;
  final int qaCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryListTile({
    required this.videoTitle,
    required this.lastUpdated,
    required this.qaCount,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat.jm().format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat.jm().format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.video_library),
      ),
      title: Text(
        videoTitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${_formatDate(lastUpdated)} • $qaCount Q&A${qaCount != 1 ? 's' : ''}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Conversation'),
              content:
                  const Text('Are you sure you want to delete this conversation?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      onTap: onTap,
    );
  }
}
