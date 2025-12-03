/// Flutter speech_to_text implementation of STTService
library;

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'stt_service.dart';
import 'voice_models.dart';

class FlutterSTTService implements STTService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  StreamController<SpeechRecognitionResult>? _resultController;
  bool _isInitialized = false;
  bool _isListening = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final available = await _speech.initialize(
        onError: (error) {
          _handleError(error.errorMsg);
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _resultController?.close();
            _resultController = null;
          }
        },
      );

      if (!available) {
        throw VoiceException(
          'Speech recognition not available on this device',
          VoiceErrorType.notAvailable,
        );
      }

      _isInitialized = true;
    } catch (e) {
      throw VoiceException(
        'Failed to initialize speech recognition: $e',
        VoiceErrorType.initialization,
      );
    }
  }

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
  }) {
    if (!_isInitialized) {
      throw VoiceException(
        'STT service not initialized. Call initialize() first.',
        VoiceErrorType.initialization,
      );
    }

    if (_isListening) {
      throw VoiceException('Already listening', VoiceErrorType.unknown);
    }

    _resultController = StreamController<SpeechRecognitionResult>();
    _isListening = true;

    _speech.listen(
      onResult: (result) {
        final recognitionResult = SpeechRecognitionResult(
          recognizedText: result.recognizedWords,
          confidence: result.confidence,
          isFinal: result.finalResult,
        );

        _resultController?.add(recognitionResult);

        // Close stream on final result
        if (result.finalResult) {
          _isListening = false;
          _resultController?.close();
        }
      },
      localeId: localeId,
      listenFor: listenDuration ?? const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );

    return _resultController!.stream;
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speech.stop();
    _isListening = false;
    _resultController?.close();
    _resultController = null;
  }

  @override
  Future<void> cancelListening() async {
    if (!_isListening) return;

    await _speech.cancel();
    _isListening = false;
    _resultController?.close();
    _resultController = null;
  }

  @override
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.isAvailable;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<List<String>> getSupportedLocales() async {
    if (!_isInitialized) {
      await initialize();
    }

    final locales = await _speech.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  @override
  Future<void> dispose() async {
    await cancelListening();
    // speech_to_text doesn't have explicit dispose
  }

  void _handleError(String errorMsg) {
    VoiceErrorType errorType = VoiceErrorType.unknown;

    if (errorMsg.contains('permission')) {
      errorType = VoiceErrorType.permissionDenied;
    } else if (errorMsg.contains('network')) {
      errorType = VoiceErrorType.networkError;
    } else if (errorMsg.contains('timeout')) {
      errorType = VoiceErrorType.timeout;
    }

    final exception = VoiceException(errorMsg, errorType);
    _resultController?.addError(exception);
    _resultController?.close();
    _isListening = false;
  }
}
