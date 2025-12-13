Continuous Listening Feature - Complete Analysis & Solution Plan
1. Expected App Flow (Correct Behavior)
┌─────────────────────────────────────────────────────────────────────────────┐
│                         EXPECTED CONTINUOUS LISTENING FLOW                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 1: USER ENABLES CONTINUOUS LISTENING MODE                       │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • User presses the listening toggle button                          │   │
│  │ • App verifies headphones are connected                             │   │
│  │ • App requests microphone permission (if not granted)               │   │
│  │ • Continuous listening mode activates                               │   │
│  │ • VIDEO KEEPS PLAYING (does NOT pause)                              │   │
│  │ • App waits for user to speak                                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 2: USER STARTS SPEAKING                                         │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • App detects user voice (speech onset)                             │   │
│  │ • VIDEO PAUSES IMMEDIATELY (when user STARTS speaking)              │   │
│  │ • App continues recording user's question                           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 3: USER FINISHES SPEAKING (Silence Detected)                    │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • App detects silence (user stopped talking)                        │   │
│  │ • Question text is finalized                                        │   │
│  │ • Question is sent to LLM API                                       │   │
│  │ • Video remains paused                                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 4: ANSWER RECEIVED & TTS SPEAKS                                 │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • LLM returns answer                                                │   │
│  │ • TTS reads the answer aloud                                        │   │
│  │ • App WAITS for TTS to COMPLETE (robust completion detection)       │   │
│  │ • Video remains paused during TTS                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 5: GRACE PERIOD (Wait for Follow-up Question)                   │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • After TTS completes, grace period starts (~5 seconds)             │   │
│  │ • App listens for follow-up question                                │   │
│  │ • Video remains paused                                              │   │
│  │                                                                     │   │
│  │ IF user speaks during grace period:                                 │   │
│  │   → GOTO STEP 3 (process new question)                              │   │
│  │                                                                     │   │
│  │ IF grace period expires with no speech:                             │   │
│  │   → GOTO STEP 6                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ STEP 6: RESUME VIDEO & CONTINUE LISTENING                            │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • Video RESUMES playing                                             │   │
│  │ • App continues listening in background                             │   │
│  │ • Returns to STEP 1 state (video plays, app waits for speech)       │   │
│  │                                                                     │   │
│  │ IF user speaks again:                                               │   │
│  │   → GOTO STEP 2                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ TIMEOUT BEHAVIOR (Enhanced Feature)                                  │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ WHILE VIDEO IS PLAYING:                                             │   │
│  │   • Listening mode stays ON indefinitely                            │   │
│  │   • No auto-disable (user is actively watching)                     │   │
│  │                                                                     │   │
│  │ WHEN VIDEO PAUSES OR FINISHES:                                      │   │
│  │   • Start 1-minute inactivity timer                                 │   │
│  │   • If user speaks: reset timer, process question                   │   │
│  │   • If 1 minute passes with no speech: auto-disable listening mode  │   │
│  │   • Show notification: "Listening mode turned off"                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ EXIT CONDITIONS                                                      │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • User manually presses toggle button → disable listening mode      │   │
│  │ • Headphones disconnected → disable listening mode                  │   │
│  │ • App goes to background → pause mode, offer resume on return       │   │
│  │ • 1-minute timeout after video pause/finish → disable mode          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Key Principles
Principle	Description
Video plays while listening	Video should NOT pause just because listening mode is ON
Video pauses on speech START	Pause when user STARTS speaking, not after they finish
Wait for TTS completion	Use robust callback, not time estimation
Grace period for follow-ups	Allow user to ask follow-up questions
App controls video	Video is a "dumb" entity controlled by app logic, not by OS audio focus
Continuous until manual disable	Listening stays ON until user explicitly turns it OFF
2. Current Wrong Workflow (The Bugs)
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CURRENT BROKEN FLOW                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  USER PRESSES LISTENING BUTTON                                              │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ BUG 1: VIDEO STOPS IMMEDIATELY                                       │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • STT starts → requests Android audio focus                         │   │
│  │ • Android gives audio focus to STT                                  │   │
│  │ • YouTube WebView loses audio focus → AUTO-PAUSES (OS behavior)     │   │
│  │                                                                     │   │
│  │ EXPECTED: Video should keep playing                                 │   │
│  │ ACTUAL: Video pauses immediately                                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ BUG 2: RAPID STOP/RESUME LOOP                                        │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ 1. STT starts → video pauses (audio focus)                          │   │
│  │ 2. STT detects silence → stops → releases audio focus               │   │
│  │ 3. Video resumes (audio focus available)                            │   │
│  │ 4. After 500ms, app restarts STT                                    │   │
│  │ 5. GOTO step 1 → INFINITE LOOP                                      │   │
│  │                                                                     │   │
│  │ User sees: Video keeps stopping and resuming every ~1 second        │   │
│  │ Green mic icon appears/disappears repeatedly                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ WHEN USER ACTUALLY SPEAKS (while mic icon is visible)                │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • App DOES capture the question correctly                           │   │
│  │ • Question is sent to API                                           │   │
│  │ • Answer is received                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ BUG 3: VIDEO RESUMES WITHOUT WAITING FOR TTS                         │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • Answer is received                                                │   │
│  │ • Video resumes IMMEDIATELY                                         │   │
│  │ • Does NOT wait for TTS to read the answer                          │   │
│  │ • Does NOT wait for grace period                                    │   │
│  │                                                                     │   │
│  │ EXPECTED: Wait for TTS → grace period → then resume                 │   │
│  │ ACTUAL: Resumes immediately after answer                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ BUG 4: LISTENING STOPS WORKING AFTER FIRST Q/A                       │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │ • First question/answer works                                       │   │
│  │ • After that, listening mode appears ON (UI shows green)            │   │
│  │ • But mic never activates again                                     │   │
│  │ • User's subsequent speech is not detected                          │   │
│  │                                                                     │   │
│  │ EXPECTED: Continue detecting speech for multiple Q/A cycles         │   │
│  │ ACTUAL: Only works once, then silently fails                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Summary of Current Bugs
Bug	Symptom	User Impact
Bug 1	Video stops when pressing listening button	Confusing, unexpected behavior
Bug 2	Video stop/resume loop (~1 second cycles)	Unusable, very annoying
Bug 3	Video resumes without waiting for TTS	User misses the answer
Bug 4	Listening stops after first Q/A	Feature completely broken
3. Root Cause Analysis & Solutions
Issue 1: Video Stops Immediately & Loops
Root Cause
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ROOT CAUSE: ANDROID AUDIO FOCUS SYSTEM                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  WHAT HAPPENS:                                                              │
│                                                                             │
│  1. speech_to_text plugin starts → calls Android's SpeechRecognizer         │
│  2. SpeechRecognizer requests AUDIO_FOCUS_GAIN                              │
│  3. Android grants audio focus to SpeechRecognizer                          │
│  4. YouTube WebView receives "audio focus lost" callback                    │
│  5. WebView's default behavior: PAUSE playback                              │
│                                                                             │
│  WHY IT LOOPS:                                                              │
│                                                                             │
│  • When STT detects silence → stops → releases audio focus                  │
│  • YouTube can resume (audio focus available)                               │
│  • VoiceServiceImpl._startListeningCycle restarts STT after 500ms           │
│  • Cycle repeats indefinitely                                               │
│                                                                             │
│  CODE LOCATION: voice_service_impl.dart lines 194-214                       │
│                                                                             │
│  onDone: () {                                                               │
│    if (finalRecognizedText != null) {                                       │
│      onQuestionDetected(finalRecognizedText!);                              │
│    } else {                                                                 │
│      // THIS CAUSES THE LOOP:                                               │
│      Future.delayed(const Duration(milliseconds: 500), () {                 │
│        _startListeningCycle(...);  // Restarts immediately                  │
│      });                                                                    │
│    }                                                                        │
│  }                                                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Solutions
Solution 1A: Audio Session Configuration
Concept: Configure Android to allow simultaneous recording and playback using the audio_session package.

