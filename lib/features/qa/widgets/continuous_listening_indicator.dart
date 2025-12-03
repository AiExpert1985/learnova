/// Visual indicator for continuous listening state
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/voice/voice_models.dart';

class ContinuousListeningIndicator extends ConsumerWidget {
  const ContinuousListeningIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceNotifierProvider);

    if (!voiceState.isContinuousModeEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context, voiceState.continuousListeningState),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(voiceState.continuousListeningState),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getTitle(voiceState.continuousListeningState),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (voiceState.recognizedText.isNotEmpty &&
                  voiceState.continuousListeningState ==
                      ContinuousListeningState.processing)
                const SizedBox(height: 4),
              if (voiceState.recognizedText.isNotEmpty &&
                  voiceState.continuousListeningState ==
                      ContinuousListeningState.processing)
                Text(
                  voiceState.recognizedText,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(
      BuildContext context, ContinuousListeningState state) {
    switch (state) {
      case ContinuousListeningState.listening:
        return Colors.blue.shade600;
      case ContinuousListeningState.processing:
        return Colors.amber.shade700;
      case ContinuousListeningState.speaking:
        return Colors.green.shade600;
      case ContinuousListeningState.idle:
        return Colors.grey.shade600;
    }
  }

  Widget _buildIcon(ContinuousListeningState state) {
    switch (state) {
      case ContinuousListeningState.listening:
        return const _PulsingMicIcon();
      case ContinuousListeningState.processing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case ContinuousListeningState.speaking:
        return const _SpeakingWaveIcon();
      case ContinuousListeningState.idle:
        return const Icon(
          Icons.mic_off,
          color: Colors.white,
          size: 20,
        );
    }
  }

  String _getTitle(ContinuousListeningState state) {
    switch (state) {
      case ContinuousListeningState.listening:
        return 'Listening...';
      case ContinuousListeningState.processing:
        return 'Processing...';
      case ContinuousListeningState.speaking:
        return 'Speaking...';
      case ContinuousListeningState.idle:
        return 'Idle';
    }
  }
}

/// Pulsing microphone icon for listening state
class _PulsingMicIcon extends StatefulWidget {
  const _PulsingMicIcon();

  @override
  State<_PulsingMicIcon> createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<_PulsingMicIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 20,
          ),
        );
      },
    );
  }
}

/// Speaking wave animation icon
class _SpeakingWaveIcon extends StatefulWidget {
  const _SpeakingWaveIcon();

  @override
  State<_SpeakingWaveIcon> createState() => _SpeakingWaveIconState();
}

class _SpeakingWaveIconState extends State<_SpeakingWaveIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final height = 4 + (12 * (0.5 + 0.5 * (1 - (value - 0.5).abs() * 2)));

            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
