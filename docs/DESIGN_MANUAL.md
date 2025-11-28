# Learnova Design Manual

**Purpose:** Design decisions, architectural choices, and development guidelines for building Learnova.

**Audience:** Development team and AI assistants working on this project.

---

## Project Overview

**Learnova** is a voice-first learning companion app for YouTube videos.

**Core Value Proposition:** Users can ask questions about YouTube video content and receive AI-powered answers based on video transcripts, enhancing comprehension and learning efficiency.

**Target Platform:** Flutter (iOS, Android, Web)

---

## Current Status

**Phase:** Step 2 - YouTube Integration (Complete)

**Current Features:**
- YouTube URL input and video loading
- Real-time transcript fetching via Innertube API
- Text-based Q&A on any YouTube video with captions
- OpenAI GPT-4o-mini integration
- Error handling and token tracking
- API key configuration via environment variables
- StateNotifier-based state management

**Not Yet Implemented:**
- Voice input/output
- User authentication
- State persistence (save Q&A history)
- Subscription management
- Video history/favorites

---

## Architecture Philosophy

### 1. Feature-Based Organization

**Decision:** Organize codebase by features, not technical layers (no MVC/layered architecture).

**Why:**
- Each feature is self-contained and independently deployable
- Easy to locate feature-specific code
- Clear boundaries between features
- Scales better as app grows
- New team members can understand features in isolation

**Structure:**
```
lib/
  features/          # Feature-based modules
    qa/              # Question & Answer feature
      models/        # Feature-specific data models
      services/      # Feature-specific business logic
      screens/       # Feature UI screens
      widgets/       # Feature UI components
  core/              # Shared infrastructure
    providers/       # Dependency injection providers
    routes/          # App-wide routing
    services/        # Shared services (LLM, config, etc.)
    screens/         # Shared screens (error, loading, etc.)
    constants/       # App-wide constants
```

### 2. Provider-Agnostic LLM Abstraction

**Decision:** Abstract LLM providers behind generic `LLMService` interface.

**Why:**
- Avoid vendor lock-in (can switch from OpenAI to Gemini/Claude/etc.)
- Enable testing without actual API calls
- Single point of change for switching providers
- Clear separation between business logic and external dependencies

**Implementation Pattern:**
- Generic interface: `LLMService`
- Provider implementations: `OpenAILLMService`, `GeminiLLMService`, etc.
- Dependency injection: Swap providers in one location

### 3. Result Pattern for Error Handling

**Decision:** Use Result pattern (success/failure) instead of throwing exceptions.

**Why:**
- Explicit error handling (fail-fast principle)
- Forces UI to handle all error states
- More readable for junior developers
- Clear distinction between business logic errors and system errors

**Pattern:**
- `QAResult` wraps `Answer?` or `error` message
- Services return results, never throw exceptions
- UI explicitly checks `isSuccess` before proceeding

---

## Technology Stack

### Core Technologies

| Technology | Purpose | Why Chosen |
|------------|---------|------------|
| **Flutter** | Cross-platform UI | Single codebase for iOS/Android/Web |
| **Dart** | Programming language | Type-safe, modern, Flutter-native |
| **Riverpod** | Dependency injection & state management | Compile-time safety, testability, scales well |
| **GoRouter** | Declarative routing | Type-safe navigation, deep linking, route guards |
| **OpenAI API** | LLM provider (current) | GPT-4o-mini for cost-effective Q&A |

### Why Riverpod + GoRouter?

**Decision:** Add Riverpod and GoRouter from the start, even for MVP.

**Why:**
- Avoids painful refactoring when adding multiple screens in Step 2+
- Team already familiar with both technologies
- Pays off as app scales (subscription screen, history, settings, etc.)
- Minimal overhead for single-screen MVP

**Trade-off:**
- ⚠️ Slight complexity increase for MVP
- ✅ Prevents major refactoring later

### StateNotifier Pattern (No Callbacks)

**Decision:** Use StateNotifier for feature state, widgets call notifiers directly.

**Why:**
- More intuitive than callback drilling
- Business logic centralized in notifier (single source of truth)
- Widgets call actions directly: `ref.read(notifier).method()`
- Cleaner code, easier to understand
- Ready for multi-screen state sharing

**Pattern:**
```dart
// Widget calls notifier directly
ref.read(qaNotifierProvider.notifier).loadVideo(url);

// Notifier handles all logic
class QANotifier extends StateNotifier<QAState> {
  Future<void> loadVideo(String url) async {
    state = state.copyWith(isLoading: true);
    // Fetch video, update state
  }
}
```

