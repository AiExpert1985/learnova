# Learnova Setup Guide

Quick guide to get Learnova running locally.

---

## Quick Start

```bash
# 1. Get an OpenAI API key from https://platform.openai.com/api-keys
# 2. Clone and install dependencies
flutter pub get

# 3. Run the app
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

That's it! You should see the Q&A screen with a sample video transcript.

---

## Prerequisites

| Requirement | Version | Notes |
|------------|---------|-------|
| **Flutter SDK** | 3.8.1+ | Download from [flutter.dev](https://flutter.dev) |
| **OpenAI API Key** | - | Free tier works fine (~$0.0001 per question) |

---

## Getting an OpenAI API Key

1. Visit https://platform.openai.com/api-keys
2. Sign in (or create account - free tier available)
3. Click **"Create new secret key"**
4. Copy the key immediately (you won't see it again)

**Cost:** ~$0.0001 per question with GPT-4o-mini (~300-500 tokens per Q&A)

---

## Configuration Approach

**Method:** Use `--dart-define` to pass API keys at compile time.

**Why this method:**
- ✅ Standard Flutter approach (official, no tricks)
- ✅ Works reliably on all platforms (Windows, Android, iOS, etc.)
- ✅ No runtime file reading (no Android sandboxing issues)
- ✅ Compile-time safety

---

## Running the App

### Development

**Any platform:**
```bash
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

**Specific platforms:**
```bash
# Desktop
flutter run -d windows --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d macos --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d linux --dart-define=OPENAI_API_KEY=your-key-here

# Mobile
flutter run -d android --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d ios --dart-define=OPENAI_API_KEY=your-key-here

# Web
flutter run -d chrome --dart-define=OPENAI_API_KEY=your-key-here
```

### Production Builds

```bash
# Android
flutter build apk --dart-define=OPENAI_API_KEY=your-key-here
flutter build appbundle --dart-define=OPENAI_API_KEY=your-key-here

# iOS
flutter build ios --dart-define=OPENAI_API_KEY=your-key-here

# Web
flutter build web --dart-define=OPENAI_API_KEY=your-key-here
```

---

## Convenient IDE Setup (Optional)

### VS Code

Create `.vscode/launch.json` in project root:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Learnova",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=OPENAI_API_KEY=your-key-here"
      ]
    }
  ]
}
```

**Then:** Press `F5` to run with API key automatically.

**Important:** Add `.vscode/` to `.gitignore` to avoid committing your API key.

### Android Studio / IntelliJ

1. Edit Run Configuration
2. Add to **Additional run args:** `--dart-define=OPENAI_API_KEY=your-key-here`
3. Apply and run

---

## Testing Step 1 MVP

The app currently uses a hardcoded transcript about learning strategies.

### What You'll See
1. Q&A screen with video title and duration
2. Sample transcript header (2-3 minute video)
3. Input field to ask questions
4. AI answers based on transcript context
5. Token usage displayed with each answer

### Sample Questions
Try these to test the AI:
- "What is spaced repetition?"
- "How many learning principles are mentioned?"
- "What's the difference between active recall and passive reading?"
- "Why is interleaving important?"
- "What is the main idea of this video?"

### Expected Behavior
- ✅ Answers in 2-3 sentences
- ✅ Says "I don't have enough information" when answer isn't in transcript
- ✅ ~300-500 tokens per answer (~$0.0001 cost)
- ✅ Loading indicator during API call
- ✅ Error messages for API failures

---

## Troubleshooting

### "OpenAI API Key Required" screen appears

**Cause:** API key not provided or not detected.

**Fix:**
- Verify `--dart-define=OPENAI_API_KEY=xxx` is in run command
- Check no spaces or quotes around the key
- Restart app after adding the flag

### API Errors

| Error | Meaning | Solution |
|-------|---------|----------|
| **401** | Invalid API key | Verify key is correct and active at platform.openai.com |
| **429** | Rate limit exceeded | Wait 1-2 minutes, or add payment method for higher limits |
| **500+** | OpenAI service issue | Wait and retry - check status.openai.com |

### Network Errors

- Check internet connection
- Verify firewall isn't blocking `api.openai.com`
- Try again (transient network issues are common)

### Flutter/Build Errors

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

---

## Running Tests

```bash
# Run all unit tests
flutter test

# Run with coverage
flutter test --coverage
```

**Current coverage:** 10 unit tests covering critical business logic (QAService, OpenAILLMService).

---

## Security Best Practices

**Development:**
- ❌ Never commit API keys to git
- ✅ Use `.gitignore` for `.vscode/` and similar config files
- ✅ Regenerate API key if accidentally committed

**Production:**
- ⚠️ Never ship API keys in mobile apps (can be extracted)
- ✅ Use a backend service to proxy API calls
- ✅ Implement rate limiting and authentication
- ✅ Use environment variables in CI/CD pipelines

**For Step 1 MVP:** Direct API key usage is acceptable for testing. Move to backend proxy before public release.

---

## Project Structure

```
learnova/
├── lib/
│   ├── features/qa/          # Q&A feature (Step 1)
│   ├── core/                 # Shared infrastructure
│   └── main.dart             # App entry point
├── test/                     # Unit tests
├── docs/
│   ├── DESIGN_MANUAL.md      # Design decisions & architecture
│   ├── DEVELOPMENT_GUIDELINES.md  # Coding standards
│   └── SETUP.md              # This file
└── README.md                 # Project overview
```

---

## Next Steps

After testing Step 1 MVP:

1. **Document your findings:**
   - Response quality (accuracy, hallucination rate)
   - Token usage patterns
   - Error patterns encountered

2. **Check the Design Manual:**
   - See [DESIGN_MANUAL.md](DESIGN_MANUAL.md) for design decisions
   - Review development roadmap (Step 2: YouTube integration)
   - Understand architecture and testing philosophy

3. **Join development:**
   - Read [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md) for coding standards
   - Check current issues and roadmap
   - Follow feature-based architecture patterns

---

## Getting Help

- **Design decisions:** See [DESIGN_MANUAL.md](DESIGN_MANUAL.md)
- **Coding standards:** See [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md)
- **OpenAI API docs:** https://platform.openai.com/docs
- **Flutter docs:** https://docs.flutter.dev

---

*Last Updated: After Step 1 completion*
