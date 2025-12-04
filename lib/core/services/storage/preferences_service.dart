import 'package:hive_flutter/hive_flutter.dart';

/// Service for managing app preferences and state persistence
/// Handles continuous mode preferences and session state using Hive
class PreferencesService {
  static const String _boxName = 'app_preferences';
  static const String _keyContinuousMode = 'continuous_mode_enabled';
  static const String _keyLastVideoId = 'last_video_id';
  static const String _keyAutoResumeEnabled = 'auto_resume_enabled';

  late Box _prefsBox;

  /// Initialize the service
  static Future<PreferencesService> create() async {
    final service = PreferencesService();
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    _prefsBox = await Hive.openBox(_boxName);
  }

  /// Save continuous mode preference
  Future<void> setContinuousModeEnabled(bool enabled) async {
    await _prefsBox.put(_keyContinuousMode, enabled);
  }

  /// Get continuous mode preference
  bool getContinuousModeEnabled() {
    return _prefsBox.get(_keyContinuousMode, defaultValue: false) as bool;
  }

  /// Save last video ID
  Future<void> setLastVideoId(String videoId) async {
    await _prefsBox.put(_keyLastVideoId, videoId);
  }

  /// Get last video ID
  String? getLastVideoId() {
    return _prefsBox.get(_keyLastVideoId) as String?;
  }

  /// Save auto-resume preference
  Future<void> setAutoResumeEnabled(bool enabled) async {
    await _prefsBox.put(_keyAutoResumeEnabled, enabled);
  }

  /// Get auto-resume preference
  bool getAutoResumeEnabled() {
    return _prefsBox.get(_keyAutoResumeEnabled, defaultValue: true) as bool;
  }

  /// Clear all preferences
  Future<void> clearAll() async {
    await _prefsBox.clear();
  }
}
