# Learnova Design Manual

**Purpose:** Design decisions, architectural choices, and development guidelines.

---

## Project Overview

**Learnova** is a voice-first learning companion for YouTube videos.
**Core Value:** AI-powered Q&A based on video transcripts.
**Platform:** Flutter (iOS, Android, Web).

### Current Status
**Phase:** Step 3 - Video Player Integration (Complete)
- **Features:** YouTube URL loading, Transcript fetching with timestamps, Video playback, Position-aware Q&A, GPT-4o-mini Q&A.
- **Pending:** Voice I/O, Auth, Persistence, History management.

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

### 4. Result Pattern for Error Handling
**Decision:** Return `Result<Success, Failure>` instead of throwing exceptions.
**Why:** Explicit error handling, fail-fast principle.

---

## Technology Stack

| Tech | Purpose | Why |
|------|---------|-----|
| **Flutter** | UI | Cross-platform |
| **Riverpod** | State/DI | Testable, scalable, compile-time safety |
| **GoRouter** | Routing | Type-safe, deep linking |
| **OpenAI** | LLM | GPT-4o-mini (Cost-effective: ~$0.0001/q) |
| **youtube_player_iframe** | Video Player | Official iFrame API, cross-platform |

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
- **Mocking:** Mock external dependencies (API, DB).

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
- **Decision:** Use `youtube_player_iframe` package for video playback with position tracking.
- **Why:** Actively maintained (updated Aug 2025), official YouTube iFrame API, works cross-platform, no API key required.
- **Architecture:** VideoPlayer widget → updates QANotifier.currentPosition → QANotifier filters transcript on askQuestion.
- **Smart Threshold:** Use full transcript for first 10 seconds (avoid empty context), then switch to position-aware filtering.
- **State Design:** Store full `VideoInfo` object in state, use computed getters (videoTitle, videoId) for backward compatibility.

### Prompt Engineering
- **Strategy:** Position-aware transcript + Question -> GPT-4o-mini.
- **Constraint:** Limit answers to 2-3 sentences to control cost/hallucination.
- **Context Filtering:** After 10s of playback, only send transcript up to current video position via `getTranscriptUpTo()`.

### Development
- **Extract when painful:** Don't premature optimize.
- **Standard over clever:** Simple solutions are better.
