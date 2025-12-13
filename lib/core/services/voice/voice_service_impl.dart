/// Implementation of VoiceService that coordinates STT and TTS
library;

import 'dart:async';
import 'voice_service.dart';
import 'stt_service.dart';
import 'tts_service.dart';
import 'voice_models.dart';

class VoiceServiceImpl implements VoiceService {
  final STTService _sttService;
  final TTSService _ttsService;
  bool _isInitialized = false;
  bool _isContinuousListening = false;
  StreamSubscription<SpeechRecognitionResult>? _continuousListeningSubscription;

  VoiceServiceImpl({
    required STTService sttService,
    required TTSService ttsService,
  }) : _sttService = sttService,
       _ttsService = ttsService;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _sttService.initialize();
    await _ttsService.initialize();
    _isInitialized = true;
  }

  @override
  Stream<SpeechRecognitionResult> startListening({
    String? localeId,
    Duration? listenDuration,
    Duration? pauseFor,
  }) {
    if (!_isInitialized) {
      throw VoiceException(
        'Voice service not initialized. Call initialize() first.',
        VoiceErrorType.initialization,
      );
    }

    // Stop speaking before listening
    if (_ttsService.isSpeaking) {
      _ttsService.stop();
    }

    return _sttService.startListening(
      localeId: localeId,
      listenDuration: listenDuration,
      pauseFor: pauseFor,
    );
  }

  @override
  Future<void> stopListening() async {
    await _sttService.stopListening();
  }

  @override
  Future<void> cancelListening() async {
    await _sttService.cancelListening();
  }

  @override
  Stream<SpeechSynthesisState> speak(String text) {
    if (!_isInitialized) {
      throw VoiceException(
        'Voice service not initialized. Call initialize() first.',
        VoiceErrorType.initialization,
      );
    }

    // Stop listening before speaking
    if (_sttService.isListening) {
      _sttService.stopListening();
    }

    return _ttsService.speak(text);
  }

  @override
  Future<void> stopSpeaking() async {
    await _ttsService.stop();
  }

  @override
  Future<void> pauseSpeaking() async {
    await _ttsService.pause();
  }

  @override
  Future<void> resumeSpeaking() async {
    await _ttsService.resume();
  }

  @override
  bool get isListening => _sttService.isListening;

  @override
  bool get isSpeaking => _ttsService.isSpeaking;

  @override
  Future<bool> isSpeechRecognitionAvailable() async {
    return await _sttService.isAvailable();
  }

  @override
  Future<void> configureTTS({
    double? speechRate,
    double? volume,
    double? pitch,
    String? language,
  }) async {
    if (speechRate != null) {
      await _ttsService.setSpeechRate(speechRate);
    }
    if (volume != null) {
      await _ttsService.setVolume(volume);
    }
    if (pitch != null) {
      await _ttsService.setPitch(pitch);
    }
    if (language != null) {
      await _ttsService.setLanguage(language);
    }
  }

  @override
  void startContinuousListening({
    required Function(String recognizedText) onQuestionDetected,
    Function(String partialText)? onSpeechStart,
    Function()? onSilenceTimeout,
    Duration? pauseFor,
    Duration? listenFor,
  }) {
    if (!_isInitialized) {
      throw VoiceException(
        'Voice service not initialized. Call initialize() first.',
        VoiceErrorType.initialization,
      );
    }

    if (_isContinuousListening && _continuousListeningSubscription != null) {
      _continuousListeningSubscription!.cancel();
    }

    _isContinuousListening = true;

    _startListeningCycle(
      onQuestionDetected: onQuestionDetected,
      onSpeechStart: onSpeechStart,
      onSilenceTimeout: onSilenceTimeout,
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      listenFor: listenFor ?? const Duration(seconds: 60),
    );
  }

  @override
  void restartListeningCycle({
    required Function(String recognizedText) onQuestionDetected,
    Function(String partialText)? onSpeechStart,
    Function()? onSilenceTimeout,
    Duration? pauseFor,
    Duration? listenFor,
  }) {
    // Only restart if the mode is still enabled
    if (!_isContinuousListening) return;

    _startListeningCycle(
      onQuestionDetected: onQuestionDetected,
      onSpeechStart: onSpeechStart,
      onSilenceTimeout: onSilenceTimeout,
      pauseFor: pauseFor ?? const Duration(seconds: 3),
      listenFor: listenFor ?? const Duration(seconds: 60),
    );
  }

  void _startListeningCycle({
    required Function(String recognizedText) onQuestionDetected,
    Function(String partialText)? onSpeechStart,
    Function()? onSilenceTimeout,
    required Duration pauseFor,
    required Duration listenFor,
  }) {
    // Stop speaking before listening
    if (_ttsService.isSpeaking) {
      _ttsService.stop();
    }

    final stream = _sttService.startListening(
      listenDuration: listenFor,
      pauseFor: pauseFor,
    );

    String? finalRecognizedText;
    bool speechOnsetNotified = false;

    _continuousListeningSubscription = stream.listen(
      (result) {
        // Speech Onset Detection
        if (result.recognizedText.trim().isNotEmpty) {
          if (!speechOnsetNotified) {
            speechOnsetNotified = true;
            onSpeechStart?.call(result.recognizedText);
          }
          finalRecognizedText = result.recognizedText;
        }
      },
      onError: (error) {
        // Pass error handling to Notifier via onDone/Timeout or let it bubble?
        // For now, we just close this cycle.
        // Notifier will likely see a timeout or use its own error handling if we exposed it.
        // But here we just stop.
        _continuousListeningSubscription?.cancel();
      },
      onDone: () {
        if (!_isContinuousListening) return;

        if (finalRecognizedText != null) {
          onQuestionDetected(finalRecognizedText!);
        } else {
          // Notify silence - let Notifier decide when to restart
          onSilenceTimeout?.call();
        }
      },
    );
  }

  @override
  Future<void> stopContinuousListening() async {
    _isContinuousListening = false;
    await _continuousListeningSubscription?.cancel();
    _continuousListeningSubscription = null;

    if (_sttService.isListening) {
      await _sttService.stopListening();
    }
  }

  @override
  bool get isContinuousListening => _isContinuousListening;

  @override
  Future<void> dispose() async {
    await stopContinuousListening();
    await _sttService.dispose();
    await _ttsService.dispose();
  }
}
