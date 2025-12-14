/// Silero VAD service implementation using vad package
library;

import 'dart:async';
import 'package:vad/vad.dart';
import 'vad_service.dart';
import '../../../utils/debug_logger.dart';

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
  bool _isInitializing = false;

  @override
  Stream<VADEvent> startMonitoring() {
    if (_isMonitoring) {
      return _eventController.stream;
    }

    if (_isInitializing) {
      DebugLogger.log('VAD already initializing, returning stream',
          level: DebugLogLevel.warning);
      return _eventController.stream;
    }

    _isInitializing = true;
    _initializeDetector();
    return _eventController.stream;
  }

  Future<void> _initializeDetector() async {
    try {
      DebugLogger.log('Initializing VAD handler...', level: DebugLogLevel.info);

      // Create VadHandler with debug mode for troubleshooting
      _handler = VadHandler.create(isDebug: true);

      DebugLogger.log('Setting up VAD event listeners...',
          level: DebugLogLevel.info);

      // Listen to speech start events
      _speechStartSubscription = _handler!.onSpeechStart.listen((_) {
        DebugLogger.log('VAD: Speech start event received',
            level: DebugLogLevel.success);
        _eventController.add(VADEvent(
          type: VADEventType.speechStart,
          timestamp: DateTime.now(),
        ));
      });

      // Listen to speech end events
      _speechEndSubscription = _handler!.onSpeechEnd.listen((samples) {
        DebugLogger.log('VAD: Speech end event received (${samples.length} samples)',
            level: DebugLogLevel.info);
        _eventController.add(VADEvent(
          type: VADEventType.speechEnd,
          timestamp: DateTime.now(),
        ));
      });

      // Listen to error events
      _errorSubscription = _handler!.onError.listen((error) {
        DebugLogger.log('VAD Error: $error', level: DebugLogLevel.error);
        _eventController.add(VADEvent(
          type: VADEventType.error,
          timestamp: DateTime.now(),
          errorMessage: error,
        ));
      });

      DebugLogger.log('Starting VAD listening (model: v5, frameSamples: 512)...',
          level: DebugLogLevel.info);

      // Start listening with VAD v5 model (frameSamples must be 512 for v5)
      await _handler!.startListening(
        model: 'v5',
        frameSamples: 512,
      );

      _isMonitoring = true;
      _isInitializing = false;

      DebugLogger.log('✓ VAD initialized and listening',
          level: DebugLogLevel.success);
    } catch (e) {
      _isInitializing = false;
      final errorMsg = 'Failed to start VAD: $e';
      DebugLogger.log(errorMsg, level: DebugLogLevel.error);

      _eventController.add(VADEvent(
        type: VADEventType.error,
        timestamp: DateTime.now(),
        errorMessage: errorMsg,
      ));
    }
  }

  @override
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    try {
      DebugLogger.log('Stopping VAD monitoring...', level: DebugLogLevel.info);

      await _handler?.stopListening();
      await _speechStartSubscription?.cancel();
      await _speechEndSubscription?.cancel();
      await _errorSubscription?.cancel();
      _speechStartSubscription = null;
      _speechEndSubscription = null;
      _errorSubscription = null;
      _isMonitoring = false;

      DebugLogger.log('VAD stopped', level: DebugLogLevel.success);
    } catch (e) {
      final errorMsg = 'Failed to stop VAD: $e';
      DebugLogger.log(errorMsg, level: DebugLogLevel.error);

      _eventController.add(VADEvent(
        type: VADEventType.error,
        timestamp: DateTime.now(),
        errorMessage: errorMsg,
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