// Configure audio session for playAndRecord mode
final session = await AudioSession.instance;
await session.configure(AudioSessionConfiguration(
  avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
  avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
  androidAudioAttributes: const AndroidAudioAttributes(
    contentType: AndroidAudioContentType.speech,
    usage: AndroidAudioUsage.voiceCommunication,
  ),
  // KEY: Don't steal focus, allow other audio to continue (ducked)
  androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
));

Pros	Cons
✅ Simple implementation	⚠️ May not work on all Android devices (OEM variations)
✅ Uses standard Android APIs	⚠️ YouTube WebView behavior may vary
✅ No new dependencies (audio_session is lightweight)	⚠️ STT still runs continuously (battery usage)
✅ Addresses the root cause directly	
Complexity: Low
Robustness: Medium-High (depends on device)

Solution 1B: VAD + STT Hybrid (RECOMMENDED)
Concept: Use lightweight Voice Activity Detection (VAD) for continuous monitoring. Only activate full STT when voice is detected.

┌─────────────────────────────────────────────────────────────────┐
│                    VAD + STT HYBRID ARCHITECTURE                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐                                                │
│  │ VAD Service │ ← Silero VAD model (lightweight)               │
│  │ (Always On) │ ← Does NOT request audio focus                 │
│  └──────┬──────┘ ← Very low CPU/battery                         │
│         │                                                       │
│         │ Voice detected?                                       │
│         │                                                       │
│    NO   │   YES                                                 │
│    ↓    ↓                                                       │
│  Keep   ┌─────────────┐                                         │
│  monitoring │ STT Service │ ← Only activated when needed        │
│         │ (On Demand) │ ← Requests audio focus briefly          │
│         └─────────────┘ ← Captures actual words                 │
│                                                                 │
│  FLOW:                                                          │
│  1. Video plays + VAD monitors (no audio focus needed)          │
│  2. VAD detects voice → pause video (OUR code)                  │
│  3. Start STT → capture question                                │
│  4. Stop STT → process → TTS → grace period                     │
│  5. Resume video → back to VAD monitoring                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Pros	Cons
✅ Video never pauses unexpectedly	⚠️ More complex architecture
✅ YOU control when video pauses	⚠️ Adds ~2-5MB for Silero VAD model
✅ Battery efficient (VAD is very light)	⚠️ Small delay between voice detection and STT start
✅ Works like ChatGPT/Gemini voice mode	
✅ Robust across all devices	
✅ No audio focus conflicts	
Complexity: Medium
Robustness: High

