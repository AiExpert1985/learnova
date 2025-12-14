/// Audio session configuration service
library;

import 'package:audio_session/audio_session.dart';
import '../../utils/debug_logger.dart';

/// Service for configuring audio session to allow simultaneous playback and recording
class AudioSessionService {
  bool _isInitialized = false;

  /// Initialize audio session for simultaneous playback and recording
  /// This allows VAD/STT to run while video continues playing
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      DebugLogger.log('Configuring audio session...', level: DebugLogLevel.info);

      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        // Allow both playback and recording simultaneously
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,

        // Allow Bluetooth devices
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.allowBluetooth,

        // Configure for voice communication on Android
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),

        // Request transient focus with ducking
        // This allows video to continue (potentially ducked) when STT activates
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ));

      _isInitialized = true;
      DebugLogger.log('Audio session configured', level: DebugLogLevel.success);
    } catch (e) {
      DebugLogger.log('Audio session config failed: $e',
          level: DebugLogLevel.error);
    }
  }

  bool get isInitialized => _isInitialized;
}
