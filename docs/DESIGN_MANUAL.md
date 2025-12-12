# Learnova Design Manual

**Purpose:** Design decisions, architectural choices, and development guidelines.

---

## Project Overview

**Learnova** is a voice-first learning companion for YouTube videos.
**Core Value:** AI-powered Q&A based on video transcripts.
**Platform:** Flutter (iOS, Android, Web).

### Current Status
**Phase:** Step 8 - Clean Minimal UI (Complete)
- **Core Features:** YouTube URL loading, Transcript fetching with timestamps, Video playback, Position-aware Q&A, GPT-4o-mini Q&A
- **Voice Features:** Voice-first UI with text fallback, Auto-speak answers for voice input, Continuous hands-free listening (auto-enabled by default), Headphone detection & enforcement, Video initialization safety controls, Configurable silence detection (3s pauseFor)
- **UI/UX:** Bottom action bar with expandable states (URL/Ask/Chat), Large listening toggle button with color-coded states (green=on, red=off, grey=disabled), Collapsible session history drawer (85% height), Skeletonizer loading shimmer for video, Clean minimal interface with video focus
- **Storage:** Auto-save conversations, History retrieval, Auto-restore previous conversations, Clear all history, State persistence via Hive (preferences + history)
- **Lifecycle:** App background handling, Resume dialog with preferences, Headphone disconnect auto-stop, State restoration on app resume
- **Pending:** Auth, Multi-turn conversation context

---

## Architecture Philosophy

### 1. Feature-Based Organization
**Decision:** Organize by features (`features/qa`), not layers.
**Why:** Scalability, clear boundaries, independent deployment.

### 2. Service-Based Feature Communication
**Decision:** Features communicate **only** through services.
**Pattern:** `Feature A -> Feature B Service -> Feature B Logic`
**Why:** Decouples logic from UI, prevents circular dependencies.

### 3. Provider-Agnostic LLM Abstraction
**Decision:** Abstract LLM providers behind `LLMService` interface.
**Why:** Avoids vendor lock-in (OpenAI <-> Gemini), enables testing.

### 4. Provider-Agnostic Voice Abstraction
**Decision:** Abstract STT/TTS providers behind `STTService`/`TTSService` interfaces, coordinated by `VoiceService`.
**Why:** Enables switching between providers (speech_to_text <-> Google Cloud STT, flutter_tts <-> ElevenLabs), testability.

### 5. Result Pattern for Error Handling
**Decision:** Return `Result<Success, Failure>` instead of throwing exceptions.
**Why:** Explicit error handling, fail-fast principle.
**Implementation:** `isSuccess` checks `failure == null` (not `data != null`) to support void operations returning `success(null)`.

### 6. Storage Abstraction via Repository Pattern
**Decision:** Abstract storage behind `Repository` interface (e.g., `HistoryRepository` → `HiveHistoryRepository`).
**Why:** Swap storage implementations (Hive → SQLite → Cloud), testability (mock repository), DB-agnostic domain models.

---

## Technology Stack

| Tech | Purpose | Why |
|------|---------|-----|
| **Flutter** | UI | Cross-platform |
| **Riverpod** | State/DI | Testable, scalable, compile-time safety |
| **GoRouter** | Routing | Type-safe, deep linking |
| **OpenAI** | LLM | GPT-4o-mini (Cost-effective: ~$0.0001/q) |
| **youtube_player_iframe** | Video Player | Official iFrame API, cross-platform |
| **webview_flutter_android** | WebView (Android) | Required by youtube_player_iframe v5.2.2 (^4.10.9) |
| **webview_flutter_wkwebview** | WebView (iOS) | Required by youtube_player_iframe v5.2.2 (^3.23.0) |
| **speech_to_text** | Speech-to-Text | Native platform APIs, offline support (iOS), battle-tested |
| **flutter_tts** | Text-to-Speech | Native platform voices, offline, free |
| **permission_handler** | Permissions | Microphone/speech recognition permissions |
| **Hive** | Local Storage | NoSQL, zero setup, fast, cross-platform |

