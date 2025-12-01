import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/providers/app_providers.dart';

/// YouTube video player widget
/// Plays video and tracks playback position for context-aware Q&A
class VideoPlayer extends ConsumerStatefulWidget {
  final String videoId;

  const VideoPlayer({
    super.key,
    required this.videoId,
  });

  @override
  ConsumerState<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends ConsumerState<VideoPlayer> {
  late YoutubePlayerController _controller;
  Timer? _positionTimer;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
        // Required for YouTube's origin policy (fixes Error 15/153)
        // See: https://stackoverflow.com/questions/79804589
        origin: 'https://www.youtube-nocookie.com',
      ),
    );

    _controller.loadVideoById(videoId: widget.videoId);

    // Poll playback position every second and update QA state
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final positionSeconds = await _controller.currentTime;
        final position = Duration(seconds: positionSeconds.round());
        ref.read(qaNotifierProvider.notifier).updatePosition(position);
      } catch (_) {
        // Ignore errors during position updates
      }
    });
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload video if videoId changes
    if (oldWidget.videoId != widget.videoId) {
      _controller.loadVideoById(videoId: widget.videoId);
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
    );
  }
}
