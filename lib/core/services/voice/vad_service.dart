/// Voice Activity Detection (VAD) service interface
library;

/// Service for detecting voice activity without requesting audio focus
/// Uses lightweight VAD model (Silero VAD) for continuous monitoring
abstract class VADService {
  /// Start voice activity detection monitoring
  /// Does NOT request Android audio focus - just monitors microphone
  /// Returns stream of VAD events (speech start, speech end, errors)
  Stream<VADEvent> startMonitoring();

  /// Stop voice activity detection monitoring
  Future<void> stopMonitoring();

  /// Check if VAD is currently monitoring
  bool get isMonitoring;

  /// Dispose of resources
  Future<void> dispose();
}

/// Voice Activity Detection event types
enum VADEventType {
  /// User started speaking (voice detected)
  speechStart,

  /// User stopped speaking (silence detected)
  speechEnd,

  /// Error occurred during VAD processing
  error,
}

/// Event emitted by VAD service
class VADEvent {
  final VADEventType type;
  final DateTime timestamp;
  final String? errorMessage;

  const VADEvent({
    required this.type,
    required this.timestamp,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'VADEvent(type: ${type.name}, timestamp: $timestamp${errorMessage != null ? ', error: $errorMessage' : ''})';
  }
}
