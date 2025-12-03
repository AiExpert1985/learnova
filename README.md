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
- OpenAI API Key ([Get one here](https://platform.openai.com/api-keys))

### Installation

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate storage adapters
dart run build_runner build --delete-conflicting-outputs

# 3. Run the app
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

### Usage

1. Paste a YouTube URL and press play
2. Wait for video and transcript to load
3. Ask questions about the content
4. Access previous conversations via history icon (top-right)

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
