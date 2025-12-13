/// Voice Activity Detection service interface
/// Provides lightweight voice detection without requesting audio focus
library;

/// Callback for voice activity events
typedef VoiceActivityCallback = void Function(bool isVoiceActive);

/// Service for detecting voice activity without heavy STT processing
/// Uses VAD (Voice Activity Detection) for efficient, continuous monitoring
abstract class VADService {
  /// Initialize the VAD service
  Future<void> initialize();

  /// Start monitoring for voice activity
  /// [onVoiceStart] is called when voice is detected
  /// [onVoiceEnd] is called when voice stops (after silence threshold)
  void startMonitoring({
    required Function() onVoiceStart,
    required Function() onVoiceEnd,
  });

  /// Stop monitoring for voice activity
  Future<void> stopMonitoring();

  /// Check if currently monitoring
  bool get isMonitoring;

  /// Check if voice is currently detected
  bool get isVoiceActive;

  /// Dispose resources
  Future<void> dispose();
}
