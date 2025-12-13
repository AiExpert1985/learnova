/// Silero VAD implementation of voice activity detection
library;

import 'dart:async';
import 'package:vad/vad.dart';
import 'vad_service.dart';

/// Implementation of VADService using Silero VAD model
/// Provides lightweight, efficient voice activity detection
class SileroVADService implements VADService {
  VadHandler? _vadHandler;
  bool _isMonitoring = false;
  bool _isVoiceActive = false;
  bool _isInitialized = false;

  Function()? _onVoiceStart;
  Function()? _onVoiceEnd;

  // Debounce timer for voice end detection
  Timer? _voiceEndTimer;
  static const _voiceEndDebounce = Duration(milliseconds: 300);

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    _vadHandler = VadHandler.create(
      isDebug: false,
      // Model downloads automatically on first use
    );

    _isInitialized = true;
  }

  @override
  void startMonitoring({
    required Function() onVoiceStart,
    required Function() onVoiceEnd,
  }) {
    if (!_isInitialized || _isMonitoring) return;

    _onVoiceStart = onVoiceStart;
    _onVoiceEnd = onVoiceEnd;
    _isMonitoring = true;
    _isVoiceActive = false;

    _vadHandler?.onSpeechStart.listen((_) {
      if (!_isMonitoring) return;

      _voiceEndTimer?.cancel();

      if (!_isVoiceActive) {
        _isVoiceActive = true;
        _onVoiceStart?.call();
      }
    });

    _vadHandler?.onSpeechEnd.listen((_) {
      if (!_isMonitoring) return;

      // Debounce voice end to avoid false triggers
      _voiceEndTimer?.cancel();
      _voiceEndTimer = Timer(_voiceEndDebounce, () {
        if (_isVoiceActive && _isMonitoring) {
          _isVoiceActive = false;
          _onVoiceEnd?.call();
        }
      });
    });

    _vadHandler?.startListening();
  }

  @override
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _isVoiceActive = false;
    _voiceEndTimer?.cancel();
    _voiceEndTimer = null;
    _onVoiceStart = null;
    _onVoiceEnd = null;

    _vadHandler?.stopListening();
  }

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  bool get isVoiceActive => _isVoiceActive;

  @override
  Future<void> dispose() async {
    await stopMonitoring();
    _vadHandler = null;
    _isInitialized = false;
  }
}
