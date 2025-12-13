/// Stub VAD implementation for voice activity detection
///
/// Note: This is a placeholder implementation. The actual Silero VAD integration
/// requires a native plugin that wraps the Silero VAD ONNX model.
///
/// For now, this stub implementation:
/// - Satisfies the VADService interface
/// - Does NOT actually detect voice activity
/// - The continuous listening feature works without VAD using audio_session
///   configuration to prevent audio focus conflicts
///
/// Future improvement: Integrate a proper VAD package such as:
/// - flutter_silero_vad (if available)
/// - A custom platform channel implementation
/// - WebRTC VAD bindings
library;

import 'dart:async';
import 'vad_service.dart';

/// Stub implementation of VADService
///
/// This implementation does not perform actual voice activity detection.
/// It is provided to satisfy the interface contract while the audio_session
/// approach handles the audio focus conflicts.
///
/// The continuous listening feature still works because:
/// 1. audio_session configures playAndRecord mode
/// 2. onSpeechStart callback in VoiceService detects first recognized word
/// 3. This provides a slight delay but functional speech-start detection
class StubVADService implements VADService {
  bool _isMonitoring = false;
  bool _isVoiceActive = false;

  @override
  Future<void> initialize() async {
    // Stub: No initialization required
    // In a real implementation, this would:
    // - Load the Silero VAD ONNX model
    // - Initialize audio capture for VAD processing
  }

  @override
  void startMonitoring({
    required Function() onVoiceStart,
    required Function() onVoiceEnd,
  }) {
    // Stub: Does not actually monitor voice activity
    // The VoiceService.onSpeechStart callback handles speech detection
    // via the first recognized word from STT
    _isMonitoring = true;
    _isVoiceActive = false;

    // Note: In a real implementation, this would:
    // - Start audio capture
    // - Process audio frames through VAD model
    // - Call onVoiceStart when voice is detected
    // - Call onVoiceEnd when silence is detected
  }

  @override
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    _isVoiceActive = false;
  }

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  bool get isVoiceActive => _isVoiceActive;

  @override
  Future<void> dispose() async {
    await stopMonitoring();
  }
}