Required Package: vad (Silero VAD, cross-platform)

Solution 1C: Vosk Offline STT
Concept: Replace Google's speech_to_text with Vosk offline STT, which has different audio handling.

Pros	Cons
✅ Works offline (no network needed)	⚠️ Large model size (~50MB)
✅ Different audio handling (may avoid focus issues)	⚠️ Potentially lower accuracy than Google STT
✅ Confirmed to work alongside other audio	⚠️ More complex setup
✅ Continuous streaming API	⚠️ Requires model bundling
Complexity: Medium
Robustness: High

Required Package: vosk_flutter_2

Solution 1D: Switch YouTube Player to InAppWebView
Concept: Use flutter_inappwebview instead of youtube_player_iframe for more control over audio focus behavior.

InAppWebView(
  initialSettings: InAppWebViewSettings(
    allowBackgroundAudioPlaying: true,  // Keep playing when other audio starts
    mediaPlaybackRequiresUserGesture: false,
  ),
)

Pros	Cons
✅ More control over WebView behavior	⚠️ Requires refactoring video player
✅ allowBackgroundAudioPlaying setting	⚠️ May not fully solve audio focus issue
✅ Can combine with Solution 1A	⚠️ Different API than current player
Complexity: Medium
Robustness: Medium

Recommendation for Issue 1
Primary: Solution 1B (VAD + STT Hybrid)

Most robust across all devices
Gives complete control over when video pauses
Battery efficient
Standard pattern used by major voice apps
Fallback: Solution 1A (Audio Session Configuration)

If VAD approach is too complex initially
Can be implemented alongside Solution 1B
Issue 2: Listening Stops After First Q/A
Root Cause
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ROOT CAUSE: FLAG NEVER RESET                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CODE LOCATION: voice_service_impl.dart lines 132-146                       │
│                                                                             │
│  void startContinuousListening(...) {                                       │
│    if (_isContinuousListening) {                                            │
│      return;  // ← BUG: Returns early, never starts new cycle!              │
│    }                                                                        │
│    _isContinuousListening = true;                                           │
│    _startListeningCycle(...);                                               │
│  }                                                                          │
│                                                                             │
│  WHAT HAPPENS:                                                              │
│                                                                             │
│  1. User enables continuous mode                                            │
│  2. startContinuousListening() called → _isContinuousListening = true       │
│  3. First Q/A cycle completes                                               │
│  4. _resumeListening() in VoiceNotifier tries to restart                    │
│  5. Calls startContinuousListening() again                                  │
│  6. BUT: _isContinuousListening is still true!                              │
│  7. Method returns early → NO NEW LISTENING CYCLE STARTS                    │
│  8. Mic never activates again                                               │
│                                                                             │
│  The flag _isContinuousListening is meant to prevent double-starts,         │
│  but it's never reset between Q/A cycles.                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Solution
Fix: Add a separate method for restarting the listening cycle (used after Q/A), distinct from the initial start method.

