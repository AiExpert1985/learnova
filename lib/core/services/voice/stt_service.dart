/// Abstract interface for Speech-to-Text (STT) services
/// Provider-agnostic: supports speech_to_text, Google Cloud STT, etc.
library;

import 'voice_models.dart';

abstract class STTService {
  /// Initialize the speech recognition service
  /// Must be called before using other methods
  /// Throws VoiceException if initialization fails
  Future<void> initialize();

  /// Start listening for speech input
  /// Returns a stream of recognition results
  /// Throws VoiceException if not initialized or permission denied
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
  });

  /// Stop listening and finalize the current recognition
  Future<void> stopListening();

  /// Cancel listening without finalizing
  Future<void> cancelListening();

  /// Check if speech recognition is available on this device
  Future<bool> isAvailable();

  /// Check if currently listening
  bool get isListening;

  /// Get supported locales
  Future<List<String>> getSupportedLocales();

  /// Dispose resources
  Future<void> dispose();
}
