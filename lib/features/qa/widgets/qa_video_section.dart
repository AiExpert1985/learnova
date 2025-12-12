import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../widgets/video_player.dart';
import '../widgets/transcript_header.dart';
import '../widgets/error_banner.dart';

import '../../qa/state/qa_state.dart';

class QAVideoSection extends ConsumerWidget {
  final QAState qaState;

  const QAVideoSection({super.key, required this.qaState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Video player with loading skeleton
        if (qaState.isLoadingVideo)
          _buildVideoSkeleton()
        else if (qaState.hasVideo)
          VideoPlayer(videoId: qaState.videoId!),

        if (qaState.hasVideo && !qaState.isLoadingVideo)
          TranscriptHeader(
            title: qaState.videoTitle!,
            duration: qaState.videoDuration!,
          ),

        if (qaState.videoError != null && qaState.videoError!.isNotEmpty)
          ErrorBanner(error: qaState.videoError!),
      ],
    );
  }

  Widget _buildVideoSkeleton() {
    return Skeletonizer(
      enabled: true,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
