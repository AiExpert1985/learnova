/// Voice state notifier
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vad/vad.dart';
import '../voice_service.dart';
import '../voice_models.dart';
import '../permission_service.dart';
import '../../audio/audio_device_service.dart';
import '../../../utils/debug_logger.dart';
import 'voice_state.dart';

class VoiceNotifier extends StateNotifier<VoiceState> {
  final VoiceService _voiceService;
  final PermissionService _permissionService;
  final AudioDeviceService _audioDeviceService;

  // VAD handler for voice activity detection
  VadHandler? _vadHandler;

  StreamSubscription<SpeechRecognitionResult>? _recognitionSubscription;
  StreamSubscription<SpeechSynthesisState>? _synthesisSubscription;
  StreamSubscription<bool>? _headphoneConnectionSubscription;
  StreamSubscription<void>? _vadSpeechStartSubscription;
  StreamSubscription<String>? _vadErrorSubscription;

  // Continuous mode fields
  Function(String question)? _onQuestionCallback;
  Function(String answer)? _onAnswerCallback;
  Timer? _inactivityTimer;
  Timer? _gracePeriodTimer;
  Duration? _currentPauseFor;
  Duration? _currentListenFor;

  // Headphone requirement callback
  VoiceNotifier(
    this._voiceService,
    this._permissionService,
    this._audioDeviceService,
  ) : super(const VoiceState()) {
    _initialize();
    _listenToHeadphoneChanges();
  }

