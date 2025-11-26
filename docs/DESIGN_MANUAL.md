# Learnova Design Manual

This document records design decisions, architectural choices, and learnings from building Learnova.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Step 1: Basic Q&A with Fake Transcript](#step-1-basic-qa-with-fake-transcript)

---

## Architecture Overview

### Feature-Based Structure

Following the development guidelines, the codebase is organized by features rather than technical layers:

```
lib/
  features/
    qa/                           # Question & Answer feature
      models/                     # Data models (Question, Answer, QAResult)
      services/                   # Business logic (QAService)
      screens/                    # UI screens (QAScreen)
  core/
    providers/                    # Riverpod DI providers
      app_providers.dart          # Service providers
    routes/                       # GoRouter configuration
      app_router.dart             # Route definitions and guards
    services/                     # Shared services
      llm/                        # LLM abstraction layer
        llm_service.dart          # Provider-agnostic interface
        openai_llm_service.dart   # OpenAI implementation
      config_service.dart         # Config file reader
    constants/                    # App-wide constants
      mock_data.dart              # Test data
  main.dart                       # App entry point

test/
  core/services/                  # Service unit tests
  features/qa/services/           # Feature unit tests
```

**Why:**
- Each feature is self-contained
- Easy to locate feature-specific code
- Clear boundaries between features
- Provider-agnostic LLM layer (swap OpenAI/Gemini/Claude easily)
- Tests mirror source structure

### State Management & Routing

**Stack:**
- **Riverpod** for dependency injection and state management
- **GoRouter** for declarative routing

**Structure:**
```
lib/
  core/
    providers/
      app_providers.dart     # DI providers (services)
    routes/
      app_router.dart        # GoRouter configuration
```

**Why Riverpod:**
- ✅ Modern, recommended by Flutter team
- ✅ Compile-time safety (no runtime lookup errors)
- ✅ Built-in dependency injection
- ✅ Testability (easy mocking)
- ✅ Scales from simple to complex state

**Why GoRouter:**
- ✅ Declarative routing (easier to reason about)
- ✅ Type-safe navigation
- ✅ Built-in deep linking support
- ✅ Route guards (for auth later)
- ✅ Web URL support

**Trade-offs:**
- ⚠️ Added complexity vs manual DI
- ✅ Pays off as app grows (multiple screens, shared state)

**When added:** After Step 1, before Step 2 - to avoid refactoring pain when adding multiple screens (history, subscription, etc.)

---

## Step 1: Basic Q&A with Fake Transcript

**Goal:** Validate core value proposition - can AI provide good answers from video transcript context?

**Scope:**
- Hardcoded transcript (2-3 minutes from a real YouTube video)
- Text-based Q&A (no voice yet)
- OpenAI GPT-4 mini integration
- Basic error handling

**Out of scope:**
- YouTube integration
- Voice input/output
- Authentication
- State persistence

---

### Design Decisions

#### 1. LLM Service Abstraction

**Decision:** Abstract LLM providers behind a provider-agnostic interface (`LLMService`)

**Why:**
- External service dependency (guideline: abstract external services)
- Enables testing without API calls
- Allows switching between OpenAI, Gemini, Claude, etc.
- Clear separation of concerns
- Name reflects generic purpose, not specific provider

**Implementation:**
```dart
// Provider-agnostic interface
abstract class LLMService {
  Future<LLMResponse> askQuestion({
    required String context,
    required String question,
  });
}

// OpenAI implementation
class OpenAILLMService implements LLMService {
  // OpenAI HTTP implementation
}

// Future: Other implementations
// class GeminiLLMService implements LLMService { ... }
// class ClaudeLLMService implements LLMService { ... }
```

**Switching providers:**
```dart
// In app_providers.dart, just change one line:
final llmServiceProvider = Provider<LLMService>((ref) {
  return OpenAILLMService(apiKey: apiKey);  // Current
  // return GeminiLLMService(apiKey: apiKey);  // Future
});
```

**Trade-offs:**
- ✅ Testability (can mock easily)
- ✅ Flexibility (swap providers in one place)
- ✅ Provider independence
- ⚠️ Slight overhead (interface + implementation)

---

#### 2. Model Structure

**Decision:** Use simple data classes for Question, Answer, and QAResult

**Models:**
- `Question`: User's text input
- `Answer`: AI response with metadata
- `QAResult`: Wraps success/error state

**Why:**
- Type-safe data flow
- Clear API contracts
- Easier error handling

---

#### 3. Error Handling Strategy

**Decision:** Use `Result` pattern (success/failure) rather than throwing exceptions

**Why:**
- Explicit error handling (fail fast principle)
- Forces UI to handle errors
- Junior-readable error states

**Implementation:**
```dart
class QAResult {
  final Answer? answer;
  final String? error;
  final bool isSuccess;
}
```

---

#### 4. Prompt Engineering

**Decision:** Send full transcript + question in a structured prompt

**Prompt template:**
```
You are a learning assistant. Answer the user's question based on the video transcript provided.

Transcript:
[TRANSCRIPT_CONTENT]

Question: [USER_QUESTION]

Provide a clear, concise answer (2-3 sentences). If the answer isn't in the transcript, say "I don't have enough information from this video to answer that."
```

**Why:**
- Clear instructions reduce hallucination
- Bounded responses (2-3 sentences) control cost and latency
- Explicit handling of unanswerable questions

**To measure:**
- Response quality (manual testing)
- Response time
- Token usage / cost per question

---

#### 5. Dependency Injection

**Decision:** Riverpod providers for dependency injection

**Why:**
- Compile-time safety (no runtime errors)
- Easy mocking for tests
- Clean service lifecycle management
- Scales to complex apps

**Implementation:**
```dart
// Define providers
final llmServiceProvider = Provider<LLMService>((ref) {
  return OpenAILLMService(apiKey: ref.watch(apiKeyProvider));
});

final qaServiceProvider = Provider<QAService>((ref) {
  return QAService(llmService: ref.watch(llmServiceProvider));
});

// Consume in widgets
class QAScreen extends ConsumerStatefulWidget {
  Widget build(BuildContext context) {
    final qaService = ref.read(qaServiceProvider);
    // ...
  }
}
```

**Switching LLM providers:**
```dart
// Just change the provider implementation
final llmServiceProvider = Provider<LLMService>((ref) {
  return GeminiLLMService(apiKey: ref.watch(geminiKeyProvider));
});
```

---

#### 6. State Management

**Decision:** Riverpod for DI, `setState` for local UI state

**Why:**
- Riverpod handles service lifecycle and injection
- `setState` sufficient for simple UI state (loading, form inputs)
- Separation of concerns: services via providers, UI state locally
- Can add StateNotifierProvider later for complex shared state

---

### Testing Strategy

**Philosophy:** Practical testing over test perfection. Avoid over-engineering.

**Current Focus:** Unit tests for business logic

Following "testable by design" principle, we focus on testing what matters:
- ✅ Business logic (services, models)
- ✅ Edge cases and error handling
- ✅ External API integration
- ❌ NOT widget tests (slow, brittle, low ROI at this stage)
- ❌ NOT 100% coverage (diminishing returns)

**Test Coverage:**

1. **QAService** (`test/features/qa/services/qa_service_test.dart`)
   - ✅ Valid question and transcript → success
   - ✅ Empty question → validation error
   - ✅ Empty transcript → validation error
   - ✅ LLM exception handling
   - ✅ Unexpected exception handling

2. **OpenAILLMService** (`test/core/services/openai_llm_service_test.dart`)
   - ✅ Successful API call → correct parsing
   - ✅ Empty API key → exception
   - ✅ 401 Unauthorized → invalid key error
   - ✅ 429 Rate limit → rate limit error
   - ✅ Request body construction (model, tokens, temperature)

**Total:** 10 unit tests covering critical business logic

**Running Tests:**
```bash
flutter test test/core test/features
```

**Test Design Principles:**
- Mock external dependencies (LLM service, HTTP client)
- Test business logic in isolation
- Clear arrange-act-assert structure
- Test edge cases and error paths
- Fast execution (< 5 seconds total)

**What We Don't Test (Intentionally):**
- **Widget tests** - Slow, brittle, test framework more than app logic. Manual testing on devices is more valuable.
- **UI interactions** - Better tested manually on real devices
- **GoRouter navigation** - Complex to test, low failure risk
- **Riverpod providers** - Simple wiring, low risk

**Future Testing (When Needed):**
- **Integration tests** - Add when critical user flows need end-to-end validation
- **Golden tests** - Add if UI consistency becomes an issue
- When to add: When manual testing becomes painful or bugs slip through

---

### Implementation Checklist

#### Before Testing
- [ ] Run `flutter pub get` to install dependencies
- [ ] Run `flutter analyze` to check for issues
- [ ] Verify app compiles without errors
- [ ] Set up OpenAI API key in launch configuration

#### Testing Checklist
- [ ] App launches without crashes
- [ ] API key missing screen displays if no key provided
- [ ] Q&A screen loads with transcript header
- [ ] Can type and submit questions
- [ ] Loading indicator shows during API call
- [ ] Answers display correctly
- [ ] Token count shows for each answer
- [ ] Error messages display for API failures
- [ ] Can ask multiple questions in sequence
- [ ] Scroll works correctly with multiple Q&A entries

### Learnings (To be filled after implementation)

#### Response Quality
- [ ] Test with 10 questions
- [ ] Document hallucination frequency
- [ ] Note ideal transcript length
- [ ] Rate answer accuracy (1-5 scale)

#### API Performance
- [ ] Average response time: ____ ms
- [ ] Token usage per question: ____ tokens
- [ ] Actual cost per question: $____
- [ ] Any timeout issues?

#### Error Patterns
- [ ] Most common errors encountered
- [ ] User experience during failures
- [ ] Network reliability

#### Prompt Effectiveness
- [ ] Does the 2-3 sentence limit work?
- [ ] Hallucination rate: ___%
- [ ] Quality of "I don't know" responses

---

### Next Steps After Step 1

1. Document learnings from manual testing
2. Adjust prompt based on quality findings
3. Move to Step 2: YouTube transcript integration

---

## Step 2: YouTube Transcript Integration

_To be documented when Step 1 is complete_

---
