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
  VadHandler? _handler;
  StreamSubscription<void>? _speechStartSubscription;
  StreamSubscription<List<double>>? _speechEndSubscription;
  StreamSubscription<String>? _errorSubscription;
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
      // Create VadHandler with debug mode enabled for testing
      _handler = VadHandler.create(isDebug: false);

      // Listen to speech start events
      _speechStartSubscription = _handler!.onSpeechStart.listen((_) {
        _eventController.add(VADEvent(
          type: VADEventType.speechStart,
          timestamp: DateTime.now(),
        ));
      });

      // Listen to speech end events
      _speechEndSubscription = _handler!.onSpeechEnd.listen((samples) {
        _eventController.add(VADEvent(
          type: VADEventType.speechEnd,
          timestamp: DateTime.now(),
        ));
      });

      // Listen to error events
      _errorSubscription = _handler!.onError.listen((error) {
        _eventController.add(VADEvent(
          type: VADEventType.error,
          timestamp: DateTime.now(),
          errorMessage: error,
        ));
      });

      // Start listening with VAD v5 model (frameSamples must be 512 for v5)
      await _handler!.startListening(
        model: 'v5',
        frameSamples: 512,
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
      await _handler?.stopListening();
      await _speechStartSubscription?.cancel();
      await _speechEndSubscription?.cancel();
      await _errorSubscription?.cancel();
      _speechStartSubscription = null;
      _speechEndSubscription = null;
      _errorSubscription = null;
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
    await _handler?.dispose();
    await _eventController.close();
  }
}
