/// Abstract interface for Text-to-Speech (TTS) services
/// Provider-agnostic: supports flutter_tts, Google Cloud TTS, ElevenLabs, etc.
library;

import 'voice_models.dart';

abstract class TTSService {
  /// Initialize the text-to-speech service
  /// Must be called before using other methods
  /// Throws VoiceException if initialization fails
  Future<void> initialize();

  /// Speak the given text
  /// Returns a stream of synthesis states
  /// Throws VoiceException if not initialized
  Stream<SpeechSynthesisState> speak(String text);

  /// Stop speaking immediately
  Future<void> stop();

  /// Pause speaking
  Future<void> pause();

  /// Resume speaking after pause
  Future<void> resume();

  /// Check if currently speaking
  bool get isSpeaking;

  /// Set speech rate (0.0 to 1.0, default 0.5)
  Future<void> setSpeechRate(double rate);

  /// Set speech volume (0.0 to 1.0, default 1.0)
  Future<void> setVolume(double volume);

  /// Set speech pitch (0.5 to 2.0, default 1.0)
  Future<void> setPitch(double pitch);

  /// Set language/locale
  Future<void> setLanguage(String languageCode);

  /// Get available languages
  Future<List<String>> getLanguages();

  /// Get available voices for current language
  Future<List<String>> getVoices();

  /// Set voice
  Future<void> setVoice(String voice);

  /// Dispose resources
  Future<void> dispose();
}
