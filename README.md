# Learnova

**Voice-first learning companion for YouTube videos.** Ask questions about video content and get AI-powered answers based on transcripts.

---

## Current Status: Step 1 MVP ✅

Text-based Q&A with hardcoded transcript to validate core AI interaction.

**Features:**
- ✅ Q&A with GPT-4o-mini (~$0.0001 per question)
- ✅ Error handling and token tracking
- ✅ Works on all platforms (Windows, Android, iOS, Web)

**Coming Next:**
- YouTube transcript integration
- Voice input/output
- User authentication

---

## Quick Start

### 1. Get OpenAI API Key
Visit https://platform.openai.com/api-keys → Create new secret key (free tier works)

### 2. Install & Run
```bash
flutter pub get
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

**Platform-specific:**
```bash
flutter run -d windows --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d android --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d ios --dart-define=OPENAI_API_KEY=your-key-here
```

### 3. Test the App
Ask questions about the sample transcript:
- "What is spaced repetition?"
- "How many learning principles are mentioned?"
- "What's the main idea of this video?"

---

## IDE Setup (Optional)

**VS Code:** Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [{
    "name": "Learnova",
    "request": "launch",
    "type": "dart",
    "program": "lib/main.dart",
    "args": ["--dart-define=OPENAI_API_KEY=your-key-here"]
  }]
}
```
Then press `F5` to run. *(Add `.vscode/` to `.gitignore`)*

**Android Studio:** Edit Run Configuration → Additional args: `--dart-define=OPENAI_API_KEY=your-key-here`

---

## Troubleshooting

**"API Key Required" screen?**
- Verify `--dart-define=OPENAI_API_KEY=xxx` is in run command
- Check no spaces/quotes around key

**API Errors:**
- `401` - Invalid key → verify at platform.openai.com
- `429` - Rate limit → wait 1-2 minutes
- `500+` - OpenAI issue → retry later

**Build Issues:**
```bash
flutter clean && flutter pub get
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

---

## Architecture

**Stack:** Flutter + Riverpod + GoRouter + OpenAI

**Structure:** Feature-based organization
```
lib/
  features/qa/          # Q&A feature
    models/             # Data models
    services/           # Business logic
    screens/            # UI screens
    widgets/            # UI components
  core/                 # Shared infrastructure
    providers/          # Dependency injection
    routes/             # App routing
    services/llm/       # LLM abstraction (OpenAI/Gemini/Claude)
```

**Key Decisions:**
- ✅ Feature-based (not layered) architecture
- ✅ Provider-agnostic LLM abstraction
- ✅ Result pattern for error handling
- ✅ Riverpod for DI, `setState` for local UI state

---

## Testing

```bash
flutter test                    # Run all tests
flutter test --coverage         # With coverage
```

**Current:** 10 unit tests covering business logic (QAService, OpenAILLMService)

---

## Documentation

**For Development:**
- **[Design Manual](docs/DESIGN_MANUAL.md)** - Architecture, decisions, roadmap, learnings
- **[Development Guidelines](docs/DEVELOPMENT_GUIDELINES.md)** - Coding standards

**Quick Reference:**
- **Prerequisites:** Flutter 3.8.1+, OpenAI API key
- **Cost:** ~$0.0001 per question (~300-500 tokens)
- **Security:** Never commit API keys, use backend proxy for production

---

## Project Principles

**Code Organization:**
- Screen files ~100-150 lines max
- Extract widgets to `widgets/` when > 150 lines
- Use existing getters (don't recreate logic)
- Self-documenting code over comments

**Testing:**
- ✅ Unit tests for business logic
- ❌ No widget tests (manual testing preferred)
- Fast execution (< 5 seconds)

**Development:**
- Feature-based organization
- No over-engineering (solve current problems)
- Standard approaches over clever tricks
- Practical solutions over perfect code

---

## Security

**Development:** Direct API key usage is fine for testing.

**Production:**
- ⚠️ Never ship API keys in mobile apps
- ✅ Use backend service to proxy API calls
- ✅ Implement rate limiting and authentication

---

## Contributing

1. Read [DESIGN_MANUAL.md](docs/DESIGN_MANUAL.md) for architecture
2. Read [DEVELOPMENT_GUIDELINES.md](docs/DEVELOPMENT_GUIDELINES.md) for standards
3. Follow feature-based structure
4. Test business logic with unit tests
5. Keep files under 150 lines

---

**Need help?** Check [DESIGN_MANUAL.md](docs/DESIGN_MANUAL.md) for detailed decisions and architecture.