### State Management
**Decision:** `StateNotifier` for logic, widgets call `ref.read(notifier).method()`.
**Avoid:** Callback drilling.

**copyWith Nullable Fields:** `copyWith(field: null)` doesn't work because `null ?? existingValue` returns the existing value. For nullable fields that need resetting to null, create the state object directly instead of using `copyWith`.

### Screen Coordinator Pattern
**Decision:** Use a dedicated `StateNotifier` coordinator when a screen needs to coordinate between multiple providers.

**When to Use:**
- Screen needs to react to changes in multiple providers (e.g., QA + Voice + Video)
- Coordination logic is complex (auto-speak, auto-enable, lifecycle handling)
- Screen would exceed 150 lines with inline coordination logic

**Structure:**
```
┌─────────────────────────────────────────┐
│           Screen (Pure UI)              │
│  • Watches coordinator state            │
│  • Renders widgets                      │
│  • Shows dialogs (UI-only reactions)    │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│    ScreenCoordinator (StateNotifier)    │
│  • Owns coordination state              │
│  • Listens to other providers           │
│  • Coordinates cross-feature behavior   │
└─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
   FeatureA    FeatureB    FeatureC
   Notifier    Notifier    Notifier
```

**Implementation:**
- Coordinator extends `StateNotifier<CoordinatorState>`
- Sets up `ref.listen()` calls in constructor
- State tracks coordination flags (e.g., `wasInContinuousMode`, `shouldShowResumeDialog`)
- Screen watches coordinator state and reacts to UI-triggering flags

**Example:** `QAScreenCoordinator` coordinates QA, Voice, and Video:
- Auto-speaks answers when input was voice
- Auto-enables continuous mode when video loads
- Syncs video playback with voice state
- Handles app lifecycle for continuous mode

**Benefits:**
- Clear separation: logic in StateNotifier, UI in screen
- Testable: coordinator has explicit, observable state
- Maintainable: one place for all coordination logic
- Readable: team/AI can understand coordination at a glance

---

## Code Organization & Refactoring

### Principles
1.  **Screens in Separate Files:** One screen per file.
2.  **Self-Documenting:** Name methods for *intent* (`hasApiKey`), not implementation.
3.  **Small Components:** Screens < 150 lines. Widgets < 60 lines.

### Refactoring Guidelines
**Extract Widgets When:**
- **Complex Logic:** Own state (controllers), loading states.
- **Reusability:** Used in multiple places (e.g., ErrorBanner).
- **Readability:** `build` method > 50 lines.

**How:**
- Move UI logic/local state to new widget.
- **Do NOT pass callbacks.**
- Widget should access `StateNotifier` directly via `ref.read(notifier).method()` for actions.
- Widget should watch `StateNotifier` state via `ref.watch(provider)` for updates.

---

## Testing Philosophy

**Principle:** Practical testing over perfection.

### Strategy
- **Unit Tests:** Business logic, Services, Edge cases.
- **No Widget Tests:** Manual testing preferred for MVP UI.
- **No Widget Tests:** Manual testing preferred for MVP UI.
- **Mocking:** Prefer manual mocks over external packages (e.g., Mockito) unless absolutely necessary.
- **External Dependencies:** Avoid adding testing dependencies to keep the project lightweight.

---

## Configuration
**Decision:** Use `--dart-define` for environment variables (API Keys).
**Why:** Standard, secure, cross-platform.

---

## Key Learnings & Decisions

### YouTube Integration
- **Decision:** Direct Innertube API implementation over libraries (`youtube_explode_dart`).
- **Why:** Stability, control, no external dependencies.
- **Detail:** Use `WEB` client for reliable transcripts.

