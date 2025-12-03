/// Permission handling for voice services
library;

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Request microphone permission
  /// Returns true if granted, false otherwise
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if permission is permanently denied
  Future<bool> isMicrophonePermissionPermanentlyDenied() async {
    final status = await Permission.microphone.status;
    return status.isPermanentlyDenied;
  }

  /// Open app settings (for when permission is permanently denied)
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Get microphone permission status
  Future<PermissionStatus> getMicrophonePermissionStatus() async {
    return await Permission.microphone.status;
  }

  /// Check if speech recognition permission is granted (iOS specific)
  Future<bool> hasSpeechRecognitionPermission() async {
    final status = await Permission.speech.status;
    return status.isGranted;
  }

  /// Request speech recognition permission (iOS specific)
  Future<bool> requestSpeechRecognitionPermission() async {
    final status = await Permission.speech.request();
    return status.isGranted;
  }

  /// Request all voice-related permissions
  /// Returns true if all required permissions are granted
  Future<bool> requestVoicePermissions() async {
    final micStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();

    return micStatus.isGranted && speechStatus.isGranted;
  }
}
