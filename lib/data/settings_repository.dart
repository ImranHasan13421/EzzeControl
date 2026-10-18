import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository extends ChangeNotifier {
  static const String _keyPointerSpeed = 'mouse_pointer_speed';
  static const String _keyScrollSpeed = 'mouse_scroll_speed';

  double _pointerSpeed = 1.0;
  double _scrollSpeed = 1.0;

  double get pointerSpeed => _pointerSpeed;
  double get scrollSpeed => _scrollSpeed;

  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pointerSpeed = prefs.getDouble(_keyPointerSpeed) ?? 1.0;
      _scrollSpeed = prefs.getDouble(_keyScrollSpeed) ?? 1.0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> setPointerSpeed(double speed) async {
    _pointerSpeed = speed.clamp(0.2, 3.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyPointerSpeed, _pointerSpeed);
    } catch (e) {
      debugPrint('Error saving pointer speed: $e');
    }
  }

  Future<void> setScrollSpeed(double speed) async {
    _scrollSpeed = speed.clamp(0.2, 3.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyScrollSpeed, _scrollSpeed);
    } catch (e) {
      debugPrint('Error saving scroll speed: $e');
    }
  }

  Future<void> resetPointerSpeed() async {
    await setPointerSpeed(1.0);
  }

  Future<void> resetScrollSpeed() async {
    await setScrollSpeed(1.0);
  }
}