### Timestamp-Aware Transcripts (Hybrid Approach)
- **Decision:** Parse and store transcript segments with timestamps from YouTube XML.
- **Why:** Enables position-aware Q&A where questions only consider watched content.
- **Structure:** `TranscriptSegment{text, start, duration}` → `VideoInfo.getFullTranscript()` / `getTranscriptUpTo(position)`.
- **Use Case:** Questions like "summarize what I've learned so far" only send watched content to LLM.
- **Implementation:** Video player tracks position → QAState stores currentPosition → QANotifier filters transcript.

### Video Player Integration
- **Decision:** Use `youtube_player_iframe` v5.2.2 with required webview platform implementations.
- **Why:** Actively maintained, official YouTube iFrame API, works cross-platform, no API key required.
- **Dependencies:** Requires `webview_flutter_android` ^4.10.9 and `webview_flutter_wkwebview` ^3.23.0 (version compatibility critical).
- **Position Tracking:** Poll `controller.currentTime` every 1 second via Timer.periodic (returns Future<double> in seconds).
- **Architecture:** VideoPlayer widget → Timer polls position → updates QANotifier.currentPosition → QANotifier filters transcript on askQuestion.
- **Smart Threshold:** Use full transcript for first 10 seconds (avoid empty context), then switch to position-aware filtering.
- **State Design:** Store full `VideoInfo` object in state, use computed getters (videoTitle, videoId) for backward compatibility.

### Prompt Engineering
- **Strategy:** Position-aware transcript + Question -> GPT-4o-mini.
- **Constraint:** Limit answers to 2-3 sentences to control cost/hallucination.
- **Context Filtering:** After 10s of playback, only send transcript up to current video position via `getTranscriptUpTo()`.

### Voice I/O Integration
- **Decision:** Three-layer abstraction for voice services.
- **Structure:**
  - `STTService` interface → `FlutterSTTService` implementation (speech_to_text)
  - `TTSService` interface → `FlutterTTSService` implementation (flutter_tts)
  - `VoiceService` coordinator combines STT + TTS, prevents conflicts
- **Architecture:** `VoiceService` → `VoiceNotifier` (StateNotifier) → UI widgets
- **Permissions:** Dedicated `PermissionService` handles microphone/speech permissions with clear error messages
- **Video Integration:** Video pauses automatically when voice input starts in chat, smart resume in continuous mode
- **Provider Pattern:** Voice controller exposed via `youtubeControllerProvider` for cross-widget coordination
- **Future Upgrades:** Easy to swap to cloud providers (Google Cloud STT/TTS, ElevenLabs) by implementing interfaces

### Voice Recognition Text Capture Fix
- **Problem:** Speech recognition wasn't reliably marking results as "final", causing recognized text to be lost in both one-off and continuous listening modes
- **Root Cause:** `finalText` only updated when `result.isFinal == true`, but STT service sometimes completes without final flag
- **Solution:** Always update `finalText` with latest `recognizedText` on every stream event (regardless of `isFinal` flag)
  - **One-off mode** (`voice_notifier.dart:116`):
    - Before: `if (result.isFinal) { finalText = result.recognizedText; }`
    - After: `finalText = result.recognizedText; // Always update with latest`
  - **Continuous mode** (`voice_service_impl.dart:177`):
    - Before: `if (result.isFinal && result.recognizedText.trim().isNotEmpty) { finalRecognizedText = result.recognizedText; }`
    - After: `if (result.recognizedText.trim().isNotEmpty) { finalRecognizedText = result.recognizedText; } // Always update with latest`
- **Impact:** Both voice input modes now reliably capture and send text to LLM even when final flag not set
- **Testing:** Added comprehensive tests for continuous listening mode:
  - `captures recognized text even without isFinal flag` - Verifies text captured when STT doesn't set final flag
  - `captures latest text when multiple results received` - Ensures latest partial result is used
  - `does not capture empty or whitespace-only text` - Prevents triggering on silence/noise
  - `stops continuous listening and cancels subscription` - Validates cleanup

