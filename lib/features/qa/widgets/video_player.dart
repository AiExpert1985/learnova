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

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        showFullscreenButton: true,
        loop: false,
      ),
    );

    _controller.loadVideoById(videoId: widget.videoId);

    // Listen to playback position changes and update QA state
    _controller.listen((event) {
      ref.read(qaNotifierProvider.notifier).updatePosition(event.position);
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
