import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/mouse_settings.dart';

class SettingsRepository {
  static const String _keySensitivity = 'mouse_sensitivity';
  static const String _keyScrollSensitivity = 'mouse_scroll_sensitivity';
  static const String _keyAcceleration = 'mouse_acceleration';
  static const String _keyInvertScroll = 'mouse_invert_scroll';
  static const String _keyTapToClick = 'mouse_tap_to_click';
  static const String _keyHaptics = 'mouse_haptics';
  static const String _keyKeepScreenAwake = 'app_keep_screen_awake';
  static const String _keyDefaultTab = 'app_default_tab';

  Future<MouseSettings> loadMouseSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return MouseSettings(
        sensitivity: prefs.getDouble(_keySensitivity) ?? 1.2,
        scrollSensitivity: prefs.getDouble(_keyScrollSensitivity) ?? 1.0,
        accelerationEnabled: prefs.getBool(_keyAcceleration) ?? true,
        invertScroll: prefs.getBool(_keyInvertScroll) ?? false,
        tapToClick: prefs.getBool(_keyTapToClick) ?? true,
        hapticsEnabled: prefs.getBool(_keyHaptics) ?? true,
      );
    } catch (_) {
      return const MouseSettings();
    }
  }

  Future<void> saveMouseSettings(MouseSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySensitivity, settings.sensitivity);
      await prefs.setDouble(_keyScrollSensitivity, settings.scrollSensitivity);
      await prefs.setBool(_keyAcceleration, settings.accelerationEnabled);
      await prefs.setBool(_keyInvertScroll, settings.invertScroll);
      await prefs.setBool(_keyTapToClick, settings.tapToClick);
      await prefs.setBool(_keyHaptics, settings.hapticsEnabled);
    } catch (_) {
      // Ignored
    }
  }

  Future<bool> getKeepScreenAwake() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyKeepScreenAwake) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setKeepScreenAwake(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyKeepScreenAwake, value);
    } catch (_) {
      // Ignored
    }
  }

  Future<int> getDefaultLandingTab() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyDefaultTab) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> setDefaultLandingTab(int tabIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDefaultTab, tabIndex);
    } catch (_) {
      // Ignored
    }
  }
}