### Voice-First Hands-Free UX
**Philosophy:** Voice is primary interface, text is fallback for edge cases (accessibility, quiet environments).

**Implementation:**

1. **Voice-First UI Design**
   - Chat UI integrates voice and text input side-by-side (text field + send + mic buttons)
   - No hidden inputs - both methods equally accessible
   - Input method tracking (`InputMethod.voice` vs `InputMethod.text`) in state for selective TTS triggering

2. **Auto-Speak for Voice Questions**
   - Answers automatically spoken when question asked via voice (chat mic button or continuous mode)
   - Text input answers NOT auto-spoken (respects user environment constraints - may be in public/quiet space)
   - Uses existing TTS completion handlers for lifecycle management
   - **Implementation:** QANotifier tracks input method, triggers `_onAutoSpeakCallback` only for voice input
   - **Testing:** Added tests to verify TTS triggered for voice input, NOT triggered for text input

3. **Headphone Detection & Enforcement**
   - Platform-specific implementation: `AudioDeviceService` interface
   - **Android:** `AudioManager.getDevices()` checks wired/Bluetooth headphones (API 23+)
   - **iOS:** `AVAudioSession.currentRoute.outputs` checks audio routes
   - **Auto-detection on video start:** Checks headphone connection when video fully initializes
     - If connected: Automatically enables continuous listening mode
     - If not connected: Listening mode stays off (user can manually enable with dialog prompt)
   - Continuous mode blocked without headphones (shows clear dialog explaining why)
   - Auto-stops continuous mode if headphones disconnect during session
   - Monitors connection changes via broadcast receivers (Android) / notifications (iOS)
   - **Testing:** Added tests to verify headphone requirement, auto-start with headphones, auto-stop on disconnect

4. **Video Initialization Safety**
   - Tracks `isVideoInitialized` (player ready) + `isTranscriptLoaded` separately
   - Mic button and continuous mode toggle disabled until both ready (`isFullyInitialized`)
   - Shows loading indicators on disabled controls with tooltips
   - Prevents errors from premature user interaction

5. **Smart Video Pause/Resume & Grace Period**
   - **When user speaks:** Video pauses immediately to prevent audio interference
   - **During processing:** Video stays paused while question sent to LLM
   - **During TTS:** Video stays paused while answer is spoken aloud
   - **Grace period:** 5-second grace period for user to ask follow-up questions
   - **Buffer time:** Additional 2-second buffer after grace period before resuming
   - **Auto-resume:** Video resumes only if still in continuous mode and listening state
   - **Why:** Ensures user can hear TTS answer without video audio interference, allows time for follow-up questions
   - **Implementation:** Callback chain in `_handleContinuousModeToggle()` coordinates video control with voice flow
   - **State:** `ContinuousListeningState.waitingForNextQuestion` (purple indicator)
   - **Grace Period Auto-Resume:**
   - New state: `ContinuousListeningState.waitingForNextQuestion` (purple indicator)
   - After TTS completes → 5-second grace period → auto-resume listening + video playback
   - Grace period cancellable: User speaks during waiting → processes new question immediately
   - Timer cleanup on mode exit prevents memory leaks
   - Visual feedback: "Ready for next question..." with hourglass icon

**State Flow:**
```
listening → processing → speaking → waitingForNextQuestion → listening (cycle repeats)
                                    ↑ (5s grace period)
```

**Why This Design:**
- Solves TTS-variable duration problem (answers vary in length)
- Natural interaction rhythm (no arbitrary fixed delays)
- Allows rapid-fire questions (cancel timer during grace period)
- Clear visual feedback for each state
- Maintains hands-free flow without awkward pauses

### Voice Service Architecture
**Decision:** Pass `pauseFor` parameter (silence detection timeout) through entire voice service stack.

**Why:**
- One-off voice input (mic button) and continuous listening both need configurable silence detection
- Balanced timeout: 3 seconds for one-off input, 5 seconds for continuous mode
- One-off mode (3s): Quick response for deliberate mic button press
- Continuous mode (5s): Extra time for users to think mid-sentence without premature cutoff
- Prevents recognition cutoff during longer questions or thinking pauses

