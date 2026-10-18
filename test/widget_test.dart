import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_control/data/bluetooth_hid_repository.dart';
import 'package:ezze_control/data/settings_repository.dart';
import 'package:ezze_control/domain/models/hid_key_codes.dart';
import 'package:ezze_control/domain/models/hid_status.dart';
import 'package:ezze_control/domain/models/mouse_settings.dart';
import 'package:ezze_control/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HidStatus Unit Tests', () {
    test('Default values are safe and expected', () {
      const status = HidStatus();
      expect(status.supportedApi, isFalse);
      expect(status.sdkInt, 0);
      expect(status.bluetoothSupported, isFalse);
      expect(status.bluetoothEnabled, isFalse);
      expect(status.permissionsGranted, isFalse);
      expect(status.missingPermissions, isEmpty);
      expect(status.profileAvailable, isFalse);
      expect(status.isRegistered, isFalse);
      expect(status.connectionState, 'DISCONNECTED');
      expect(status.isConnected, isFalse);
      expect(status.isReadyToRegister, isFalse);
    });

    test('Parses from native map correctly', () {
      final map = {
        'supportedApi': true,
        'sdkInt': 34,
        'deviceModel': 'Infinix X6833B',
        'androidVersion': '14',
        'bluetoothSupported': true,
        'bluetoothEnabled': true,
        'permissionsGranted': true,
        'missingPermissions': <String>[],
        'profileAvailable': true,
        'profilePending': false,
        'isRegistered': true,
        'isRegistering': false,
        'connectionState': 'CONNECTED',
        'connectedDeviceName': 'DESKTOP-TEST',
        'connectedDeviceAddress': 'AA:BB:CC:DD:EE:FF',
        'lastError': null,
      };

      final status = HidStatus.fromMap(map);
      expect(status.supportedApi, isTrue);
      expect(status.sdkInt, 34);
      expect(status.deviceModel, 'Infinix X6833B');
      expect(status.androidVersion, '14');
      expect(status.bluetoothSupported, isTrue);
      expect(status.bluetoothEnabled, isTrue);
      expect(status.permissionsGranted, isTrue);
      expect(status.missingPermissions, isEmpty);
      expect(status.profileAvailable, isTrue);
      expect(status.isRegistered, isTrue);
      expect(status.isConnected, isTrue);
      expect(status.connectedDeviceName, 'DESKTOP-TEST');
      expect(status.connectedDeviceAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('isReadyToRegister evaluates prerequisites accurately', () {
      const notReady = HidStatus(
        supportedApi: true,
        bluetoothSupported: true,
        bluetoothEnabled: false,
        permissionsGranted: true,
      );
      expect(notReady.isReadyToRegister, isFalse);

      const ready = HidStatus(
        supportedApi: true,
        bluetoothSupported: true,
        bluetoothEnabled: true,
        permissionsGranted: true,
      );
      expect(ready.isReadyToRegister, isTrue);
    });
  });

  group('MouseSettings Unit Tests', () {
    test('Default values and serialization are correct', () {
      const settings = MouseSettings();
      expect(settings.sensitivity, 1.2);
      expect(settings.scrollSensitivity, 1.0);
      expect(settings.accelerationEnabled, isTrue);
      expect(settings.invertScroll, isFalse);
      expect(settings.tapToClick, isTrue);
      expect(settings.hapticsEnabled, isTrue);

      final map = settings.toMap();
      final reconstructed = MouseSettings.fromMap(map);
      expect(reconstructed.sensitivity, 1.2);
      expect(reconstructed.scrollSensitivity, 1.0);
      expect(reconstructed.accelerationEnabled, isTrue);
      expect(reconstructed.invertScroll, isFalse);
      expect(reconstructed.tapToClick, isTrue);
      expect(reconstructed.hapticsEnabled, isTrue);
    });

    test('copyWith updates fields correctly', () {
      const settings = MouseSettings();
      final updated = settings.copyWith(
        sensitivity: 2.0,
        invertScroll: true,
      );
      expect(updated.sensitivity, 2.0);
      expect(updated.scrollSensitivity, 1.0);
      expect(updated.invertScroll, isTrue);
    });
  });

  group('HidKeyCodes & Character Mapping Tests', () {
    test('Maps lowercase letters correctly without shift', () {
      final a = HidKeyCodes.fromChar('a');
      expect(a, isNotNull);
      expect(a!.keyCode, HidKeyCodes.keyA);
      expect(a.modifier, HidModifiers.none);

      final z = HidKeyCodes.fromChar('z');
      expect(z, isNotNull);
      expect(z!.keyCode, HidKeyCodes.keyZ);
      expect(z.modifier, HidModifiers.none);
    });

    test('Maps uppercase letters correctly with shift modifier', () {
      final capA = HidKeyCodes.fromChar('A');
      expect(capA, isNotNull);
      expect(capA!.keyCode, HidKeyCodes.keyA);
      expect(capA.modifier, HidModifiers.leftShift);

      final capZ = HidKeyCodes.fromChar('Z');
      expect(capZ, isNotNull);
      expect(capZ!.keyCode, HidKeyCodes.keyZ);
      expect(capZ.modifier, HidModifiers.leftShift);
    });

    test('Maps numbers and symbols with shift', () {
      final one = HidKeyCodes.fromChar('1');
      expect(one!.keyCode, HidKeyCodes.key1);
      expect(one.modifier, HidModifiers.none);

      final exclamation = HidKeyCodes.fromChar('!');
      expect(exclamation!.keyCode, HidKeyCodes.key1);
      expect(exclamation.modifier, HidModifiers.leftShift);

      final space = HidKeyCodes.fromChar(' ');
      expect(space!.keyCode, HidKeyCodes.keySpace);

      final enter = HidKeyCodes.fromChar('\n');
      expect(enter!.keyCode, HidKeyCodes.keyEnter);
    });
  });

  group('BluetoothHidRepository Unit Tests', () {
    test('Method channel calls sendMouseMovement with expected args', () async {
      final log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ezze.control/hid'),
        (MethodCall call) async {
          log.add(call);
          if (call.method == 'sendMouseMovement') return true;
          if (call.method == 'sendTestMouseMovement') return true;
          if (call.method == 'sendTestKey') return true;
          if (call.method == 'sendKeyboardReport') return true;
          if (call.method == 'releaseAllInputs') return true;
          if (call.method == 'getBondedDevices') {
            return [
              {'name': 'Windows PC', 'address': '11:22:33:44:55:66'}
            ];
          }
          return null;
        },
      );

      final repo = BluetoothHidRepository();
      final devices = await repo.getBondedDevices();
      expect(devices.length, 1);
      expect(devices.first['name'], 'Windows PC');

      final mouseResult = await repo.sendMouseMovement(dx: 15, dy: -20, buttons: 1);
      expect(mouseResult, isTrue);
      expect(log.last.method, 'sendMouseMovement');
      expect(log.last.arguments, {'buttons': 1, 'dx': 15, 'dy': -20, 'wheel': 0});

      final testMouse = await repo.sendTestMouseMovement();
      expect(testMouse, isTrue);

      final testKey = await repo.sendTestKey();
      expect(testKey, isTrue);

      final keyStrokeResult = await repo.sendKeyStroke(
        modifiers: HidModifiers.leftCtrl,
        keyCode: HidKeyCodes.keyC,
      );
      expect(keyStrokeResult, isTrue);

      final released = await repo.releaseAllInputs();
      expect(released, isTrue);
    });
  });

  group('Widget & Navigation Tests', () {
    testWidgets('Renders HomeShell, interacts with Keyboard and Touchpad', (WidgetTester tester) async {
      final methodCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ezze.control/hid'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          if (methodCall.method == 'getCapabilities') {
            return {
              'supportedApi': true,
              'sdkInt': 34,
              'deviceModel': 'Infinix X6833B',
              'androidVersion': '14',
              'bluetoothSupported': true,
              'bluetoothEnabled': true,
              'permissionsGranted': true,
              'missingPermissions': <String>[],
              'profileAvailable': true,
              'profilePending': false,
              'isRegistered': true,
              'isRegistering': false,
              'connectionState': 'CONNECTED',
              'connectedDeviceName': 'IMRAN-LAPTOP',
              'connectedDeviceAddress': '0C:7A:15:BF:D2:8F',
            };
          }
          if (methodCall.method == 'getBondedDevices') {
            return <Map<String, dynamic>>[];
          }
          if (methodCall.method == 'sendMouseMovement') {
            return true;
          }
          if (methodCall.method == 'sendKeyboardReport') {
            return true;
          }
          if (methodCall.method == 'releaseAllInputs') {
            return true;
          }
          return null;
        },
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = BluetoothHidRepository();
      final settingsRepo = SettingsRepository();
      await tester.pumpWidget(
        EzzeControlApp(
          repository: repo,
          settingsRepository: settingsRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Touchpad tab should be selected by default
      expect(find.text('Touchpad'), findsWidgets);
      expect(find.text('IMRAN-LAPTOP'), findsWidgets);
      expect(find.text('LEFT CLICK'), findsOneWidget);

      // Tap on Keyboard tab
      await tester.tap(find.text('Keyboard'));
      await tester.pumpAndSettle();

      // Keyboard screen should be displayed with QWERTY layout
      expect(find.text('SPACE'), findsOneWidget);
      expect(find.text('CTRL'), findsOneWidget);
      expect(find.text('ALT'), findsOneWidget);
      expect(find.text('?123'), findsOneWidget);
      expect(find.text('Ctrl+C'), findsOneWidget);
      expect(find.text('Win+D'), findsOneWidget);

      // Tap on letter key 'a'
      await tester.tap(find.text('a'));
      await tester.pumpAndSettle();

      // Tap on ?123 symbols layer switch
      await tester.tap(find.text('?123'));
      await tester.pumpAndSettle();
      expect(find.text('ABC'), findsWidgets);

      // Tap on ABC to switch back to QWERTY
      await tester.tap(find.text('ABC').first);
      await tester.pumpAndSettle();
      expect(find.text('?123'), findsOneWidget);

      // Tap on Connectivity tab
      await tester.tap(find.text('Connectivity'));
      await tester.pumpAndSettle();
      expect(find.text('Phase 2 — Windows HID Verification'), findsOneWidget);
      expect(find.text('Live Diagnostics Log'), findsOneWidget);
    });
  });
}
