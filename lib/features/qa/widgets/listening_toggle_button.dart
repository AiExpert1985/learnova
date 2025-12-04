import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/voice/voice_models.dart';

/// Large listening toggle button (ear icon)
/// Primary interaction for hands-free learning
/// Listening is ON by default when video loads
class ListeningToggleButton extends ConsumerWidget {
  final VoidCallback onToggle;

  const ListeningToggleButton({
    super.key,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceNotifierProvider);
    final qaState = ref.watch(qaNotifierProvider);

    final isEnabled = voiceState.isInitialized && qaState.isFullyInitialized;
    final isListening = voiceState.isContinuousModeEnabled;
    final currentState = voiceState.continuousListeningState;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large ear button
        Material(
          elevation: 4,
          shape: const CircleBorder(),
          color: Colors.teal.shade600,
          child: InkWell(
            onTap: isEnabled ? onToggle : null,
            customBorder: const CircleBorder(),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? Colors.teal.shade600 : Colors.grey.shade400,
              ),
              child: Icon(
                isListening ? Icons.hearing : Icons.hearing_disabled,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Status text
        Text(
          isListening ? 'Listening' : 'Off',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isEnabled ? Colors.teal.shade700 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        // Minimal state indicator
        if (isListening) _buildStateIndicator(currentState),
      ],
    );
  }

  Widget _buildStateIndicator(ContinuousListeningState state) {
    String text;
    switch (state) {
      case ContinuousListeningState.listening:
        text = 'Ready...';
        break;
      case ContinuousListeningState.processing:
        text = 'Processing...';
        break;
      case ContinuousListeningState.speaking:
        text = 'Speaking...';
        break;
      case ContinuousListeningState.waitingForNextQuestion:
        text = 'Waiting for next question...';
        break;
      case ContinuousListeningState.idle:
        text = 'Idle';
        break;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
