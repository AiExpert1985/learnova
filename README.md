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

# Set up API key
cp config.example.json config.json
# Edit config.json and add your OpenAI API key

# Run the app
flutter run --dart-define-from-file=config.json
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
      models/              # Data models
      services/            # Business logic
      screens/             # UI
  core/
    services/              # Shared services (OpenAI)
    constants/             # Mock data and constants
```

## Getting Started

This is a Flutter application following feature-based architecture with dependency injection.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
