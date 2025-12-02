# Learnova

**Voice-first learning companion for YouTube videos.** Ask questions about video content and get AI-powered answers based on transcripts.

**✨ Features:**
- 🎥 YouTube video integration with transcript fetching
- 💬 Position-aware Q&A (questions consider watched content)
- 📝 Auto-save conversation history
- 🔄 Load previous conversations
- 🎯 GPT-4o-mini powered answers

---

## Quick Start

### 1. Prerequisites
- **Flutter** (3.8.1+)
- **Dart** (3.8.1+)
- **OpenAI API Key** - Get one at [platform.openai.com](https://platform.openai.com/api-keys)

### 2. Setup & Installation

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate Hive adapters (required for local storage)
dart run build_runner build --delete-conflicting-outputs

# 3. Run the app (replace with your actual API key)
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

**Platform-specific:**
```bash
# Windows
flutter run -d windows --dart-define=OPENAI_API_KEY=your-key-here

# Android
flutter run -d android --dart-define=OPENAI_API_KEY=your-key-here

# iOS
flutter run -d ios --dart-define=OPENAI_API_KEY=your-key-here

# Chrome (Web)
flutter run -d chrome --dart-define=OPENAI_API_KEY=your-key-here
```

### 3. Usage

1. **Paste a YouTube URL** in the input field and press play
2. **Wait for the video** and transcript to load
3. **Ask questions** about the video content
4. **View history** by tapping the history icon (top-right)
5. **Load previous conversations** by tapping any history entry

---

## Testing

```bash
# Run all tests
flutter test

# Run specific test suite
flutter test test/features/history/
flutter test test/features/qa/

# Run with coverage
flutter test --coverage
```

---

## Project Structure

```
lib/
├── core/                  # Shared services & utilities
│   ├── providers/        # App-wide Riverpod providers
│   ├── routes/           # GoRouter configuration
│   ├── services/         # LLM, YouTube, Config services
│   └── widgets/          # Reusable UI components
├── features/
│   ├── qa/              # Q&A feature
│   │   ├── models/      # Question, Answer, QAHistoryEntry
│   │   ├── services/    # QA service (LLM interaction)
│   │   ├── state/       # QANotifier (StateNotifier)
│   │   ├── screens/     # QA screen UI
│   │   └── widgets/     # Q&A specific widgets
│   └── history/         # Conversation history feature
│       ├── data/        # Models, Repository, Adapters
│       ├── services/    # HistoryService (public API)
│       ├── state/       # HistoryNotifier
│       ├── providers/   # History providers
│       └── ui/          # History UI widgets
└── main.dart            # App entry point
```

---

## Troubleshooting

### Build Runner Issues
```bash
# Clean and rebuild
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Hive Storage Issues
```bash
# Clear app data and reinstall
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

### Test Failures
```bash
# Ensure all dependencies are installed
flutter pub get

# Run tests with verbose output
flutter test --verbose
```

---

## For Developers

For detailed architecture, design decisions, and coding standards, please refer to:

- **[Design Manual](docs/DESIGN_MANUAL.md)** - Architecture, tech stack, design decisions
- **[AI Assistant Guide](docs/AI_ASSISTANT_GUIDE.md)** - Development guidelines and standards
- **[Implementation Summary](IMPLEMENTATION_SUMMARY.md)** - Step-by-step implementation guide
- **[Fixes Applied](FIXES_APPLIED.md)** - Recent critical fixes and improvements

---

## License

This project is licensed under the MIT License.