**Implementation:**
- `VoiceService.startListening()` accepts optional `pauseFor` parameter
- `VoiceNotifier.startListening()` passes 3-second default for one-off input
- Continuous mode uses 5-second threshold for more natural speech patterns
- STT service logs show actual timeout value for debugging

**Continuous Mode Critical Fixes:**
- **Async Flow Fix:**
  - Problem: `speakAnswerAndResume()` returned immediately, breaking flow and causing premature video resume
  - Solution: Added `Completer<void>` to await TTS completion
  - Video timing: Waits TTS + grace period (5s) + buffer (2s) = 7s before resuming
- **Cycle Restart Fix:**
  - Problem: Listening stopped after silence or first question - never restarted
  - Root cause: `onDone` handler only restarted cycle when text detected, not on silence
  - Solution: Restart listening cycle on silence (500ms delay) to maintain continuous operation
  - Impact: Truly continuous listening - works indefinitely across silence and multiple questions
- **Callback Setup:**
  - Callbacks (continuous mode, auto-speak, headphone) set up once in `initState()` via `_setupCallbacks()`
  - Ensures callbacks ready before auto-enable or manual toggle
- **Testing:** Added tests for silence handling, multiple question cycles, and state transitions

**Emulator Testing Note:** Android emulator requires "Virtual microphone uses host audio input" setting enabled in AVD configuration. Speech recognition timeout (`error_speech_timeout`) without this setting is configuration issue, not code defect.

### Continuous Listening Mode & Video Audio Interference
**Problem:** In continuous listening mode, microphone picks up video audio from device speakers, causing speech recognition to transcribe video content instead of user questions.

**Decision:** Headphones-only MVP approach.

**Why:**
- **Zero implementation cost** - Documentation only, no code needed
- **100% reliable** - Completely prevents video audio interference
- **Better learning experience** - Immersive, private, focused
- **Industry standard** - Duolingo, Rosetta Stone, language learning apps require headphones for speaking exercises
- **Ships immediately** - No technical risk, validates core value proposition (voice-powered learning)
- **MVP-appropriate** - Solves problem with simplest constraint rather than complex engineering

**Options Considered & Rejected:**

1. **Echo Cancellation (EC)**
   - **Why rejected:** Unreliable (hardware-dependent), only reduces volume 50-80% (not 100%), STT still picks up quieter video audio
   - **Complexity:** Medium, requires platform-specific tuning
   - **Result:** Unpredictable UX across devices

2. **Transcript-Based Filtering**
   - **Concept:** Match recognized words against video transcript to filter out video audio
   - **Why rejected:**
     - **Fatal flaw:** Microphone receives mixed audio (user + video) as single stream; impossible to separate at application level
     - **False positives:** User asks "What is machine learning?" → exact phrase in transcript → algorithm ignores legitimate question
     - **Timing synchronization:** Requires perfect real-time sync with video position (pause, seek, rewind breaks matching)
     - **STT variability:** "you're" vs "you are", "4" vs "four" breaks exact matching
   - **Complexity:** Very high
   - **Result:** Unreliable, poor UX (ignores real questions)

3. **EC + Transcript Filtering + Smart Pause Detection**
   - **Concept:** Use EC to reduce video volume, detect "different" words, pause video for 1 second to verify
   - **Why rejected:**
     - **False positives ruin UX:** Background noise, coughs, nearby conversations trigger random video pausing
     - **Still has mixed audio problem:** Even with EC, need transcript matching (still unreliable)
     - **Video stuttering:** Constant interruptions destroy learning flow
   - **Complexity:** Very high (40-60 hours implementation)
   - **Result:** Bad UX, unreliable detection

