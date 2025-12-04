/// Voice input button for speech-to-text
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/providers/app_providers.dart';
import 'video_player.dart';

/// Voice input button that listens for voice and converts to text
/// Pauses video during listening, resumes after
class VoiceInputButton extends ConsumerStatefulWidget {
  final Function(String) onTextRecognized;

  const VoiceInputButton({super.key, required this.onTextRecognized});

  @override
  ConsumerState<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends ConsumerState<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _wasVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleVoiceInput() async {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final voiceState = ref.read(voiceNotifierProvider);
    final videoController = ref.read(youtubeControllerProvider);

    if (voiceState.isListening) {
      // Stop listening
      await voiceNotifier.stopListening();

      // Resume video if it was playing before
      if (_wasVideoPlaying && videoController != null) {
        await videoController.playVideo();
      }

      // Send recognized text if available
      final recognizedText = ref.read(voiceNotifierProvider).recognizedText;
      if (recognizedText.isNotEmpty) {
        widget.onTextRecognized(recognizedText);
      }
    } else {
      // Pause video before listening
      if (videoController != null) {
        try {
          final playerState = await videoController.playerState;
          _wasVideoPlaying = playerState == PlayerState.playing;
          if (_wasVideoPlaying) {
            await videoController.pauseVideo();
          }
        } catch (_) {
          // Ignore errors
        }
      }

      // Start listening and get the final text
      final recognizedText = await voiceNotifier.startListening();

      // Resume video if it was playing before
      if (_wasVideoPlaying && videoController != null) {
        await videoController.playVideo();
      }

      // Send recognized text if available
      if (recognizedText != null && recognizedText.isNotEmpty) {
        widget.onTextRecognized(recognizedText);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceNotifierProvider);
    final qaState = ref.watch(qaNotifierProvider);
    final isVideoReady = qaState.isFullyInitialized;

    // Control animation based on listening state
    if (voiceState.isListening && !_animationController.isAnimating) {
      _animationController.repeat();
    } else if (!voiceState.isListening && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.reset();
    }

    // Show error as snackbar
    if (voiceState.error != null && voiceState.error!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(voiceState.error!),
              action: voiceState.error!.contains('settings')
                  ? SnackBarAction(
                      label: 'Settings',
                      onPressed: () {
                        // Open app settings
                        ref.read(permissionServiceProvider).openAppSettings();
                      },
                    )
                  : null,
            ),
          );
          ref.read(voiceNotifierProvider.notifier).clearError();
        }
      });
    }

    final isEnabled = voiceState.isInitialized && isVideoReady;

    return IconButton(
      onPressed: isEnabled ? _handleVoiceInput : null,
      icon: voiceState.isListening
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_animationController.value * 0.2),
                  child: const Icon(Icons.mic),
                );
              },
            )
          : isVideoReady
              ? const Icon(Icons.mic_none)
              : const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
      color: voiceState.isListening ? Colors.red : Colors.blue,
      iconSize: 28,
      tooltip: !isVideoReady
          ? 'Loading video...'
          : voiceState.isListening
              ? 'Stop listening'
              : 'Start voice input',
    );
  }
}
