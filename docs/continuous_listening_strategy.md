# Continuous Listening Strategy

This document summarizes the fixes and architecture choices applied to the continuous listening feature.

## Method Overview
- **Audio session tuning:** Configure the platform audio session for *play-and-record* with transient ducking so STT can run without stealing audio focus from the video player.
- **Speech-onset detection:** Use the first partial STT result to mark `userSpeaking` and pause video immediately when the user starts talking.
- **Deterministic state machine:** Expanded `ContinuousListeningState` with `userSpeaking` and explicit grace-period handling to avoid premature video resume.
- **Graceful TTS handling:** Retry once on TTS errors, fall back to text if synthesis still fails, and start a grace period only after TTS completion.
- **Timeout safeguards:** One-minute timer when the video is paused/ended to auto-disable listening and notify the user; five-minute inactivity timer remains for safety.

## Solutions Implemented
| Problem | Decision | Why |
| --- | --- | --- |
| Video pausing immediately when listening starts | Configure `AudioSessionService` to use `playAndRecord` with ducking | Prevents STT from seizing full audio focus and allows the video to keep playing. |
| Video should pause when the user starts speaking | Added `userSpeaking` state triggered by partial STT results | Aligns pause timing with speech onset rather than after recognition completes. |
| Video resuming before TTS completes | TTS retry + completion-driven grace period | Ensures playback resumes only after speech synthesis and a follow-up window. |
| Continuous mode stops after first Q/A | Introduced `restartListeningCycle` that bypasses the one-time flag | Allows multiple Q/A cycles without toggling the mode off/on. |
| Auto-disable after inactivity when video is paused | Coordinator monitors player state and triggers a 1-minute timeout | Matches the requested enhanced timeout behavior. |

## Solutions Deferred / Rejected
- **Full VAD + STT hybrid:** Not integrated yet to limit churn; current onset detection mitigates late pauses. Recommended as a future enhancement once Silero VAD integration is validated across devices.
- **WebView swap to `flutter_inappwebview`:** Deferred to avoid destabilizing the video stack; current audio-session tuning is sufficient for now.

## Future Enhancements
- Integrate Silero VAD for earlier voice detection without relying on STT audio focus.
- Track TTS completion from platform callbacks to further harden against platform-specific focus interruptions.
- Expand automated tests around the voice state machine and coordinator timeouts.
