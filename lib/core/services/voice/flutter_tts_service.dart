/// Flutter flutter_tts implementation of TTSService
library;

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_service.dart';
import 'voice_models.dart';

class FlutterTTSService implements TTSService {
  final FlutterTts _tts = FlutterTts();
  StreamController<SpeechSynthesisState>? _stateController;
  bool _isInitialized = false;
  bool _isSpeaking = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set default values
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Set up handlers
      _tts.setStartHandler(() {
        _isSpeaking = true;
        _stateController?.add(SpeechSynthesisState.speaking);
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        _stateController?.add(SpeechSynthesisState.idle);
        _stateController?.close();
        _stateController = null;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        _stateController?.addError(
          VoiceException(
            'TTS error: $msg',
            VoiceErrorType.unknown,
          ),
        );
        _stateController?.add(SpeechSynthesisState.error);
        _stateController?.close();
        _stateController = null;
      });

      _tts.setPauseHandler(() {
        _stateController?.add(SpeechSynthesisState.paused);
      });

      _tts.setContinueHandler(() {
        _stateController?.add(SpeechSynthesisState.speaking);
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        _stateController?.add(SpeechSynthesisState.idle);
        _stateController?.close();
        _stateController = null;
      });

      _isInitialized = true;
    } catch (e) {
      throw VoiceException(
        'Failed to initialize TTS: $e',
        VoiceErrorType.initialization,
      );
    }
  }

  @override
  Stream<SpeechSynthesisState> speak(String text) {
    if (!_isInitialized) {
      throw VoiceException(
        'TTS service not initialized. Call initialize() first.',
        VoiceErrorType.initialization,
      );
    }

    if (text.trim().isEmpty) {
      throw VoiceException(
        'Cannot speak empty text',
        VoiceErrorType.unknown,
      );
    }

    // Stop any ongoing speech
    if (_isSpeaking) {
      _tts.stop();
    }

    _stateController = StreamController<SpeechSynthesisState>();

    // Start speaking
    _tts.speak(text);

    return _stateController!.stream;
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    _stateController?.close();
    _stateController = null;
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
  }

  @override
  Future<void> resume() async {
    // flutter_tts doesn't have explicit resume, use speak continuation
    // This is a limitation of the package
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> setSpeechRate(double rate) async {
    if (rate < 0.0 || rate > 1.0) {
      throw VoiceException(
        'Speech rate must be between 0.0 and 1.0',
        VoiceErrorType.unknown,
      );
    }
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw VoiceException(
        'Volume must be between 0.0 and 1.0',
        VoiceErrorType.unknown,
      );
    }
    await _tts.setVolume(volume);
  }

  @override
  Future<void> setPitch(double pitch) async {
    if (pitch < 0.5 || pitch > 2.0) {
      throw VoiceException(
        'Pitch must be between 0.5 and 2.0',
        VoiceErrorType.unknown,
      );
    }
    await _tts.setPitch(pitch);
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }

  @override
  Future<List<String>> getLanguages() async {
    final languages = await _tts.getLanguages;
    if (languages is List) {
      return languages.map((lang) => lang.toString()).toList();
    }
    return [];
  }

  @override
  Future<List<String>> getVoices() async {
    final voices = await _tts.getVoices;
    if (voices is List) {
      return voices.map((voice) => voice.toString()).toList();
    }
    return [];
  }

  @override
  Future<void> setVoice(String voice) async {
    await _tts.setVoice({"name": voice, "locale": "en-US"});
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
