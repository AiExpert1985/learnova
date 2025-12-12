import 'package:flutter/material.dart';

/// Dialog shown when trying to enable continuous mode without headphones
/// Dialog shown when trying to enable continuous mode without headphones
class HeadphoneRequiredDialog extends StatefulWidget {
  const HeadphoneRequiredDialog({super.key});

  @override
  State<HeadphoneRequiredDialog> createState() =>
      _HeadphoneRequiredDialogState();
}

class _HeadphoneRequiredDialogState extends State<HeadphoneRequiredDialog> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.headphones, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Connect headset',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_showExplanation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Headphones separate your voice from the video sound, helping the AI understand you clearly.',
                style: TextStyle(fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _showExplanation = !_showExplanation;
            });
          },
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_showExplanation ? 'Hide why' : 'Why'),
              const SizedBox(width: 4),
              Icon(
                _showExplanation ? Icons.keyboard_arrow_up : Icons.help_outline,
                size: 16,
              ),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Show headphone required dialog
void showHeadphoneRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const HeadphoneRequiredDialog(),
  );
}
