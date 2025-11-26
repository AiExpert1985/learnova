# Learnova Setup Guide

## Prerequisites

- Flutter SDK (3.8.1 or higher)
- OpenAI API key

## Getting an OpenAI API Key

1. Go to https://platform.openai.com/api-keys
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the key (you won't be able to see it again)

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

## Configuration

**One standard way:** Use `--dart-define` to pass API key at compile time.

This is the official Flutter approach - works on **all platforms**.

## Running the App

### Any Platform
```bash
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

### Specific Platforms
```bash
# Desktop
flutter run -d windows --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d macos --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d linux --dart-define=OPENAI_API_KEY=your-key-here

# Mobile
flutter run -d android --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d ios --dart-define=OPENAI_API_KEY=your-key-here
```

### Production Builds
```bash
# Android APK
flutter build apk --dart-define=OPENAI_API_KEY=your-key-here

# Android App Bundle (for Play Store)
flutter build appbundle --dart-define=OPENAI_API_KEY=your-key-here

# iOS (for App Store)
flutter build ios --dart-define=OPENAI_API_KEY=your-key-here
```

## For Convenience (Optional)

### VS Code Launch Configuration

Create `.vscode/launch.json`:
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

Then press F5 to run.

**Note:** Add `.vscode/` to `.gitignore` to avoid committing your API key.

## Security Notes

- **Never commit your API key** to version control
- Use environment variables in CI/CD pipelines
- For production, use a backend service to protect your API key

## Testing Step 1 MVP

The app currently uses a hardcoded transcript for testing. To test:

1. Run the app with your API key
2. You'll see a Q&A screen with a sample video about learning strategies
3. Type questions in the input field and press send
4. The AI will answer based on the transcript
5. Token usage is displayed with each answer

### Sample Questions to Try

- "What is spaced repetition?"
- "How many learning principles are mentioned?"
- "What's the difference between active recall and passive reading?"
- "Why is interleaving important?"
- "What is the most important insight mentioned?"

## Troubleshooting

### "OpenAI API Key Required" screen appears

- Make sure you're passing the `--dart-define` flag
- Check that your API key is correct (no spaces or quotes)

### API errors (401, 429, etc.)

- **401**: Invalid API key - verify your key is active
- **429**: Rate limit exceeded - wait a few minutes
- **500**: OpenAI service down - try again later

### Network errors

- Check your internet connection
- Ensure no firewall is blocking OpenAI API (api.openai.com)

## Next Steps

After testing Step 1, see [DESIGN_MANUAL.md](DESIGN_MANUAL.md) for:
- Recording your learnings
- Design decisions
- Moving to Step 2 (YouTube integration)
