/// Voice service models and exceptions
library;

/// Represents the result of speech-to-text recognition
class SpeechRecognitionResult {
  final String recognizedText;
  final double confidence;
  final bool isFinal;

  SpeechRecognitionResult({
    required this.recognizedText,
    required this.confidence,
    required this.isFinal,
  });
}

/// Represents the state of speech recognition
enum SpeechRecognitionState {
  idle,
  listening,
  processing,
  error,
}

/// Represents the state of text-to-speech
enum SpeechSynthesisState {
  idle,
  speaking,
  paused,
  error,
}

/// Exception thrown by voice services
class VoiceException implements Exception {
  final String message;
  final VoiceErrorType type;

  VoiceException(this.message, this.type);

  @override
  String toString() => 'VoiceException: $message (${type.name})';
}

/// Types of voice-related errors
enum VoiceErrorType {
  permissionDenied,
  notAvailable,
  networkError,
  timeout,
  initialization,
  unknown,
}
