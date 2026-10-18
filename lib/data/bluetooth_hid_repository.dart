import 'dart:async';
import 'package:flutter/services.dart';
import '../domain/models/hid_key_codes.dart';
import '../domain/models/hid_status.dart';

class BluetoothHidRepository {
  static const MethodChannel _methodChannel =
      MethodChannel('com.ezze.control/hid');
  static const EventChannel _eventChannel =
      EventChannel('com.ezze.control/events');

  Stream<Map<dynamic, dynamic>>? _cachedStream;

  Stream<Map<dynamic, dynamic>> get eventStream {
    _cachedStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => event as Map<dynamic, dynamic>);
    return _cachedStream!;
  }

  Future<HidStatus> getCapabilities() async {
    try {
      final result =
          await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getCapabilities');
      if (result != null) {
        return HidStatus.fromMap(result);
      }
    } on PlatformException catch (e) {
      return HidStatus(
        lastError: 'Failed to query capabilities: ${e.message}',
      );
    }
    return const HidStatus();
  }

  Future<bool> requestPermissions() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestHidRegistration() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('requestHidRegistration');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> unregisterHid() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('unregisterHid');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<List<Map<String, String>>> getBondedDevices() async {
    try {
      final result = await _methodChannel
          .invokeListMethod<Map<dynamic, dynamic>>('getBondedDevices');
      if (result != null) {
        return result.map((item) {
          return {
            'name': item['name']?.toString() ?? 'Unknown Device',
            'address': item['address']?.toString() ?? '',
          };
        }).toList();
      }
    } on PlatformException {
      return [];
    }
    return [];
  }

  Future<bool> connectHost(String address) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'connectHost',
        {'address': address},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> unpairHost(String address) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'unpairHost',
        {'address': address},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> makeDiscoverable() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('makeDiscoverable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> openBluetoothSettings() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('openBluetoothSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> sendTestMouseMovement() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('sendTestMouseMovement');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> sendTestKey() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('sendTestKey');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> sendMouseMovement({
    int buttons = 0,
    int dx = 0,
    int dy = 0,
    int wheel = 0,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendMouseMovement',
        {
          'buttons': buttons,
          'dx': dx,
          'dy': dy,
          'wheel': wheel,
        },
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> sendMouseReport(Uint8List data) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendMouseReport',
        {'data': data},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> sendKeyboardReport(Uint8List data) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'sendKeyboardReport',
        {'data': data},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> sendKeyStroke({
    int modifiers = 0,
    required int keyCode,
  }) async {
    try {
      final keyDown = Uint8List(8);
      keyDown[0] = modifiers;
      keyDown[1] = 0;
      keyDown[2] = keyCode;
      await sendKeyboardReport(keyDown);

      await Future.delayed(const Duration(milliseconds: 25));

      final keyUp = Uint8List(8);
      keyUp[0] = modifiers;
      await sendKeyboardReport(keyUp);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendKeyboardState({
    int modifiers = 0,
    List<int> keyCodes = const [],
  }) async {
    try {
      final report = Uint8List(8);
      report[0] = modifiers;
      report[1] = 0;
      final count = keyCodes.length.clamp(0, 6);
      for (var i = 0; i < count; i++) {
        report[2 + i] = keyCodes[i];
      }
      return await sendKeyboardReport(report);
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendTextSequence(String text) async {
    try {
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        final stroke = HidKeyCodes.fromChar(char);
        if (stroke != null) {
          await sendKeyStroke(
            modifiers: stroke.modifier,
            keyCode: stroke.keyCode,
          );
          await Future.delayed(const Duration(milliseconds: 15));
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> releaseAllInputs() async {
    try {
      final result =
          await _methodChannel.invokeMethod<bool>('releaseAllInputs');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('disconnect');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> setKeepScreenOn(bool enabled) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'setKeepScreenOn',
        {'enabled': enabled},
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