  Future<void> _initialize() async {
    try {
      await _voiceService.initialize();
      state = state.copyWith(isInitialized: true);
      DebugLogger.log('Voice service initialized', level: DebugLogLevel.success);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize voice services: $e',
        isInitialized: false,
      );
      DebugLogger.log('Voice init failed: $e', level: DebugLogLevel.error);
    }
  }

  /// Listen for headphone connection/disconnection changes
  void _listenToHeadphoneChanges() {
    _headphoneConnectionSubscription = _audioDeviceService
        .headphoneConnectionStream
        .listen((isConnected) {
          if (!isConnected && state.isContinuousModeEnabled) {
            // Headphones disconnected during continuous mode - stop it
            DebugLogger.log('Headphones disconnected - stopping continuous mode',
                level: DebugLogLevel.warning);
            stopContinuousMode();
            state = state.copyWith(
              error: 'Headphones disconnected. Continuous mode stopped.',
            );
          }
        });
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
      final completer = Completer<String?>();
      final stream = _voiceService.startListening(
        pauseFor: const Duration(seconds: 3),
      );

      _recognitionSubscription = stream.listen(
        (result) {
          // Always update with latest recognized text
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

    DebugLogger.log('Starting continuous mode...', level: DebugLogLevel.info);

    // Check if headphones are connected
    final areHeadphonesConnected = await _audioDeviceService
        .areHeadphonesConnected();
    if (!areHeadphonesConnected) {
      DebugLogger.log('Headphones required', level: DebugLogLevel.warning);
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
        DebugLogger.log('Mic permission denied', level: DebugLogLevel.error);
        return;
      }
    }

    _onQuestionCallback = onQuestion;
    _onAnswerCallback = onAnswerReady;
    _currentPauseFor = const Duration(seconds: 5);
    _currentListenFor = const Duration(seconds: 60);

    state = state.copyWith(
      isContinuousModeEnabled: true,
      continuousListeningState: ContinuousListeningState.listening,
      error: null,
    );

    // Start inactivity timer (5 minutes)
    _startInactivityTimer();

    // Initialize and start VAD for voice detection
    await _startVAD();
  }

  /// Initialize and start Voice Activity Detection
  Future<void> _startVAD() async {
    try {
      DebugLogger.log('[VAD] Initializing...');

      _vadHandler = VadHandler.create();

      // Listen for speech detection
      _vadSpeechStartSubscription = _vadHandler!.onSpeechStart.listen((_) {
        if (!state.isContinuousModeEnabled) return;
        DebugLogger.log('[VAD] 🎤 Speech detected');
        _onSpeechStart();
      });

      // Listen for errors
      _vadErrorSubscription = _vadHandler!.onError.listen((error) {
        DebugLogger.log('[VAD] ❌ Error: $error');
      });

      // Start VAD listening
      await _vadHandler!.startListening(model: 'v5', frameSamples: 512);

      DebugLogger.log('[VAD] ✓ Monitoring started');
    } catch (e) {
      DebugLogger.log('[VAD] ❌ Failed to start: $e');
    }
  }

  /// Handle speech start (VAD detected voice)
  void _onSpeechStart() {
    if (!state.isContinuousModeEnabled) return;

    _resetInactivityTimer();

    // Update state to userSpeaking (video will pause via coordinator)
    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.userSpeaking,
    );

    DebugLogger.log('▶️ STT started capturing words',
        level: DebugLogLevel.info);

    // Now start STT to capture actual words
    String? finalRecognizedText;
    final stream = _voiceService.startListening(
      pauseFor: _currentPauseFor,
      listenDuration: _currentListenFor,
    );

    _recognitionSubscription = stream.listen(
      (result) {
        if (result.recognizedText.trim().isNotEmpty) {
          finalRecognizedText = result.recognizedText;
          state = state.copyWith(recognizedText: result.recognizedText);
        }
      },
      onError: (error) {
        DebugLogger.log('STT error: $error', level: DebugLogLevel.error);
        // On error, return to listening state and restart VAD
        state = state.copyWith(
          continuousListeningState: ContinuousListeningState.listening,
        );
        // VAD is still running, will detect next speech
      },
      onDone: () {
        if (!state.isContinuousModeEnabled) return;

        if (finalRecognizedText != null) {
          DebugLogger.log('✓ Question: "$finalRecognizedText"',
              level: DebugLogLevel.success);
          _handleQuestionDetected(finalRecognizedText!);
        } else {
          DebugLogger.log('No speech detected - back to listening',
              level: DebugLogLevel.info);
          // No text detected, return to listening
          state = state.copyWith(
            continuousListeningState: ContinuousListeningState.listening,
          );
          // VAD is still running, will detect next speech
        }
      },
    );
  }

  /// Stop continuous listening mode
  Future<void> stopContinuousMode() async {
    DebugLogger.log('[Mode] Stopping continuous listening');

    // Stop VAD
    await _vadSpeechStartSubscription?.cancel();
    await _vadErrorSubscription?.cancel();
    _vadSpeechStartSubscription = null;
    _vadErrorSubscription = null;
    _vadHandler = null;

    await _voiceService.stopContinuousListening();
    await _recognitionSubscription?.cancel();
    _recognitionSubscription = null;

    _inactivityTimer?.cancel();
    _gracePeriodTimer?.cancel();
    _inactivityTimer = null;
    _gracePeriodTimer = null;
    _onQuestionCallback = null;
    _onAnswerCallback = null;

    state = state.copyWith(
      isContinuousModeEnabled: false,
      continuousListeningState: ContinuousListeningState.idle,
    );

    DebugLogger.log('Continuous mode stopped', level: DebugLogLevel.success);
  }

  /// Handle question detected in continuous mode
  void _handleQuestionDetected(String recognizedText) {
    if (!state.isContinuousModeEnabled) return;

    // Cancel grace period timer if question detected during grace period
    _gracePeriodTimer?.cancel();

    _resetInactivityTimer();

    // Update state to processing
    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.processing,
      recognizedText: recognizedText,
    );

    DebugLogger.log('📤 Sending question to API', level: DebugLogLevel.info);

    // Notify the QA feature to process the question
    _onQuestionCallback?.call(recognizedText);
  }

  /// Speak answer in continuous mode and resume listening
  /// Returns a Future that completes when TTS finishes and grace period starts
  Future<void> speakAnswerAndResume(String answer) async {
    if (!state.isContinuousModeEnabled) return;

    _resetInactivityTimer();

    DebugLogger.log('📥 API response received', level: DebugLogLevel.success);

    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.speaking,
    );

    DebugLogger.log('🔊 TTS speaking answer', level: DebugLogLevel.info);

    // Create completer to make this properly awaitable
    final completer = Completer<void>();

    // Speak the answer
    final stream = _voiceService.speak(answer);

    _synthesisSubscription = stream.listen(
      (synthesisState) {
        // Update synthesis state
        state = state.copyWith(synthesisState: synthesisState);
      },
      onError: (error) {
        DebugLogger.log('TTS error: $error', level: DebugLogLevel.error);
        // On TTS error, show answer as text and resume listening
        _onAnswerCallback?.call(answer);
        _resumeListening();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onDone: () {
        DebugLogger.log('✓ TTS finished', level: DebugLogLevel.success);
        // When speaking completes, resume listening
        _resumeListening();
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    // Wait for TTS to complete before returning
    await completer.future;
  }

  /// Resume listening after speaking (with grace period)
  void _resumeListening() {
    if (!state.isContinuousModeEnabled) return;

    // Enter grace period state
    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.waitingForNextQuestion,
      recognizedText: '',
    );

    DebugLogger.log('⏳ Grace period (5s) - waiting for follow-up',
        level: DebugLogLevel.info);

    // Start 5-second grace period timer
    _gracePeriodTimer?.cancel();
    _gracePeriodTimer = Timer(const Duration(seconds: 5), () {
      // Grace period elapsed, resume listening
      if (!state.isContinuousModeEnabled) return;

      DebugLogger.log('▶️ Resuming video + VAD monitoring',
          level: DebugLogLevel.success);

      state = state.copyWith(
        continuousListeningState: ContinuousListeningState.listening,
      );

      // VAD is still monitoring, no need to restart it
      // It will detect the next speech automatically
    });
  }

  /// Start inactivity timer
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      // Auto-disable after 5 minutes of inactivity
      DebugLogger.log('Inactivity timeout - stopping continuous mode',
          level: DebugLogLevel.warning);
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
    _gracePeriodTimer?.cancel();
    _recognitionSubscription?.cancel();
    _synthesisSubscription?.cancel();
    _headphoneConnectionSubscription?.cancel();
    _vadSpeechStartSubscription?.cancel();
    _vadErrorSubscription?.cancel();
    _voiceService.dispose();
    _audioDeviceService.dispose();
    super.dispose();
  }
}
