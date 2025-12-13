/// Audio session configuration service
/// Configures the audio session for simultaneous recording and playback
library;

import 'package:audio_session/audio_session.dart';

/// Service for configuring the audio session to allow playback and recording
/// to coexist without interrupting each other
abstract class AudioSessionService {
  /// Configure audio session for continuous listening mode
  /// Sets up playAndRecord mode so STT doesn't pause video playback
  Future<void> configureForContinuousListening();

  /// Configure audio session for normal playback only
  Future<void> configureForPlayback();

  /// Dispose resources
  Future<void> dispose();
}

/// Implementation of AudioSessionService using audio_session package
class AudioSessionServiceImpl implements AudioSessionService {
  AudioSession? _session;
  bool _isConfiguredForContinuousListening = false;

  Future<AudioSession> _getSession() async {
    _session ??= await AudioSession.instance;
    return _session!;
  }

  @override
  Future<void> configureForContinuousListening() async {
    if (_isConfiguredForContinuousListening) return;

    final session = await _getSession();

    // Note: Cannot use const here because AVAudioSessionCategoryOptions
    // uses bitwise OR which requires runtime evaluation
    await session.configure(
      AudioSessionConfiguration(
        // iOS: Allow playback and recording simultaneously
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth
            .union(AVAudioSessionCategoryOptions.defaultToSpeaker)
            .union(AVAudioSessionCategoryOptions.mixWithOthers),
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,

        // Android: Request audio focus that allows other audio to duck
        // This prevents the video from pausing when STT starts
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        // Key: Use gainTransientMayDuck instead of gain
        // This allows other audio to continue playing (possibly ducked)
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );

    _isConfiguredForContinuousListening = true;
  }

  @override
  Future<void> configureForPlayback() async {
    final session = await _getSession();

    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.moviePlayback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.movie,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ),
    );

    _isConfiguredForContinuousListening = false;
  }

  @override
  Future<void> dispose() async {
    // audio_session doesn't require explicit disposal
    _session = null;
    _isConfiguredForContinuousListening = false;
  }
}