// voice_service_impl.dart

// Called once when user enables continuous mode
void startContinuousListening({
  required Function(String) onQuestionDetected,
  Duration? pauseFor,
  Duration? listenFor,
}) {
  if (_isContinuousListening) return;  // Prevent double-start
  _isContinuousListening = true;
  _startListeningCycle(...);
}

// NEW: Called to restart after Q/A cycle completes
void restartListeningCycle({
  required Function(String) onQuestionDetected,
  Duration? pauseFor,
  Duration? listenFor,
}) {
  if (!_isContinuousListening) return;  // Only if mode is still enabled
  _startListeningCycle(...);  // Start new cycle without flag check
}

Pros	Cons
✅ Direct fix for the bug	None
✅ Simple change	
✅ Maintains existing architecture	
✅ No new dependencies	
Complexity: Low
Robustness: High

Issue 3: Video Resumes Without Waiting for TTS
Root Cause
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ROOT CAUSE: TTS INTERRUPTION / ERROR PATH                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  The flutter_tts package DOES have completion callbacks:                    │
│                                                                             │
│  _tts.setCompletionHandler(() {                                             │
│    // Fires when TTS finishes speaking                                      │
│  });                                                                        │
│                                                                             │
│  BUT the issue is likely:                                                   │
│                                                                             │
│  1. AUDIO FOCUS CONFLICT:                                                   │
│     • The audio focus battle (Issue 1) may interrupt TTS                    │
│     • TTS errors/cancels → onError callback fires                           │
│     • onError immediately calls _resumeListening()                          │
│     • Video resumes too early                                               │
│                                                                             │
│  2. CODE PATH (voice_notifier.dart):                                        │
│                                                                             │
│  _synthesisSubscription = stream.listen(                                    │
│    onError: (error) {                                                       │
│      _onAnswerCallback?.call(answer);                                       │
│      _resumeListening();  // ← Resumes immediately on ANY error             │
│    },                                                                       │
│    onDone: () {                                                             │
│      _resumeListening();  // ← Should only fire after TTS completes         │
│    },                                                                       │
│  );                                                                         │
│                                                                             │
│  If TTS is interrupted (audio focus taken away), the stream may             │
│  close/error prematurely, triggering early resume.                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Solution
Fix: Improve TTS error handling with retry logic and ensure proper completion verification.

Future<void> speakAnswerAndResume(String answer) async {
  if (!state.isContinuousModeEnabled) return;
  
  _resetInactivityTimer();
  state = state.copyWith(
    continuousListeningState: ContinuousListeningState.speaking,
  );

  bool ttsCompleted = false;
  int retryCount = 0;
  const maxRetries = 1;

  Future<void> attemptSpeak() async {
    final completer = Completer<void>();
    final stream = _voiceService.speak(answer);

    _synthesisSubscription = stream.listen(
      (synthesisState) {
        state = state.copyWith(synthesisState: synthesisState);
      },
      onError: (error) {
        if (retryCount < maxRetries) {
          retryCount++;
          // Retry after short delay
          Future.delayed(Duration(milliseconds: 500), () => attemptSpeak());
        } else {
          // Show answer as text since TTS failed
          _onAnswerCallback?.call(answer);
          ttsCompleted = true;  // Mark as "completed" (with fallback)
          _startGracePeriod();
        }
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        ttsCompleted = true;
        _startGracePeriod();
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
  }

  await attemptSpeak();
}

void _startGracePeriod() {
  state = state.copyWith(
    continuousListeningState: ContinuousListeningState.waitingForNextQuestion,
    recognizedText: '',
  );

  _gracePeriodTimer?.cancel();
  _gracePeriodTimer = Timer(const Duration(seconds: 5), () {
    if (!state.isContinuousModeEnabled) return;
    
    state = state.copyWith(
      continuousListeningState: ContinuousListeningState.listening,
    );
    
    // Resume video here (coordinator listens to this state change)
    _voiceService.restartListeningCycle(...);
  });
}

