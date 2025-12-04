import 'package:flutter/material.dart';

/// Dialog shown when trying to enable continuous mode without headphones
class HeadphoneRequiredDialog extends StatelessWidget {
  const HeadphoneRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.headphones, color: Colors.orange, size: 28),
          SizedBox(width: 12),
          Text('Headphones Required'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Please connect headphones to use hands-free mode.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 12),
          Text(
            'Why headphones?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Headphones prevent the microphone from picking up video audio, '
            'ensuring accurate voice recognition of your questions.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
      actions: [
        TextButton(
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
