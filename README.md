# Learnova

A voice-first learning companion for YouTube videos. Ask questions by voice while watching educational content, get AI-powered answers, and resume automatically.

## Current Status: Step 1 MVP

Basic Q&A with hardcoded transcript to validate the core AI interaction.

**What works:**
- Text-based Q&A with AI (GPT-4 mini)
- Hardcoded sample transcript
- Error handling
- Token usage tracking

**Not yet implemented:**
- YouTube integration
- Voice input/output
- Authentication

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run with API key (works on all platforms)
flutter run --dart-define=OPENAI_API_KEY=your-key-here

# Or specify platform
flutter run -d windows --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d android --dart-define=OPENAI_API_KEY=your-key-here
```

See [SETUP.md](docs/SETUP.md) for detailed instructions.

## Documentation

- [Setup Guide](docs/SETUP.md) - How to run the app and configure API keys
- [Design Manual](docs/DESIGN_MANUAL.md) - Architecture decisions and learnings
- [Development Guidelines](docs/DEVELOPMENT_GUIDELINES.md) - Core principles and practices

## Project Structure

```
lib/
  features/
    qa/                    # Question & Answer feature
      models/              # Data models (Question, Answer, QAResult)
      services/            # Business logic (QAService)
      screens/             # UI screens (QAScreen)
  core/
    providers/             # Riverpod DI providers
    routes/                # GoRouter configuration
    services/              # Shared services
      llm/                 # LLM abstraction (OpenAI, future: Gemini, Claude)
      config_service.dart  # Config file reader
    constants/             # Mock data and constants
  main.dart
```

**Architecture:**
- **State Management**: Riverpod
- **Routing**: GoRouter
- **LLM Provider**: OpenAI (swappable to Gemini/Claude)

## Getting Started

This is a Flutter application following feature-based architecture with dependency injection.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
