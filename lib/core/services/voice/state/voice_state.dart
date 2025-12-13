/// Voice feature state
library;

import '../voice_models.dart';

class VoiceState {
  final bool isListening;
  final bool isSpeaking;
  final String recognizedText;
  final String? error;
  final bool isInitialized;
  final SpeechRecognitionState recognitionState;
  final SpeechSynthesisState synthesisState;

  // Continuous listening mode fields
  final bool isContinuousModeEnabled;
  final ContinuousListeningState continuousListeningState;

  const VoiceState({
    this.isListening = false,
    this.isSpeaking = false,
    this.recognizedText = '',
    this.error,
    this.isInitialized = false,
    this.recognitionState = SpeechRecognitionState.idle,
    this.synthesisState = SpeechSynthesisState.idle,
    this.isContinuousModeEnabled = false,
    this.continuousListeningState = ContinuousListeningState.idle,
  });

  VoiceState copyWith({
    bool? isListening,
    bool? isSpeaking,
    String? recognizedText,
    String? error,
    bool? isInitialized,
    SpeechRecognitionState? recognitionState,
    SpeechSynthesisState? synthesisState,
    bool? isContinuousModeEnabled,
    ContinuousListeningState? continuousListeningState,
  }) {
    return VoiceState(
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      recognizedText: recognizedText ?? this.recognizedText,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
      recognitionState: recognitionState ?? this.recognitionState,
      synthesisState: synthesisState ?? this.synthesisState,
      isContinuousModeEnabled: isContinuousModeEnabled ?? this.isContinuousModeEnabled,
      continuousListeningState: continuousListeningState ?? this.continuousListeningState,
    );
  }

  /// Clear error
  VoiceState clearError() {
    return copyWith(error: '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VoiceState &&
        other.isListening == isListening &&
        other.isSpeaking == isSpeaking &&
        other.recognizedText == recognizedText &&
        other.error == error &&
        other.isInitialized == isInitialized &&
        other.recognitionState == recognitionState &&
        other.synthesisState == synthesisState &&
        other.isContinuousModeEnabled == isContinuousModeEnabled &&
        other.continuousListeningState == continuousListeningState;
  }

  @override
  int get hashCode {
    return Object.hash(
      isListening,
      isSpeaking,
      recognizedText,
      error,
      isInitialized,
      recognitionState,
      synthesisState,
      isContinuousModeEnabled,
      continuousListeningState,
    );
  }
}
