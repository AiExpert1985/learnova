/// Voice state notifier with VAD integration for continuous listening
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../voice_service.dart';
import '../voice_models.dart';
import '../permission_service.dart';
import '../vad_service.dart';
import '../../audio/audio_device_service.dart';
import '../../audio/audio_session_service.dart';
import 'voice_state.dart';

class VoiceNotifier extends StateNotifier<VoiceState> {
  final VoiceService _voiceService;
  final PermissionService _permissionService;
  final AudioDeviceService _audioDeviceService;
  final AudioSessionService _audioSessionService;
  final VADService _vadService;

  StreamSubscription<SpeechRecognitionResult>? _recognitionSubscription;
  StreamSubscription<SpeechSynthesisState>? _synthesisSubscription;
  StreamSubscription<bool>? _headphoneConnectionSubscription;

  // Continuous mode fields
  Function(String question)? _onQuestionCallback;
  Function(String answer)? _onAnswerCallback;
  Function()? _onSpeechStartCallback;
  Timer? _inactivityTimer;
  Timer? _gracePeriodTimer;

  // Video pause tracking for inactivity timeout
  bool _wasVideoPlayingBeforePause = false;
  Timer? _videoPausedTimeoutTimer;

  VoiceNotifier(
    this._voiceService,
    this._permissionService,
    this._audioDeviceService,
    this._audioSessionService,
    this._vadService,
  ) : super(const VoiceState()) {
    _initialize();
    _listenToHeadphoneChanges();
  }

