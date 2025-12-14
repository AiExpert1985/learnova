/// Silero VAD service implementation using vad package
library;

import 'dart:async';
import 'package:vad/vad.dart';
import 'vad_service.dart';

/// Implementation of VAD service using Silero VAD model
/// Lightweight voice activity detection that does NOT request audio focus
class SileroVADService implements VADService {
  final StreamController<VADEvent> _eventController =
      StreamController<VADEvent>.broadcast();
  VoiceActivityDetector? _detector;
  bool _isMonitoring = false;

  @override
  Stream<VADEvent> startMonitoring() {
    if (_isMonitoring) {
      return _eventController.stream;
    }

    _initializeDetector();
    return _eventController.stream;
  }

  Future<void> _initializeDetector() async {
    try {
      _detector = VoiceActivityDetector();

      await _detector!.start(
        // Use Silero VAD v5 model (512 sample frames = 32ms per frame)
        frameSamples: 512,
        sampleRate: 16000,

        // Callbacks for VAD events
        onSpeechStart: () {
          _eventController.add(VADEvent(
            type: VADEventType.speechStart,
            timestamp: DateTime.now(),
          ));
        },

        onSpeechEnd: () {
          _eventController.add(VADEvent(
            type: VADEventType.speechEnd,
            timestamp: DateTime.now(),
          ));
        },

        onError: (error) {
          _eventController.add(VADEvent(
            type: VADEventType.error,
            timestamp: DateTime.now(),
            errorMessage: error.toString(),
          ));
        },
      );

      _isMonitoring = true;
    } catch (e) {
      _eventController.add(VADEvent(
        type: VADEventType.error,
        timestamp: DateTime.now(),
        errorMessage: 'Failed to start VAD: $e',
      ));
    }
  }

  @override
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      await _detector?.stop();
      _isMonitoring = false;
    } catch (e) {
      _eventController.add(VADEvent(
        type: VADEventType.error,
        timestamp: DateTime.now(),
        errorMessage: 'Failed to stop VAD: $e',
      ));
    }
  }

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  Future<void> dispose() async {
    await stopMonitoring();
    await _eventController.close();
  }
}