4. **Wake Word Detection ("Hey Learnova...")**
   - **Concept:** Only listen after detecting keyword
   - **Why rejected:**
     - **Not truly hands-free:** Must remember keyword, adds friction
     - **Unnatural for learning:** Command-based vs conversational
     - **Implementation cost:** 10-15 hours, new dependency
   - **Valid solution but wrong for learning context**

**Silence Detection Timeout:**
- **Decision:** 3-second pause threshold (configurable via `pauseFor` parameter)
- **Why:** Balance between responsiveness and false triggers
- **Implementation:** Pass `pauseFor` through `VoiceService` → `STTService` → platform STT
- **Lesson learned:** Initially hardcoded to 10 seconds, caused poor UX (long wait after speaking). Fixed by making configurable.

**Future Enhancement (Phase 2 - Post-MVP):**
- **Video Auto-Pause Option:** Add settings toggle to pause video during listening for speaker mode
- **Implementation:** 2-3 hours (pause/resume video player when entering/exiting listening state)
- **User value:** Enables speaker mode without headphones in quiet environments
- **Decision criteria:** Only implement if users request it; expect most prefer headphones for focused learning

**Key Principle:** For MVP, solve problems with simplest constraint (headphones) rather than complex engineering (EC + filtering). Ship fast, validate core hypothesis, iterate based on real user feedback.

