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

  // Continuous mode fields
  Function(String question)? _onQuestionCallback;
  Function(String answer)? _onAnswerCallback;
  Timer? _inactivityTimer;

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
        final isPermanentlyDenied = await _permissionService
            .isMicrophonePermissionPermanentlyDenied();
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
    try {
      if (state.isListening) {
        await _voiceService.cancelListening();
        await _recognitionSubscription?.cancel();
        _recognitionSubscription = null;
      }

      // Always clear recognized text when cancelling
      state = state.copyWith(
        isListening: false,
        recognizedText: '',
        recognitionState: SpeechRecognitionState.idle,
      );
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        recognizedText: '',
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

  /// Toggle continuous listening mode
  Future<void> toggleContinuousMode({
    required Function(String question) onQuestion,
    required Function(String answer) onAnswerReady,
  }) async {
    if (state.isContinuousModeEnabled) {
      // Disable continuous mode
      await stopContinuousMode();
    } else {
      // Enable continuous mode
      await startContinuousMode(
        onQuestion: onQuestion,
        onAnswerReady: onAnswerReady,
      );
    }
  }

  /// Start continuous listening mode
  Future<void> startContinuousMode({
    required Function(String question) onQuestion,
    required Function(String answer) onAnswerReady,
  }) async {
    if (!state.isInitialized) {
      state = state.copyWith(error: 'Voice service not initialized');
      return;
    }

    // Check permissions
    final hasPermission = await _permissionService.hasMicrophonePermission();
    if (!hasPermission) {
      final granted = await _permissionService.requestMicrophonePermission();
      if (!granted) {
        final isPermanentlyDenied = await _permissionService
            .isMicrophonePermissionPermanentlyDenied();
        if (isPermanentlyDenied) {
          state = state.copyWith(
            error:
                'Microphone permission denied. Please enable it in settings.',
          );
        } else {
          state = state.copyWith(error: 'Microphone permission denied');
        }
        return;
      }
    }

    _onQuestionCallback = onQuestion;
    _onAnswerCallback = onAnswerReady;

    state = state.copyWith(
      isContinuousModeEnabled: true,
      continuousListeningState: ContinuousListeningState.listening,
      error: null,
    );

    // Start inactivity timer (5 minutes)
    _startInactivityTimer();

    // Start continuous listening
    _voiceService.startContinuousListening(
      onQuestionDetected: _handleQuestionDetected,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 60),
    );
  }

  /// Stop continuous listening mode
  Future<void> stopContinuousMode() async {
    await _voiceService.stopContinuousListening();
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _onQuestionCallback = null;
    _onAnswerCallback = null;

    state = state.copyWith(
      isContinuousModeEnabled: false,
      continuousListeningState: ContinuousListeningState.idle,
    );
  }

  /// Handle question detected in continuous mode
  void _handleQuestionDetected(String recognizedText) {
    if (!state.isContinuousModeEnabled) return;

    _resetInactivityTimer();

    // Update state to processing
    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.processing,
      recognizedText: recognizedText,
    );

    // Notify the QA feature to process the question
    _onQuestionCallback?.call(recognizedText);
  }

  /// Speak answer in continuous mode and resume listening
  Future<void> speakAnswerAndResume(String answer) async {
    if (!state.isContinuousModeEnabled) return;

    _resetInactivityTimer();

    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.speaking,
    );

    // Speak the answer
    final stream = _voiceService.speak(answer);

    _synthesisSubscription = stream.listen(
      (synthesisState) {
        // Update synthesis state
        state = state.copyWith(synthesisState: synthesisState);
      },
      onError: (error) {
        // On TTS error, show answer as text and resume listening
        _onAnswerCallback?.call(answer);
        _resumeListening();
      },
      onDone: () {
        // When speaking completes, resume listening
        _resumeListening();
      },
    );
  }

  /// Resume listening after speaking
  void _resumeListening() {
    if (!state.isContinuousModeEnabled) return;

    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.listening,
      recognizedText: '',
    );

    // Restart listening cycle
    _voiceService.startContinuousListening(
      onQuestionDetected: _handleQuestionDetected,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 60),
    );
  }

  /// Start inactivity timer
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      // Auto-disable after 5 minutes of inactivity
      stopContinuousMode();
    });
  }

  /// Reset inactivity timer
  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _recognitionSubscription?.cancel();
    _synthesisSubscription?.cancel();
    _voiceService.dispose();
    super.dispose();
  }
}
