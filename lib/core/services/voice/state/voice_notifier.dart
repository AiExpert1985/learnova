/// Voice state notifier
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../voice_service.dart';
import '../voice_models.dart';
import '../permission_service.dart';
import 'voice_state.dart';

class VoiceNotifier extends StateNotifier<VoiceState> {
  final VoiceService _voiceService;
  final PermissionService _permissionService;
  StreamSubscription<SpeechRecognitionResult>? _recognitionSubscription;
  StreamSubscription<SpeechSynthesisState>? _synthesisSubscription;

  VoiceNotifier(this._voiceService, this._permissionService)
      : super(const VoiceState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _voiceService.initialize();
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize voice services: $e',
        isInitialized: false,
      );
    }
  }

  /// Start listening for voice input
  /// Returns the final recognized text or null if cancelled/error
  Future<String?> startListening() async {
    if (!state.isInitialized) {
      state = state.copyWith(error: 'Voice service not initialized');
      return null;
    }

    if (state.isListening) {
      return null;
    }

    // Check permissions
    final hasPermission = await _permissionService.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _permissionService.requestMicrophonePermission();
      if (!granted) {
        final isPermanentlyDenied =
            await _permissionService.isMicrophonePermissionPermanentlyDenied();
        if (isPermanentlyDenied) {
          state = state.copyWith(
            error:
                'Microphone permission denied. Please enable it in settings.',
          );
        } else {
          state = state.copyWith(error: 'Microphone permission denied');
        }
        return null;
      }
    }

    try {
      state = state.copyWith(
        isListening: true,
        recognizedText: '',
        error: null,
        recognitionState: SpeechRecognitionState.listening,
      );

      String? finalText;
      final stream = _voiceService.startListening();

      _recognitionSubscription = stream.listen(
        (result) {
          state = state.copyWith(recognizedText: result.recognizedText);
          if (result.isFinal) {
            finalText = result.recognizedText;
          }
        },
        onError: (error) {
          state = state.copyWith(
            isListening: false,
            error: error.toString(),
            recognitionState: SpeechRecognitionState.error,
          );
        },
        onDone: () {
          state = state.copyWith(
            isListening: false,
            recognitionState: SpeechRecognitionState.idle,
          );
        },
      );

      return finalText;
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
        recognitionState: SpeechRecognitionState.error,
      );
      return null;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!state.isListening) return;

    try {
      await _voiceService.stopListening();
      await _recognitionSubscription?.cancel();
      _recognitionSubscription = null;

      state = state.copyWith(
        isListening: false,
        recognitionState: SpeechRecognitionState.idle,
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
        recognitionState: SpeechRecognitionState.error,
      );
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (!state.isListening) return;

    try {
      await _voiceService.cancelListening();
      await _recognitionSubscription?.cancel();
      _recognitionSubscription = null;

      state = state.copyWith(
        isListening: false,
        recognizedText: '',
        recognitionState: SpeechRecognitionState.idle,
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: e.toString(),
        recognitionState: SpeechRecognitionState.error,
      );
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!state.isInitialized) {
      state = state.copyWith(error: 'Voice service not initialized');
      return;
    }

    if (text.trim().isEmpty) return;

    try {
      state = state.copyWith(
        isSpeaking: true,
        error: null,
        synthesisState: SpeechSynthesisState.speaking,
      );

      final stream = _voiceService.speak(text);

      _synthesisSubscription = stream.listen(
        (synthesisState) {
          state = state.copyWith(
            synthesisState: synthesisState,
            isSpeaking: synthesisState == SpeechSynthesisState.speaking,
          );
        },
        onError: (error) {
          state = state.copyWith(
            isSpeaking: false,
            error: error.toString(),
            synthesisState: SpeechSynthesisState.error,
          );
        },
        onDone: () {
          state = state.copyWith(
            isSpeaking: false,
            synthesisState: SpeechSynthesisState.idle,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isSpeaking: false,
        error: e.toString(),
        synthesisState: SpeechSynthesisState.error,
      );
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (!state.isSpeaking) return;

    try {
      await _voiceService.stopSpeaking();
      await _synthesisSubscription?.cancel();
      _synthesisSubscription = null;

      state = state.copyWith(
        isSpeaking: false,
        synthesisState: SpeechSynthesisState.idle,
      );
    } catch (e) {
      state = state.copyWith(
        isSpeaking: false,
        error: e.toString(),
        synthesisState: SpeechSynthesisState.error,
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.clearError();
  }

  @override
  void dispose() {
    _recognitionSubscription?.cancel();
    _synthesisSubscription?.cancel();
    _voiceService.dispose();
    super.dispose();
  }
}
