# Continuous Listening Feature - Technical Documentation

## Overview

The Continuous Listening feature allows users to ask questions about a YouTube video using voice while the video is playing. The app listens for questions, pauses the video when the user speaks, processes the question through an LLM, speaks the answer aloud, and resumes video playback.

## Problem Statement

The initial implementation had four critical bugs:

| Bug | Symptom | User Impact |
|-----|---------|-------------|
| **Bug 1** | Video stops immediately when pressing listening button | Unexpected behavior |
| **Bug 2** | Video stop/resume loop (~1 second cycles) | Unusable, very annoying |
| **Bug 3** | Video resumes without waiting for TTS | User misses the answer |
| **Bug 4** | Listening stops after first Q/A | Feature completely broken |

## Root Cause Analysis

### Bug 1 & 2: Audio Focus Conflict

**Root Cause:** Android's audio focus system. When STT (speech_to_text) starts, it requests `AUDIO_FOCUS_GAIN`. Android grants this focus, causing the YouTube WebView to lose focus and auto-pause.

```
1. speech_to_text plugin starts → calls Android's SpeechRecognizer
2. SpeechRecognizer requests AUDIO_FOCUS_GAIN
3. Android grants audio focus to SpeechRecognizer
4. YouTube WebView receives "audio focus lost" callback
5. WebView's default behavior: PAUSE playback
```

The loop occurs because:
1. STT starts → video pauses (audio focus)
2. STT detects silence → stops → releases audio focus
3. Video resumes (audio focus available)
4. After 500ms, app restarts STT
5. GOTO step 1 → INFINITE LOOP

### Bug 3: Missing TTS Completion Handling

**Root Cause:** The code resumed listening immediately after starting TTS without waiting for it to complete. Audio focus conflicts could also interrupt TTS prematurely.

### Bug 4: Flag Not Reset

**Root Cause:** The `_isContinuousListening` flag in `VoiceServiceImpl.startContinuousListening()` prevented restarting after Q/A cycle:

```dart
void startContinuousListening(...) {
  if (_isContinuousListening) {
    return;  // BUG: Returns early after first Q/A!
  }
  _isContinuousListening = true;
  _startListeningCycle(...);
}
```

When `_resumeListening()` called `startContinuousListening()`, it returned early because the flag was still true.

## Solution Architecture

### Selected Solution: Audio Session Configuration + STT Speech Onset Detection

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         AUDIO SESSION LAYER                              │
│                     (Configure playAndRecord mode)                       │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         VOICE SERVICE                                    │
│  • Coordinates STT and TTS                                              │
│  • Provides onSpeechStart callback (first recognized word)              │
│  • Provides onQuestionDetected callback (after silence)                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       VOICE NOTIFIER                                     │
│  • State machine owner                                                  │
│  • Coordinates voice states with app behavior                           │
│  • Manages timeouts and grace periods                                   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    QA SCREEN COORDINATOR                                 │
│  • Reacts to voice state changes                                        │
│  • Controls video: pause on userSpeaking, resume on listening           │
└─────────────────────────────────────────────────────────────────────────┘
```

### State Machine

```
enum ContinuousListeningState {
  idle,                    // Mode disabled
  listening,               // STT monitoring, video plays
  userSpeaking,            // Voice detected, video paused
  processing,              // STT done, calling LLM
  speaking,                // TTS reading answer
  waitingForNextQuestion,  // Grace period after speaking
}
```

**State Transitions:**
```
                        ┌──────────┐
                        │   IDLE   │
                        └────┬─────┘
                             │ enable
                             ▼
       ┌──────────────────────────────────────────────────┐
       │                  LISTENING                        │◄────────┐
       │           (STT monitors, video plays)             │         │
       └────────────────────┬─────────────────────────────┘         │
                            │                                        │
                    speech detected                                  │
                            │                                        │
                            ▼                                        │
       ┌──────────────────────────────────────────────────┐         │
       │               USER_SPEAKING                       │         │
       │       (STT captures, video paused)                │         │
       └────────────────────┬─────────────────────────────┘         │
                            │                                        │
                    silence detected                                 │
                            │                                        │
                            ▼                                        │
       ┌──────────────────────────────────────────────────┐         │
       │                PROCESSING                         │         │
       │            (calling LLM API)                      │         │
       └────────────────────┬─────────────────────────────┘         │
                            │                                        │
                     answer ready                                    │
                            │                                        │
                            ▼                                        │
       ┌──────────────────────────────────────────────────┐         │
       │                 SPEAKING                          │         │
       │           (TTS reads answer)                      │         │
       └────────────────────┬─────────────────────────────┘         │
                            │                                        │
                    TTS completes                                    │
                            │                                        │
                            ▼                                        │
       ┌──────────────────────────────────────────────────┐         │
       │          WAITING_FOR_NEXT_QUESTION                │         │
       │              (grace period)                       │         │
       └───────┬──────────────────────────────┬───────────┘         │
               │                              │                      │
       user speaks                    grace period expires           │
               │                              │                      │
               ▼                              └──────────────────────┘
        USER_SPEAKING                    (resume video, back to LISTENING)
