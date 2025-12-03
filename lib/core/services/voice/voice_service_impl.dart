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

  VoiceServiceImpl({
    required STTService sttService,
    required TTSService ttsService,
  })  : _sttService = sttService,
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
  Future<void> dispose() async {
    await _sttService.dispose();
    await _ttsService.dispose();
  }
}
