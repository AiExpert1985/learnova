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
    qa/                      # Question & Answer feature
      models/                # Data models specific to Q&A
      services/              # Business logic
      screens/               # UI screens
      widgets/               # Reusable UI components
  core/
    services/                # Shared services (external APIs)
    constants/               # App-wide constants
  main.dart
```

**Why:**
- Each feature is self-contained
- Easy to locate feature-specific code
- Clear boundaries between features
- Scales well as app grows

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

#### 1. OpenAI Service Abstraction

**Decision:** Abstract OpenAI API behind an interface (`OpenAIService`)

**Why:**
- External service dependency (guideline: abstract external services)
- Enables testing without API calls
- Allows switching providers later if needed
- Clear separation of concerns

**Implementation:**
```dart
// Abstract interface
abstract class OpenAIService {
  Future<String> askQuestion(String context, String question);
}

// Concrete implementation
class OpenAIServiceImpl implements OpenAIService {
  // HTTP implementation details
}
```

**Trade-offs:**
- ✅ Testability (can mock easily)
- ✅ Flexibility (swap providers)
- ⚠️ Slight overhead (one extra class)

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

**Decision:** Constructor injection, manual wiring in `main.dart`

**Why:**
- Simple and explicit
- No framework overhead
- Follows DI guideline without premature complexity

**Example:**
```dart
final openAIService = OpenAIServiceImpl(apiKey: apiKey);
final qaService = QAService(openAIService: openAIService);
final screen = QAScreen(qaService: qaService);
```

---

#### 6. State Management

**Decision:** Use `StatefulWidget` with simple `setState` for now

**Why:**
- Built-in, zero dependencies
- Sufficient for single-screen MVP
- Avoid premature abstraction

**When to revisit:**
- Multi-screen state sharing
- Complex state logic
- Performance issues

---

### Testable Units

Following "testable by design" principle, these units are ready for testing:

1. **OpenAIServiceImpl**
   - Edge cases: API timeout, invalid API key, malformed response, network error

2. **QAService**
   - Edge cases: Empty question, null transcript, OpenAI error propagation

3. **Prompt construction**
   - Edge cases: Very long transcript, special characters, empty context

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