```

### Video Control Rules

| State Transition | Video Action |
|------------------|--------------|
| idle → listening | No change (keep playing) |
| listening → userSpeaking | **PAUSE** |
| userSpeaking → processing | Keep paused |
| processing → speaking | Keep paused |
| speaking → waitingForNextQuestion | Keep paused |
| waitingForNextQuestion → listening | **RESUME** |
| waitingForNextQuestion → userSpeaking | Keep paused |
| Any → idle | Resume (if was playing before) |

## Solutions Considered

### Solution A: Audio Session Configuration (SELECTED)

**Approach:** Use the `audio_session` package to configure Android/iOS for simultaneous recording and playback.

```dart
await session.configure(AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
  avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.mixWithOthers,
  androidAudioFocusGainType:
      AndroidAudioFocusGainType.gainTransientMayDuck,
));
```

**Pros:**
- ✅ Simple implementation
- ✅ Uses standard Android/iOS APIs
- ✅ Lightweight (minimal bundle size impact)
- ✅ Addresses root cause directly

**Cons:**
- ⚠️ May not work on all Android devices (OEM variations)
- ⚠️ YouTube WebView behavior may vary
- ⚠️ STT still runs continuously (some battery usage)

**Status:** IMPLEMENTED

### Solution B: VAD + STT Hybrid (PLANNED)

**Approach:** Use Voice Activity Detection (Silero VAD) for lightweight monitoring. Only activate full STT when voice is detected.

```
┌─────────────┐
│ VAD Service │ ← Silero VAD model (lightweight)
│ (Always On) │ ← Does NOT request audio focus
└──────┬──────┘ ← Very low CPU/battery
       │
       │ Voice detected?
       │
  NO   │   YES
  ↓    ↓
Keep   ┌─────────────┐
monitoring │ STT Service │ ← Only activated when needed
       │ (On Demand) │ ← Requests audio focus briefly
       └─────────────┘ ← Captures actual words
