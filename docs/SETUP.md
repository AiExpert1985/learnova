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

## Running the App

### Option 1: Command Line (Recommended for Testing)

Run with your API key:
```bash
flutter run --dart-define=OPENAI_API_KEY=your_api_key_here
```

### Option 2: VS Code Launch Configuration

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
        "--dart-define=OPENAI_API_KEY=your_api_key_here"
      ]
    }
  ]
}
```

**Important:** Add `.vscode/launch.json` to `.gitignore` to avoid committing your API key.

### Option 3: Android Studio

1. Go to Run → Edit Configurations
2. Add to "Additional run args":
   ```
   --dart-define=OPENAI_API_KEY=your_api_key_here
   ```

## Security Notes

- **Never commit your API key** to version control
- The API key is passed at build time via `--dart-define`
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
