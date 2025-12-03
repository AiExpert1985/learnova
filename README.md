# Learnova

**AI-powered learning companion for YouTube videos.** Ask questions about video content and get intelligent answers based on transcripts.

## Features

- 🎥 **YouTube Integration** - Load any YouTube video with automatic transcript fetching
- 💬 **Position-Aware Q&A** - Answers based on content you've actually watched
- 🤖 **GPT-4o-mini Powered** - Fast, cost-effective AI responses
- 💾 **Auto-Save Conversations** - Never lose your learning progress
- 🔄 **Smart History** - Automatically resumes previous conversations when you paste a URL
- 🗑️ **History Management** - View, search, delete, or clear all conversations

---

## Quick Start

### Prerequisites
- Flutter 3.8.1+
- Dart SDK 3.8.1+
- OpenAI API Key ([Get one here](https://platform.openai.com/api-keys))

### Installation

```bash
# 1. Clone the repository
git clone <repository-url>
cd learnova

# 2. Install dependencies
flutter pub get

# 3. Generate Hive storage adapters (REQUIRED)
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app with your OpenAI API key
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

> **Note:** Step 3 is required to generate `hive_adapters.g.dart` for local storage functionality.

### Usage

1. Paste a YouTube URL and press play
2. Wait for video and transcript to load
3. Ask questions about the content
4. Access previous conversations via history icon (top-right)

---

## Architecture

### Feature Structure
```
features/
├── qa/              # Q&A feature (main functionality)
│   ├── models/      # Domain models
│   ├── services/    # Business logic
│   ├── state/       # State management (Riverpod)
│   └── ui/          # Screens and widgets
└── history/         # Conversation persistence
    ├── data/        # Repository pattern + Hive adapters
    ├── services/    # Public API for other features
    ├── state/       # State management
    └── ui/          # History UI components
```

### Key Technologies
- **Flutter** - Cross-platform UI
- **Riverpod** - State management & DI
- **Hive** - Local NoSQL storage
- **OpenAI GPT-4o-mini** - AI responses (~$0.0001/question)
- **YouTube Innertube API** - Direct transcript fetching

---

## Testing

```bash
# Run all tests
flutter test

# Run specific feature tests
flutter test test/features/qa/
flutter test test/features/history/
```

---

## Documentation

For detailed information, see:

- **[DESIGN_MANUAL.md](docs/DESIGN_MANUAL.md)** - Architecture, design decisions, and tech stack
- **[AI_ASSISTANT_GUIDE.md](docs/AI_ASSISTANT_GUIDE.md)** - Development guidelines and coding standards

---

## Troubleshooting

**Build errors after pulling changes:**
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

**Tests failing:**
```bash
flutter pub get
flutter test --verbose
```

---

## License

MIT License
