import 'package:audio_session/audio_session.dart';

/// Configures the platform audio session for simultaneous playback and recording.
class AudioSessionService {
  /// Configure the session to allow play-and-record behavior while ducking
  /// other audio sources instead of stealing focus entirely.
  Future<void> configureForVoice() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );
  }
}
