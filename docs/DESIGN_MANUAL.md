# Learnova Design Manual

**Purpose:** Design decisions, architectural choices, and development guidelines.

---

## 1. Architecture Philosophy

### Feature-Based Organization
- **Decision:** Organize by features (e.g., `features/qa`, `features/history`).
- **Why:** Scalability, clear boundaries, independent deployment.

### Service-Based Communication
- **Decision:** Features communicate **only** through services.
- **Pattern:** `Feature A -> Feature B Service -> Feature B Logic`
- **Why:** Decouples logic from UI, prevents circular dependencies.

### Provider Abstractions
- **LLM**: Abstracted via `LLMService` to prevent vendor lock-in (OpenAI <-> Gemini).
- **Voice**: `VoiceService` coordinates `STTService` (Speech-to-Text) and `TTSService` (Text-to-Speech) interfaces.
- **Storage**: Abstracted via `Repository` pattern (e.g., `HistoryRepository`) to allow `Hive` swap-outs.

### Result Pattern
- **Decision:** Return `Result<Success, Failure>` instead of throwing exceptions.
- **Why:** Explicit error handling, fail-fast principle.

### Screen Coordinator Pattern
- **Decision:** Use a dedicated `StateNotifier` coordinator when a screen needs to coordinate multiple providers (e.g., Video + QA + Voice).
- **Structure:** `Screen` (UI) watches `Coordinator` (State) which listens to `FeatureNotifiers`.
- **Example:** `QAScreenCoordinator` syncs video playback with voice state and handles app lifecycle.
- **When to Use:** Complex cross-feature logic or screen code > 150 lines.

---

## 2. Core Design Decisions

### Video & Transcripts
- **YouTube API**: Direct Innertube API (Stability/Control) instead of `youtube_explode_dart`.
- **Hybrid Timestamps**: Parse/store transcript segments with timestamps to enable **position-aware Q&A**.
- **Context Filtering**: After 10s of playback, questions only consider content watched *so far* (`getTranscriptUpTo(position)`).

### Voice Experience (Hands-Free)
- **Voice-First Strategy**: 
    - Voice input -> Auto-speaks answer.
    - Text input -> Silent answer (respects environment).
- **Input Method**: `InputMethod.voice` vs `InputMethod.text` tracked in state triggers selective TTS.
- **Continuous Mode**:
    - **Logic**: Listen -> Silence (detect) -> Process -> Speak -> Grace Period -> Resume.
    - **Headphones Required**: MVP decision to prevent audio feedback loop. Strict enforcement via `AudioDeviceService`.
    - **Silence Detection**: Configurable `pauseFor` parameter (3s for one-off, 5s for continuous).
    - **Video Sync**: Video pauses immediately when user speaks or TTS speaks. Resumes after grace period (if it was playing).
    - **Grace Period**: 5-second buffer after TTS finishes before resuming listening, allowing for follow-up questions.
    - **Safety**: 
        - Auto-stop on App Background/Pause.
        - Auto-stop on Headphone disconnect.
        - 5-minute inactivity timeout.
    - **Error Recovery**: STT failure auto-retries after 2s delay.

### Persistence (History)
- **Separation**: History is a standalone feature (`features/history`), not coupled to QA logic.
- **Storage**: `Hive` used for local persistence (fast, NoSQL).
- **Auto-Save**: Conversation saved after every Q&A pair.
- **Smart Restore**: Pasting a URL checks for existing history and restores it automatically.

### UI Architecture
- **Unified Bottom Bar**: 
    - **Collapsed**: Simple actions (URL input, Chat).
    - **Chat Sheet**: Full-screen bottom sheet (85% height) for conversation history.
- **Listening Toggle**: Large, color-coded central button (Green=On, Red=Off, Gray=Disabled).
- **Visual Feedback**: Pulse animations for listening state; Skeletonizer for loading.

---

## 3. Technology Stack

| Tech | Purpose | Why |
|------|---------|-----|
| **Flutter**| UI | Cross-platform, fast rendering |
| **Riverpod**| State/DI | Compile-time safety, testability |
| **GoRouter**| Routing | Deep linking, type-safety |
| **OpenAI**| LLM | GPT-4o-mini (Cost-effective: ~$0.0001/q) |
| **youtube_player_iframe**| Video | Official iFrame API (v5.2.2 requires webview ^4.x/^3.x) |
| **speech_to_text**| STT | Native platform APIs, offline support |
| **flutter_tts**| TTS | Native platform voices, no cost |
| **Hive**| Storage | Fast, zero-setup NoSQL, cross-platform |

**Configuration**: API Keys managed via `--dart-define` for security.

---

## 4. Refactoring & Standards

### Widget Extraction
- **Rule**: Extract if `build()` > 50 lines or needs local state.
- **Pattern**: Widgets access data via `ref.read/watch`. **Avoid callback drilling**.

### Testing Strategy
- **Focus**: Practical testing.
- **Unit Tests**: Business logic, Services, Repositories.
- **Manual Verification**: UI/Widgets (for MVP speed).
- **Mocking**: Manual mocks preferred over heavy mocking libraries.

---

## 5. Development Guidelines (See `AI_ASSISTANT_GUIDE.md` for details)
- **Principle**: Practical solutions over theoretical perfection.
- **Code**: Simple, readable, fail-fast.
- **Process**: Plan -> Implement -> Verify.
