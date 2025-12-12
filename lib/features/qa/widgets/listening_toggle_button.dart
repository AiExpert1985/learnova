import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

import '../utils/qa_actions.dart';

/// Large listening toggle button (ear icon)
/// Primary interaction for hands-free learning
/// Listening is ON by default when video loads
class ListeningToggleButton extends ConsumerWidget {
  const ListeningToggleButton({super.key});

  Future<void> _handleToggle(WidgetRef ref) async {
    await toggleContinuousModeWithVideo(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceNotifierProvider);
    final qaState = ref.watch(qaNotifierProvider);

    final isEnabled = voiceState.isInitialized && qaState.isFullyInitialized;
    final isListening = voiceState.isContinuousModeEnabled;

    // Define styles based on state
    final Color color = isEnabled
        ? (isListening ? Colors.green.shade600 : Colors.red.shade600)
        : Colors.grey.shade400;

    final IconData icon = isListening ? Icons.hearing : Icons.hearing_disabled;
    final String label = isListening ? '(listening on)' : '(listening is off)';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large circular button
        Material(
          elevation: 4,
          shape: const CircleBorder(),
          color: color,
          child: InkWell(
            onTap: isEnabled ? () => _handleToggle(ref) : null,
            customBorder: const CircleBorder(),
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Status label
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
