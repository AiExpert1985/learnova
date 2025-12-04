/// Toggle switch for continuous listening mode
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class ContinuousModeToggle extends ConsumerWidget {
  final VoidCallback onToggle;

  const ContinuousModeToggle({super.key, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceNotifierProvider);
    final qaState = ref.watch(qaNotifierProvider);
    final isEnabled = voiceState.isContinuousModeEnabled;
    final isVideoReady = qaState.isFullyInitialized;

    return Opacity(
      opacity: isVideoReady ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: isEnabled
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isEnabled
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: isVideoReady ? onToggle : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isVideoReady)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      isEnabled ? Icons.mic : Icons.mic_off,
                      color: isEnabled
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    !isVideoReady
                        ? 'Loading...'
                        : isEnabled
                            ? 'Always Listening'
                            : 'Tap to Listen',
                    style: TextStyle(
                      color: isEnabled
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
