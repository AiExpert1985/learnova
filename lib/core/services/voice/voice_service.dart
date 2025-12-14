/// Voice service coordinator that combines STT and TTS
/// Handles conflicts between listening and speaking
library;

import 'voice_models.dart';

abstract class VoiceService {
  /// Initialize voice services (STT + TTS)
  Future<void> initialize();

  /// Start listening for voice input
  /// Automatically stops speaking if active
  /// Returns stream of recognition results
  /// [pauseFor] Duration of silence to wait before finalizing (defaults to 3 seconds)
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  });

  /// Stop listening
  Future<void> stopListening();

  /// Cancel listening
  Future<void> cancelListening();

  /// Speak text
  /// Automatically stops listening if active
  /// Returns stream of synthesis states
  Stream<SpeechSynthesisState> speak(String text);

  /// Stop speaking
  Future<void> stopSpeaking();

  /// Pause speaking
  Future<void> pauseSpeaking();

  /// Resume speaking
  Future<void> resumeSpeaking();

  /// Check if listening
  bool get isListening;

  /// Check if speaking
  bool get isSpeaking;

  /// Check if voice recognition is available
  Future<bool> isSpeechRecognitionAvailable();

  /// Configure TTS settings
  Future<void> configureTTS({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  });

  /// Start continuous listening mode
  /// Callback is invoked when a question is detected (after silence)
  /// Returns a stream controller that can be used to stop continuous mode
  void startContinuousListening({
    required Function(String recognizedText) onQuestionDetected,
    Function()? onSpeechStart,
    Duration? pauseFor,
    Duration? listenFor,
  });

  /// Restart an existing listening cycle without resetting the continuous flag
  void restartListeningCycle({
    required Function(String recognizedText) onQuestionDetected,
    Function()? onSpeechStart,
    Duration? pauseFor,
    Duration? listenFor,
  });

  /// Stop continuous listening mode
  Future<void> stopContinuousListening();

  /// Check if continuous listening is active
  bool get isContinuousListening;

  /// Dispose resources
  Future<void> dispose();
}
