import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app preferences and state persistence
/// Handles continuous mode preferences and session state
class PreferencesService {
  static const String _keyContinuousMode = 'continuous_mode_enabled';
  static const String _keyLastVideoId = 'last_video_id';
  static const String _keyAutoResumeEnabled = 'auto_resume_enabled';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// Initialize the service
  static Future<PreferencesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  /// Save continuous mode preference
  Future<bool> setContinuousModeEnabled(bool enabled) async {
    return await _prefs.setBool(_keyContinuousMode, enabled);
  }

  /// Get continuous mode preference
  bool getContinuousModeEnabled() {
    return _prefs.getBool(_keyContinuousMode) ?? false;
  }

  /// Save last video ID
  Future<bool> setLastVideoId(String videoId) async {
    return await _prefs.setString(_keyLastVideoId, videoId);
  }

  /// Get last video ID
  String? getLastVideoId() {
    return _prefs.getString(_keyLastVideoId);
  }

  /// Save auto-resume preference
  Future<bool> setAutoResumeEnabled(bool enabled) async {
    return await _prefs.setBool(_keyAutoResumeEnabled, enabled);
  }

  /// Get auto-resume preference
  bool getAutoResumeEnabled() {
    return _prefs.getBool(_keyAutoResumeEnabled) ?? true; // Default: enabled
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