```

**Pros:**
- ✅ Video never pauses unexpectedly
- ✅ YOU control when video pauses
- ✅ Battery efficient (VAD is very light)
- ✅ Robust across all devices

**Cons:**
- ⚠️ More complex architecture
- ⚠️ Adds ~2-5MB for Silero VAD model
- ⚠️ Requires native plugin development or finding existing package

**Status:** INTERFACE DEFINED, STUB IMPLEMENTATION
- VADService interface created
- StubVADService provides placeholder
- Actual Silero VAD integration pending package availability

### Solution C: Vosk Offline STT (REJECTED)

**Approach:** Replace Google's speech_to_text with Vosk offline STT, which has different audio handling.

**Pros:**
- ✅ Works offline
- ✅ Different audio handling (may avoid focus issues)
- ✅ Continuous streaming API

**Cons:**
- ❌ Large model size (~50MB)
- ❌ Potentially lower accuracy than Google STT
- ❌ More complex setup
- ❌ Requires bundling model with app

**Status:** REJECTED - Bundle size impact too significant

### Solution D: Switch to InAppWebView (NOT NEEDED)

**Approach:** Use `flutter_inappwebview` instead of `youtube_player_iframe` for more control.

```dart
InAppWebView(
  initialSettings: InAppWebViewSettings(
    allowBackgroundAudioPlaying: true,
  ),
)
```

**Pros:**
- ✅ More control over WebView behavior
- ✅ `allowBackgroundAudioPlaying` setting

**Cons:**
- ❌ Requires significant refactoring
- ❌ May not fully solve audio focus issue
- ❌ Different API than current player

**Status:** NOT NEEDED - Audio session configuration sufficient

## Implementation Details

### Key Files Modified

| File | Changes |
|------|---------|
| `pubspec.yaml` | Added `audio_session` package |
| `voice_models.dart` | Added `userSpeaking` state to enum |
| `voice_service.dart` | Added `restartListeningCycle` method, `onSpeechStart` callback |
| `voice_service_impl.dart` | Fixed flag bug, added speech onset detection |
| `voice_notifier.dart` | Complete rewrite with proper state machine |
| `qa_screen_coordinator.dart` | Updated video sync logic |
| `audio_session_service.dart` | NEW - Audio session configuration |
| `vad_service.dart` | NEW - VAD interface (for future) |
| `silero_vad_service.dart` | NEW - Stub VAD implementation |

### Bug Fixes Applied

**Bug 1 & 2 Fix (Audio Focus):**
```dart
// AudioSessionServiceImpl.configureForContinuousListening()
await session.configure(AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
  androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
));
```

**Bug 3 Fix (TTS Completion):**
```dart
// VoiceNotifier.speakAnswerAndResume()
Future<void> speakAnswerAndResume(String answer) async {
  final completer = Completer<void>();

  _synthesisSubscription = stream.listen(
    onDone: () {
      _startGracePeriod();  // Only after TTS completes
      completer.complete();
    },
  );

  await completer.future;  // Wait for completion
}
```

**Bug 4 Fix (Flag Reset):**
```dart
// VoiceService interface
void restartListeningCycle({...});  // New method

// VoiceNotifier._resumeListeningAfterGracePeriod()
void _resumeListeningAfterGracePeriod() {
  // Use restartListeningCycle instead of startContinuousListening
  _voiceService.restartListeningCycle(
    onQuestionDetected: _handleQuestionDetected,
    onSpeechStart: _handleSpeechStart,
  );
}
```

## Timeout Behavior

| Scenario | Timeout | Action |
|----------|---------|--------|
| Video playing, no speech | None | Listening stays ON indefinitely |
| Video paused/finished, no speech | 1 minute | Auto-disable listening mode |
| No Q/A activity | 5 minutes | Auto-disable listening mode |

## Future Improvements

1. **Real VAD Integration**
   - Integrate Silero VAD ONNX model via platform channel
   - Enables instant voice detection without STT delay
   - More battery efficient

2. **Follow-up Question Detection During Grace Period**
   - Currently listening restarts after grace period
   - Could detect speech during grace period without full restart

3. **Background Audio Mode**
   - Allow listening to continue when app is in background
   - Requires foreground service on Android

## Testing

Key test scenarios:
- [ ] Enable listening → video keeps playing (no loop)
- [ ] Speak question → video pauses at speech START
- [ ] Answer received → TTS speaks fully → grace period → video resumes
- [ ] Follow-up question during grace period
- [ ] Multiple Q/A cycles work correctly
- [ ] 1-minute timeout after video pause
- [ ] Manual disable/enable
- [ ] Headphone disconnect safety
- [ ] App background/resume