  Future<void> _initialize() async {
    try {
      await _voiceService.initialize();
      await _vadService.initialize();
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize voice services: $e',
        isInitialized: false,
      );
    }
  }

  /// Listen for headphone connection/disconnection changes
  void _listenToHeadphoneChanges() {
    _headphoneConnectionSubscription = _audioDeviceService
        .headphoneConnectionStream
        .listen((isConnected) {
          if (!isConnected && state.isContinuousModeEnabled) {
            stopContinuousMode();
            state = state.copyWith(
              error: 'Headphones disconnected. Continuous mode stopped.',
            );
          }
        });
  }

  /// Start listening for voice input (one-off, non-continuous)
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
      final completer = Completer<String?>();
      final stream = _voiceService.startListening(
        pauseFor: const Duration(seconds: 3),
      );

      _recognitionSubscription = stream.listen(
        (result) {
          finalText = result.recognizedText;
          state = state.copyWith(recognizedText: result.recognizedText);
        },
        onError: (error) {
          state = state.copyWith(
            isListening: false,
            error: error.toString(),
            recognitionState: SpeechRecognitionState.error,
          );
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        onDone: () {
          state = state.copyWith(
            isListening: false,
            recognitionState: SpeechRecognitionState.idle,
          );
          if (!completer.isCompleted) {
            completer.complete(finalText);
          }
        },
      );

      return await completer.future;
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

  /// Speak text (one-off, non-continuous)
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
    Function()? onSpeechStart,
  }) async {
    if (state.isContinuousModeEnabled) {
      await stopContinuousMode();
    } else {
      await startContinuousMode(
        onQuestion: onQuestion,
        onAnswerReady: onAnswerReady,
        onSpeechStart: onSpeechStart,
      );
    }
  }

  /// Start continuous listening mode with VAD-based monitoring
  Future<void> startContinuousMode({
    required Function(String question) onQuestion,
    required Function(String answer) onAnswerReady,
    Function()? onSpeechStart,
  }) async {
    if (!state.isInitialized) {
      state = state.copyWith(error: 'Voice service not initialized');
      return;
    }

    // Check if headphones are connected
    final areHeadphonesConnected = await _audioDeviceService
        .areHeadphonesConnected();
    if (!areHeadphonesConnected) {
      state = state.copyWith(error: 'headphone_required');
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

    // Configure audio session for simultaneous playback and recording
    await _audioSessionService.configureForContinuousListening();

    _onQuestionCallback = onQuestion;
    _onAnswerCallback = onAnswerReady;
    _onSpeechStartCallback = onSpeechStart;

    state = state.copyWith(
      isContinuousModeEnabled: true,
      continuousListeningState: ContinuousListeningState.listening,
      error: null,
    );

    // Start inactivity timer (5 minutes)
    _startInactivityTimer();

    // Start continuous listening with speech onset callback
    _voiceService.startContinuousListening(
      onQuestionDetected: _handleQuestionDetected,
      onSpeechStart: _handleSpeechStart,
      pauseFor: const Duration(seconds: 5),
      listenFor: const Duration(seconds: 60),
    );
  }

  /// Stop continuous listening mode
  Future<void> stopContinuousMode() async {
    await _voiceService.stopContinuousListening();
    await _vadService.stopMonitoring();

    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = null;
    _videoPausedTimeoutTimer?.cancel();
    _videoPausedTimeoutTimer = null;

    _onQuestionCallback = null;
    _onAnswerCallback = null;
    _onSpeechStartCallback = null;

    // Reset audio session
    await _audioSessionService.configureForPlayback();

    state = state.copyWith(
      isContinuousModeEnabled: false,
      continuousListeningState: ContinuousListeningState.idle,
    );
  }

  /// Handle speech start detected (user started speaking)
  void _handleSpeechStart() {
    if (!state.isContinuousModeEnabled) return;

    // Transition to userSpeaking state
    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.userSpeaking,
    );

    // Notify coordinator to pause video
    _onSpeechStartCallback?.call();
  }

  /// Handle question detected in continuous mode
  void _handleQuestionDetected(String recognizedText) {
    if (!state.isContinuousModeEnabled) return;

    // Cancel grace period timer if question detected during grace period
    _gracePeriodTimer?.cancel();
    _videoPausedTimeoutTimer?.cancel();

    _resetInactivityTimer();

    // Transition to processing state
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
      isSpeaking: true,
    );

    final completer = Completer<void>();
    int retryCount = 0;
    const maxRetries = 1;

    Future<void> attemptSpeak() async {
      final stream = _voiceService.speak(answer);

      _synthesisSubscription = stream.listen(
        (synthesisState) {
          state = state.copyWith(synthesisState: synthesisState);
        },
        onError: (error) {
          if (retryCount < maxRetries) {
            retryCount++;
            // Retry after short delay
            Future.delayed(const Duration(milliseconds: 500), attemptSpeak);
          } else {
            // TTS failed after retry - show answer as text and continue
            _onAnswerCallback?.call(answer);
            state = state.copyWith(isSpeaking: false);
            _startGracePeriod();
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        },
        onDone: () {
          state = state.copyWith(isSpeaking: false);
          _startGracePeriod();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    }

    await attemptSpeak();
    await completer.future;
  }

  /// Start grace period after TTS completes
  void _startGracePeriod() {
    if (!state.isContinuousModeEnabled) return;

    // Enter grace period state
    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.waitingForNextQuestion,
      recognizedText: '',
    );

    // Start 5-second grace period timer
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer(const Duration(seconds: 5), () {
      _resumeListeningAfterGracePeriod();
    });
  }

  /// Resume listening after grace period (using restartListeningCycle)
  void _resumeListeningAfterGracePeriod() {
    if (!state.isContinuousModeEnabled) return;

    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.listening,
    );

    // Use restartListeningCycle instead of startContinuousListening
    // This avoids the flag bug where startContinuousListening returns early
    _voiceService.restartListeningCycle(
      onQuestionDetected: _handleQuestionDetected,
      onSpeechStart: _handleSpeechStart,
      pauseFor: const Duration(seconds: 5),
      listenFor: const Duration(seconds: 60),
    );
  }

  /// Called when video pauses - start 1-minute timeout
  void onVideoPaused() {
    if (!state.isContinuousModeEnabled) return;

    _wasVideoPlayingBeforePause = true;
    _videoPausedTimeoutTimer?.cancel();
    _videoPausedTimeoutTimer = Timer(const Duration(minutes: 1), () {
      // Auto-disable after 1 minute of video paused
      if (state.isContinuousModeEnabled) {
        stopContinuousMode();
        state = state.copyWith(
          error: 'Listening mode turned off due to inactivity',
        );
      }
    });
  }

  /// Called when video resumes - cancel the 1-minute timeout
  void onVideoResumed() {
    _wasVideoPlayingBeforePause = false;
    _videoPausedTimeoutTimer?.cancel();
    _videoPausedTimeoutTimer = null;
  }

  /// Start inactivity timer (5 minutes of no speech)
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      stopContinuousMode();
    });
  }

  /// Reset inactivity timer
  void _resetInactivityTimer() {
    _startInactivityTimer();
    // Also reset video paused timeout if video is playing
    if (!_wasVideoPlayingBeforePause) {
      _videoPausedTimeoutTimer?.cancel();
      _videoPausedTimeoutTimer = null;
    }
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _gracePeriodTimer?.cancel();
    _videoPausedTimeoutTimer?.cancel();
    _recognitionSubscription?.cancel();
    _synthesisSubscription?.cancel();
    _headphoneConnectionSubscription?.cancel();
    _voiceService.dispose();
    _vadService.dispose();
    _audioDeviceService.dispose();
    _audioSessionService.dispose();
    super.dispose();
  }
}
