# Vidorion

**AI-powered learning companion for YouTube videos.** Ask questions about video content and get intelligent answers instantly.

## Quick Start

**Prerequisites:** Flutter/Dart 3.8.1+, [OpenAI API Key](https://platform.openai.com/api-keys).

```bash
# 1. Clone & Dependencies
git clone <repository-url>
cd vidorion
flutter pub get

# 2. Setup (Required)
dart run build_runner build --delete-conflicting-outputs

# 3. Run
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

> **Note:** Microphone & Speech permissions are requested on first use (Android/iOS pre-configured).

## Features

- 🎥 **YouTube Integration** - Automatic transcripts & playback.
- 💬 **Context-Aware Q&A** - Smart answers based on watched content.
- 🤖 **GPT-4o-mini** - Fast, cheap AI using your own key.
- 💾 **History** - Auto-saved conversations & smart restore.
- 🗣️ **Voice Mode** - Hands-free continuous interaction.

## Documentation

- **[DESIGN_MANUAL.md](docs/DESIGN_MANUAL.md)** - Architecture & Tech Stack (Riverpod, Hive, etc.)
- **[AI_ASSISTANT_GUIDE.md](docs/AI_ASSISTANT_GUIDE.md)** - Contributing guidelines.

## Troubleshooting

- **Build Errors:** Run `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs`
- **Tests:** Run `flutter test`

## License

MIT
