import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../domain/models.dart';

class BluetoothHidRepository extends ChangeNotifier {
  static const MethodChannel _methodChannel = MethodChannel('com.ezze.control/hid');
  static const EventChannel _eventChannel = EventChannel('com.ezze.control/events');

  static final BluetoothHidRepository _instance = BluetoothHidRepository._internal();
  factory BluetoothHidRepository() => _instance;
  BluetoothHidRepository._internal();

  StreamSubscription? _eventSubscription;

  HidCapabilities _capabilities = const HidCapabilities();
  List<BtDevice> _pairedDevices = [];
  List<BtDevice> _discoveredDevices = [];
  bool _isScanning = false;
  BtDevice? _activeDevice;

  HidCapabilities get capabilities => _capabilities;
  List<BtDevice> get pairedDevices => _pairedDevices;
  List<BtDevice> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  BtDevice? get activeDevice => _activeDevice;
  bool get isConnected => _capabilities.isConnected;
  bool get isConnecting => _capabilities.isConnecting;

  Future<void> init() async {
    _startEventListening();
    await updateCapabilities();
    await refreshPairedDevices();
  }

  void _startEventListening() {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          _capabilities = HidCapabilities.fromMap(event);
          if (event['type'] == 'device_found') {
            refreshDiscoveredDevices();
          } else if (event['type'] == 'discovery_finished') {
            _isScanning = false;
          } else if (event['type'] == 'device_unpaired') {
            refreshPairedDevices();
          }
          notifyListeners();
        }
      },
      onError: (dynamic error) {
        debugPrint('HID EventChannel error: $error');
      },
    );
  }

  Future<void> updateCapabilities() async {
    try {
      final res = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getCapabilities');
      if (res != null) {
        _capabilities = HidCapabilities.fromMap(res);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating capabilities: $e');
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final granted = await _methodChannel.invokeMethod<bool>('requestPermissions') ?? false;
      await updateCapabilities();
      if (granted) {
        await refreshPairedDevices();
      }
      return granted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> refreshPairedDevices() async {
    try {
      final res = await _methodChannel.invokeListMethod<Map<dynamic, dynamic>>('getPairedDevices');
      if (res != null) {
        _pairedDevices = res.map((m) => BtDevice.fromMap(m)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching paired devices: $e');
    }
  }

  Future<void> refreshDiscoveredDevices() async {
    try {
      final res = await _methodChannel.invokeListMethod<Map<dynamic, dynamic>>('getDiscoveredDevices');
      if (res != null) {
        _discoveredDevices = res.map((m) => BtDevice.fromMap(m)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching discovered devices: $e');
    }
  }

  Future<bool> startDiscovery() async {
    try {
      _isScanning = true;
      _discoveredDevices.clear();
      notifyListeners();
      final ok = await _methodChannel.invokeMethod<bool>('startDiscovery') ?? false;
      return ok;
    } catch (e) {
      _isScanning = false;
      notifyListeners();
      debugPrint('Error starting discovery: $e');
      return false;
    }
  }

  Future<bool> stopDiscovery() async {
    try {
      _isScanning = false;
      notifyListeners();
      final ok = await _methodChannel.invokeMethod<bool>('stopDiscovery') ?? false;
      return ok;
    } catch (e) {
      debugPrint('Error stopping discovery: $e');
      return false;
    }
  }

  Future<bool> connect(BtDevice device) async {
    try {
      _activeDevice = device;
      notifyListeners();
      final ok = await _methodChannel.invokeMethod<bool>('connect', {'address': device.address}) ?? false;
      return ok;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      final ok = await _methodChannel.invokeMethod<bool>('disconnect') ?? false;
      _activeDevice = null;
      notifyListeners();
      return ok;
    } catch (e) {
      debugPrint('Error disconnecting: $e');
      return false;
    }
  }

  Future<bool> unpair(String address) async {
    try {
      final ok = await _methodChannel.invokeMethod<bool>('unpair', {'address': address}) ?? false;
      await refreshPairedDevices();
      return ok;
    } catch (e) {
      debugPrint('Error unpairing device: $e');
      return false;
    }
  }

  Future<void> openBluetoothSettings() async {
    try {
      await _methodChannel.invokeMethod('openBluetoothSettings');
    } catch (e) {
      debugPrint('Error opening Bluetooth settings: $e');
    }
  }

  Future<void> sendMouseMovement({
    required int dx,
    required int dy,
    int buttons = 0,
    int wheel = 0,
  }) async {
    try {
      await _methodChannel.invokeMethod('sendMouseMovement', {
        'dx': dx,
        'dy': dy,
        'buttons': buttons,
        'wheel': wheel,
      });
    } catch (e) {
      debugPrint('Error sending mouse movement: $e');
    }
  }

  Future<void> sendMouseClick(String button, {bool isDouble = false}) async {
    try {
      await _methodChannel.invokeMethod('sendMouseClick', {
        'button': button,
        'isDouble': isDouble,
      });
    } catch (e) {
      debugPrint('Error sending mouse click: $e');
    }
  }

  Future<void> sendMouseDown({int buttons = 1}) async {
    try {
      await _methodChannel.invokeMethod('sendMouseDown', {'buttons': buttons});
    } catch (e) {
      debugPrint('Error sending mouse down: $e');
    }
  }

  Future<void> sendMouseUp() async {
    try {
      await _methodChannel.invokeMethod('sendMouseUp');
    } catch (e) {
      debugPrint('Error sending mouse up: $e');
    }
  }

  Future<void> sendKey(int keyCode, {int modifier = 0}) async {
    try {
      await _methodChannel.invokeMethod('sendKey', {
        'keyCode': keyCode,
        'modifier': modifier,
      });
    } catch (e) {
      debugPrint('Error sending key: $e');
    }
  }

  Future<void> sendText(String text) async {
    if (text.isEmpty) return;
    try {
      await _methodChannel.invokeMethod('sendText', {'text': text});
    } catch (e) {
      debugPrint('Error sending text: $e');
    }
  }

  Future<void> releaseAll() async {
    try {
      await _methodChannel.invokeMethod('releaseAll');
    } catch (e) {
      debugPrint('Error releasing all inputs: $e');
    }
  }

  Future<String?> requestSpeechInput() async {
    try {
      final result = await _methodChannel.invokeMethod<String>('requestSpeechInput');
      return result;
    } catch (e) {
      debugPrint('Error requesting speech input: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