**Avoid:** Callback drilling (passing VoidCallback through widget tree)

---

## Code Organization Principles

### 1. Screens in Separate Files
- UI components don't live in router/config files
- Each screen = one file in appropriate directory
- Example: `ApiKeyMissingScreen` in `core/screens/`, not embedded in `app_router.dart`

### 2. Use Existing Getters/Methods
- Don't recreate logic that already exists
- Use `ConfigService.hasApiKey` not `ConfigService.apiKey.isEmpty`
- Benefits: Single source of truth, clearer intent, easier refactoring

### 3. Self-Documenting Code
- Name things for **what** they check/do, not **how** they do it
- `hasApiKey` reads better than `apiKey.isEmpty`
- Reduces need for comments

### 4. Break Large Files into Smaller Components
- Screen files: ~100-150 lines max
- Widget files: ~30-60 lines each
- Extract reusable widgets to `widgets/` directory
- Extract feature-specific models to `models/` directory

**When to extract:**
- File exceeds ~150 lines
- Widget has independent reuse potential
- Logic can be isolated and tested separately

**When NOT to extract:**
- Widget is < 20 lines
- Only used once with tight coupling to parent
- Extraction creates more complexity than it solves

**Example:** `qa_screen.dart` refactored from 261 → 120 lines by extracting:
- `QAHistoryEntry` model
- `TranscriptHeader`, `QABubble`, `QuestionInput` widgets
- Result: Main screen focuses on state management

---

## Testing Philosophy

**Guiding Principle:** Practical testing over test perfection. Avoid over-engineering.

### What We Test ✅
- **Business logic:** Services, models with logic
- **Edge cases:** Empty inputs, validation failures
- **Error handling:** API failures, network errors
- **External integrations:** OpenAI API behavior

### What We Don't Test ❌
- **Widget tests:** Slow, brittle, low ROI - manual device testing more valuable
- **UI interactions:** Better tested manually
- **Simple data classes:** Testing trivial getters tests the language, not our code
- **Router/Provider wiring:** Low risk, complex to test

### Current Test Coverage
- **10 unit tests** covering critical business logic
- QAService: 5 tests (validation, error handling)
- OpenAILLMService: 5 tests (API integration, error codes)
- Tests run in < 5 seconds

### Test Design Principles
- Mock external dependencies (HTTP, LLM services)
- Test business logic in isolation
- Clear arrange-act-assert structure
- Test mirror source structure (`test/` matches `lib/`)

### When to Add More Tests
- Integration tests: When critical user flows need end-to-end validation
- Golden tests: If UI consistency becomes a problem
- Widget tests: Only if manual testing becomes painful

---

## Configuration Management

**Decision:** Use Flutter's standard `--dart-define` for environment variables.

**Why:**
- Standard Flutter approach (no tricks)
- Works consistently across all platforms (Windows, Android, iOS)
- Compile-time configuration (no runtime file reading)
- No platform-specific sandboxing issues

**What We Tried:**
- ❌ Config file (config.json) - Android sandboxing prevents file access
- ❌ Hybrid approach (file + environment) - Two methods for one problem
- ✅ Single standard method: `--dart-define` only

**Implementation:**
- API keys passed via `--dart-define OPENAI_API_KEY=xxx`
- ConfigService reads from `String.fromEnvironment()`
- Route guards check API key presence before rendering Q&A screen

---

## Key Design Decisions

### 1. Prompt Engineering

**Current Strategy:**
- Send full transcript + user question to LLM
- Instruct model to answer in 2-3 sentences
- Explicitly handle "I don't know" scenarios
- GPT-4o-mini model for cost optimization

**Why:**
- Clear instructions reduce hallucination
- Bounded responses control cost and latency
- Explicit boundaries prevent over-answering

**Metrics to Watch:**
- Response quality (manual evaluation)
- Token usage per question (~300-500 tokens typical)
- Cost per question (~$0.0001 with GPT-4o-mini)

### 2. State Management Approach

**Decision:** Use StateNotifier for feature state management, not callbacks.

**Why:**
- Centralizes business logic in one place (notifier)
- Widgets call notifiers directly via `ref.read(notifier).method()`
- No callback drilling through widget trees
- More intuitive: UI calls actions, notifier manages state
- Ready for future expansion (shared state, complex flows)

