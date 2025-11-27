import 'package:flutter/material.dart';

/// Header displaying video/transcript information
class TranscriptHeader extends StatelessWidget {
  final String title;
  final Duration duration;

  const TranscriptHeader({
    super.key,
    required this.title,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Duration: ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
