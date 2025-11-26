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

## Configuration (Choose One)

The app supports two configuration methods:

### Option 1: config.json File (Best for Desktop Development)

Create `config.json` in project root:
```bash
echo '{"OPENAI_API_KEY": "your-key-here"}' > config.json
```

Or manually create `config.json`:
```json
{
  "OPENAI_API_KEY": "sk-your-actual-key-here"
}
```

**Note:** `config.json` is gitignored and won't be committed.

### Option 2: Environment Variable (Required for Mobile)

Pass API key via `--dart-define` when running:
```bash
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

**When to use each:**
- **Desktop (Windows/Mac/Linux):** Use config.json (simpler)
- **Mobile (Android/iOS):** Use --dart-define (required)

## Running the App

### Desktop
```bash
flutter run -d windows  # or macos, linux
```
Reads from `config.json` automatically.

### Android Emulator
```bash
flutter run -d android --dart-define=OPENAI_API_KEY=your-key-here
```

### iOS Simulator
```bash
flutter run -d ios --dart-define=OPENAI_API_KEY=your-key-here
```

### Android Device (Release Build)
```bash
flutter build apk --dart-define=OPENAI_API_KEY=your-key-here
```

## Security Notes

- **Never commit your API key** to version control
- `config.json` is already in `.gitignore`
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