**Pattern:**
```dart
// State
class FeatureState {
  final List<Data> items;
  final bool isLoading;
}

// Notifier
class FeatureNotifier extends StateNotifier<FeatureState> {
  void performAction(params) {
    // Business logic here
    state = state.copyWith(...);
  }
}

// Widget calls directly
ref.read(featureNotifier.notifier).performAction(params);
```

**When NOT to use StateNotifier:**
- Simple forms with no business logic
- One-off UI animations or transitions
- Widget-local state (expanded/collapsed, selected index)

### 3. Service Layer Separation

**Pattern:** Three-layer separation
1. **UI Layer:** Widgets and screens (presentation)
2. **Service Layer:** Business logic (QAService)
3. **Integration Layer:** External dependencies (OpenAILLMService)

**Why:**
- UI doesn't know about OpenAI (only generic LLMService)
- Business logic isolated from API details
- Each layer testable independently
- Easy to swap implementations

---

## Development Roadmap

### Step 1: Basic Q&A with Fake Transcript ✅ **Complete**

**Goal:** Validate that AI can provide good answers from transcript context.

**Achievements:**
- Hardcoded transcript (2-3 minute video)
- Text-based Q&A working
- Error handling implemented
- Token tracking functional
- Cost metrics established (~$0.0001/question)

**Key Learnings:**
- GPT-4o-mini provides good quality at low cost
- 2-3 sentence limit works well
- Model handles "I don't know" appropriately
- Token usage reasonable (~300-500 per question)

### Step 2: YouTube Transcript Integration ✅ **Complete**

**Goal:** Fetch transcripts from any YouTube video with captions.

**Achievements:**
- YouTube Innertube API integration (no API key needed)
- WEB client for maximum reliability
- Video metadata extraction (title, duration)
- Caption track selection (prioritizes manual English > auto English > any language)
- HTML entity decoding in transcripts
- Comprehensive error handling

**Critical Decision: Innertube API over youtube_explode_dart**

**Why we switched:**
- `youtube_explode_dart` had XmlParserException on many videos
- Library-based solutions are fragile (depend on third-party maintenance)
- Innertube API is YouTube's internal API (more stable)
- Direct HTTP implementation gives us full control
- No external library dependency

**Implementation:**
- Endpoint: `https://www.youtube.com/youtubei/v1/player`
- Client: WEB (more reliable than ANDROID for transcripts)
- Simple regex for XML text extraction (avoids parser complexity)
- ~250 lines of clean, maintainable code

**Key Learnings:**
- WEB client (clientName: 'WEB') more stable than ANDROID for transcripts
- ANDROID client requires integrity checks, prone to 400 errors
- User-Agent header important for request legitimacy
- Regex-based XML parsing simpler and more reliable than XML parsers
- Direct API implementation > third-party libraries for critical features

### Step 3+: Voice & Advanced Features 🔮 **Future**

- Voice input (speech-to-text)
- Voice output (text-to-speech)
- User authentication
- State persistence (save Q&A history)
- Subscription management
- Video timestamp linking
- Follow-up question suggestions

---

## Critical Learnings

### Configuration
- ✅ **Standard approaches > clever tricks**
- Android emulator can't access host filesystem
- `--dart-define` works reliably across all platforms
- One simple method beats multiple complex methods

### Testing
- ✅ **Widget tests not needed for production apps at MVP stage**
- Manual device testing provides better ROI
- Focus unit tests on business logic, not UI
- 10 well-designed tests > 100 shallow tests

### Cost Optimization
- ✅ **GPT-4o-mini is 100x cheaper than estimated**
- Actual cost: ~$0.0001 per question
- Token usage: ~300-500 tokens typical
- 2-3 sentence limit keeps costs predictable

### Code Organization
- ✅ **Extract when you feel pain, not before**
- Don't over-engineer for hypothetical future needs
- 100-150 line screens are manageable
- Extract when files exceed ~150 lines or widgets are reusable

### Architecture
- ✅ **Feature-based > layered architecture**
- Provider abstraction was correct decision
- Riverpod/GoRouter worth adding early (team already knows them)
- Result pattern makes error handling explicit

### YouTube Integration
- ✅ **Direct API implementation > third-party libraries**
- YouTube Innertube API is reliable (YouTube's own internal API)
- WEB client more stable than ANDROID for transcript fetching
- Simple regex parsing > complex XML parsers
- No API key needed, no quota limits
- Direct control over requests and error handling
