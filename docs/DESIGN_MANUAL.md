# Learnova Design Manual

**Purpose:** Design decisions, architectural choices, and development guidelines.

---

## Project Overview

**Learnova** is a voice-first learning companion for YouTube videos.
**Core Value:** AI-powered Q&A based on video transcripts.
**Platform:** Flutter (iOS, Android, Web).

### Current Status
**Phase:** Step 2.5 - Timestamp-Aware Transcripts (Complete)
- **Features:** YouTube URL loading, Transcript fetching with timestamps, Context-aware Q&A foundation, GPT-4o-mini Q&A.
- **Pending:** Video player integration, Voice I/O, Auth, Persistence.

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
- **Decision:** Parse and store transcript segments with timestamps from YouTube XML, but send full transcript to LLM for now.
- **Why:** Validates core Q&A value quickly while preserving timestamp data for future video-position-aware features.
- **Structure:** `TranscriptSegment{text, start, duration}` → `VideoInfo.getFullTranscript()` (current) / `getTranscriptUpTo(position)` (future).
- **Use Case:** When video player tracking is added, questions like "summarize what I've learned so far" will only send watched content to LLM.
- **Benefit:** No rework needed later—data is already captured.

### Prompt Engineering
- **Strategy:** Full transcript + Question -> GPT-4o-mini.
- **Constraint:** Limit answers to 2-3 sentences to control cost/hallucination.
- **Future:** Context will be filtered by video position using `getTranscriptUpTo()`.

### Development
- **Extract when painful:** Don't premature optimize.
- **Standard over clever:** Simple solutions are better.
