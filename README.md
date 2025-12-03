# Learnova

**Voice-first learning companion for YouTube videos.** Ask questions about video content and get AI-powered answers based on transcripts.

---

## Quick Start

### 1. Prerequisites
- **Flutter** (3.8.1+)
- **OpenAI API Key** (Get one at [platform.openai.com](https://platform.openai.com/api-keys))

### 2. Install & Run
```bash
# Get dependencies
flutter pub get

# Run the app (replace with your actual key)
flutter run --dart-define=OPENAI_API_KEY=your-key-here
```

**Platform-specific:**
```bash
flutter run -d windows --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d android --dart-define=OPENAI_API_KEY=your-key-here
flutter run -d ios --dart-define=OPENAI_API_KEY=your-key-here
```

### 3. Permissions Setup (Voice I/O)

The app requires microphone and speech recognition permissions for voice features.

**Android:**
Permissions are already configured in `android/app/src/main/AndroidManifest.xml`:
- `RECORD_AUDIO` - Microphone access for voice input
- `BLUETOOTH` / `BLUETOOTH_CONNECT` - Bluetooth headset support

**iOS:**
Permissions are already configured in `ios/Runner/Info.plist`:
- `NSMicrophoneUsageDescription` - Microphone access
- `NSSpeechRecognitionUsageDescription` - Speech recognition

On first use, the app will request these permissions. If denied, you'll need to manually enable them in device settings.

---

## For Developers

For detailed architecture, design decisions, and coding standards, please refer to:

- **[Design Manual](docs/DESIGN_MANUAL.md)**
- **[AI Assistant Guide](docs/AI_ASSISTANT_GUIDE.md)**