### Persistence & History Storage
- **Decision:** Separate history feature (`features/history/`), not coupled to QA. Hive for storage, abstracted via Repository pattern.
- **Why:** Clear boundaries, reusable across features, future flexibility (cloud sync, SQLite).
- **Architecture:** QA feature → HistoryService (public API) → HistoryRepository (abstraction) → HiveHistoryRepository (implementation).
- **Auto-Save:** After each successful Q&A, save conversation (one per video, append entries if same video). Silent failure (don't disrupt UX).
- **Models:** DB-agnostic domain models (`ConversationHistory`, `QAEntry`). Hive adapters in separate layer for serialization.
- **UI:** Bottom sheet with conversation list (video title, date, Q&A count). Tap row → load video + restore history. Delete individual/clear all with confirmation.
- **Auto-scroll:** Q&A history list scrolls to bottom when loading conversation from history or adding new entries.
- **Smart Loading:** When URL is pasted, check if conversation exists for that video. If yes, restore previous conversation; if no, start fresh.
- **Manual Loading:** `loadConversationFromHistory()` in QANotifier loads video via URL, then restores Q&A history in state.
- **Automatic Restoration:** `loadVideo()` checks `loadConversationByVideoId()` → if exists, restore history automatically. Preserves timestamps and video positions.
- **Initialization Pattern:** Use `ConsumerStatefulWidget` with `Future.microtask()` to initialize history after widget tree is ready, preventing race conditions.
- **Timestamp Accuracy:** Capture timestamp when question is asked (not when saved), ensuring historical data reflects actual Q&A time.
- **Position Accuracy:** Store video position at time of question (not current position), enabling accurate context restoration.
- **Debug Handling:** Wrap debug prints in `if (kDebugMode)` checks for production performance.

### Voice & Q/A Interaction (Updated)
- **Continuous Listening Mode:**
  - **Default:** OFF (User must manually enable).
  - **Auto-Enable:** Disabled (Headphone connection does *not* auto-trigger listening to prevent accidental activation).
  - **Icons:** Consistent "Ear" theme (`Icons.hearing` / `Icons.hearing_disabled`).
  - **UI:** Large Red/Green toggle button.
- **Headphone Requirement:**
  - **Dialog:** Simplified "Connect headset" message.
  - **Disclosure:** Progressive "Why?" button for detailed explanation to reduce cognitive load.
- **Auto-Speak Logic:**
  - **Startup:** Silent (Loading history does *not* trigger speech).
  - **Active Session:** Speaks only new answers generated during the session.

### Bottom Action Bar & Chat UI (Step 8 - Updated)
- **Decision:** Simplified bottom action bar with integrated chat UI
- **Why:** Reduces UI clutter by combining Ask and Chat into unified interface, maintains hands-free focus
- **Architecture:**
  - `BottomBarState` enum: collapsed, urlExpanded (askExpanded removed)
  - Two components: `BottomActionBar` (main), `UrlInputBar`, `ChatBottomSheet` (new)
  - State management via QANotifier: `setBottomBarState()`, `collapseBottomBar()`
- **Collapsed State (Default):** Two equal-width buttons:
  - **URL button:** Always enabled (even without video), expands to show input field + Go button + collapse (×)
  - **Chat button:** Disabled until video loads, opens chat bottom sheet with full conversation interface
- **Expanded States:**
  - **URL:** TextField + Go button + collapse button, auto-focus for immediate typing, disabled during loading
  - **Chat:** Full-screen bottom sheet (85% height, adjusts for keyboard) with conversation history + input at bottom
- **Chat Bottom Sheet Features:**
  - **History display:** Shows all Q&A from current session at top, auto-scrolls to latest message
  - **Input at bottom:** Text field + Send button + Mic button for voice input
  - **Keyboard handling:** Sheet height adjusts automatically to avoid keyboard blocking content (maxHeight = 85% - keyboardHeight)
  - **Continuous updates:** Auto-scrolls to show new messages after submission (300ms delay)
  - **Integrated voice input:** Microphone button directly in input row, triggers voice recognition and sends to LLM
- **Key Behavior Changes:**
  - Opening chat automatically stops continuous listening mode (prevents voice interference while typing)
  - Video pauses when chat opens (stays paused after close - user manually resumes)
  - No separate float button needed (redundant with Chat button)
- **Large Listening Toggle Button:**
  - Centered in main body with video player
  - 100dp circular Material with elevation 4
  - Icons: `Icons.hearing` (active) / `Icons.hearing_disabled` (off)
  - Text: "Listening" / "Off"
  - Color-coded states for instant visual feedback:
    - Green (Colors.green.shade600) when listening is ON
    - Red (Colors.red.shade600) when listening is OFF
    - Grey (Colors.grey.shade400) when disabled (no video)
  - Disabled with visual feedback until `isFullyInitialized` is true
- **Video Loading Feedback:**
  - Skeletonizer shimmer effect (16:9 aspect ratio) during `isLoadingVideo`
  - Hides TranscriptHeader until video fully loads
  - Smooth visual transition from loading to ready state
- **Empty State:** "Add YouTube URL to Start the Learning Journey" centered in body when no video
- **Session History:** Only accessible via Chat button (bottom sheet), removed from main body to reduce clutter
- **Video Pause Behavior:** When chat opens, video pauses and listening mode stops to prevent interference

### Development
- **Extract when painful:** Don't premature optimize.
- **Standard over clever:** Simple solutions are better.
- **Package versions:** Always verify dependency compatibility (e.g., youtube_player_iframe v5.2.2 requires webview ^4.x, not ^3.x).
- **Step-by-step approach:** Validate each iteration before building on it (hybrid approach for timestamps validated Q&A first).
- **Abstraction criteria:** Only abstract external services/libraries to enable provider switching and testing.

---

## Future Features

### Voice Enhancements
- ✅ Voice-first UI with text fallback (Complete)
- ✅ Auto-speak for voice questions (Complete)
- ✅ Continuous listening with grace period (Complete)
- ✅ Headphone detection & enforcement (Complete)
- ✅ Collapsible current session history drawer (Complete - 85% height bottom sheet)
- ✅ Lifecycle management (Complete - app background, resume dialog, state persistence)
- Wake word detection (deferred - adds friction to learning UX)
- Multi-language support

### History Enhancements
- Search conversations
- Export conversation as text/PDF
- Group by date (Today, Yesterday, Last Week)
- Cloud sync (requires auth)

### Context & Conversation
- Multi-turn conversations with context
- Reference previous questions
- Conversation summarization

### Authentication
- User accounts
- Cross-device sync
- Usage tracking
