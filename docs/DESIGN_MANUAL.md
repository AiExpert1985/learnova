# Learnova Design Manual

**Purpose:** Design decisions, architectural choices, and development guidelines.

---

## Project Overview

**Learnova** is a voice-first learning companion for YouTube videos.
**Core Value:** AI-powered Q&A based on video transcripts.
**Platform:** Flutter (iOS, Android, Web).

### Current Status
**Phase:** Step 6 - Continuous Listening Mode (Complete)
- **Features:** YouTube URL loading, Transcript fetching with timestamps, Video playback, Position-aware Q&A, GPT-4o-mini Q&A, Voice input (STT), Voice output (TTS), Continuous hands-free listening (headphones-only MVP), Auto-save conversations, History retrieval, Auto-restore previous conversations, Clear all history.
- **Pending:** Auth, Multi-turn conversation context, Video auto-pause option.

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
- **Video Integration:** Video pauses automatically when voice input starts, resumes when stopped
- **Provider Pattern:** Voice controller exposed via `youtubeControllerProvider` for cross-widget coordination
- **Future Upgrades:** Easy to swap to cloud providers (Google Cloud STT/TTS, ElevenLabs) by implementing interfaces

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

### Development
- **Extract when painful:** Don't premature optimize.
- **Standard over clever:** Simple solutions are better.
- **Package versions:** Always verify dependency compatibility (e.g., youtube_player_iframe v5.2.2 requires webview ^4.x, not ^3.x).
- **Step-by-step approach:** Validate each iteration before building on it (hybrid approach for timestamps validated Q&A first).
- **Abstraction criteria:** Only abstract external services/libraries to enable provider switching and testing.

---

## Future Features

### Voice Enhancements
- ✅ Continuous listening mode (Complete - headphones-only MVP)
- Video auto-pause option for speaker mode (Phase 2 - post-MVP)
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
