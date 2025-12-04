/// Flutter speech_to_text implementation of STTService
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
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
    if (_isInitialized) {
      debugPrint('[STT] Already initialized');
      return;
    }

    debugPrint('[STT] Initializing speech recognition...');
    try {
      final available = await _speech.initialize(
        onError: (error) {
          debugPrint('[STT] Error during recognition: ${error.errorMsg}');
          _handleError(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('[STT] Status changed: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _resultController?.close();
            _resultController = null;
          }
        },
      );

      if (!available) {
        debugPrint('[STT] Speech recognition not available on device');
        throw VoiceException(
          'Speech recognition not available on this device',
          VoiceErrorType.notAvailable,
        );
      }

      _isInitialized = true;
      debugPrint('[STT] ✅ Initialization successful');
    } catch (e) {
      debugPrint('[STT] ❌ Initialization failed: $e');
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
    Duration? pauseFor,
  }) {
    debugPrint('[STT] 🎤 Start listening requested (locale: $localeId, pauseFor: ${pauseFor?.inSeconds}s)');

    if (!_isInitialized) {
      debugPrint('[STT] ❌ Cannot start - not initialized');
      throw VoiceException(
        'STT service not initialized. Call initialize() first.',
        VoiceErrorType.initialization,
      );
    }

    if (_isListening) {
      debugPrint('[STT] ⚠️  Already listening');
      throw VoiceException('Already listening', VoiceErrorType.unknown);
    }

    _resultController = StreamController<SpeechRecognitionResult>();
    _isListening = true;
    debugPrint('[STT] ✅ Listening started');

    _speech.listen(
      onResult: (result) {
        debugPrint('[STT] 📝 Result: "${result.recognizedWords}" (confidence: ${result.confidence}, final: ${result.finalResult})');

        final recognitionResult = SpeechRecognitionResult(
          recognizedText: result.recognizedWords,
          confidence: result.confidence,
          isFinal: result.finalResult,
        );

        _resultController?.add(recognitionResult);

        // Close stream on final result
        if (result.finalResult) {
          debugPrint('[STT] ✅ Final result received, closing stream');
          _isListening = false;
          _resultController?.close();
        }
      },
      localeId: localeId,
      listenFor: listenDuration ?? const Duration(seconds: 60),
      pauseFor: pauseFor ?? const Duration(seconds: 3),
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
