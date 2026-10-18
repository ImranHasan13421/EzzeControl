import 'package:flutter_test/flutter_test.dart';
import 'package:ezze_control/domain/models.dart';
import 'package:ezze_control/domain/hid_key_codes.dart';
import 'package:ezze_control/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Domain Models Test', () {
    test('BtDevice parsing and computer detection', () {
      final map = {
        'name': 'IMRAN-LAPTOP',
        'address': '0C:7A:15:BF:D2:8F',
        'type': 1,
        'deviceClass': 260,
        'majorDeviceClass': 256,
        'isConnected': true,
        'isBonded': true,
      };

      final device = BtDevice.fromMap(map);
      expect(device.name, 'IMRAN-LAPTOP');
      expect(device.address, '0C:7A:15:BF:D2:8F');
      expect(device.isComputer, true);
      expect(device.isConnected, true);
    });

    test('HidKeyCodes constants validity', () {
      expect(HidKeyCodes.keyF1, 0x3A);
      expect(HidKeyCodes.keyF12, 0x45);
      expect(HidKeyCodes.mouseButtonLeft, 0x01);
      expect(HidKeyCodes.mouseButtonRight, 0x02);
      expect(HidKeyCodes.keyEnter, 0x28);
    });
  });

  group('UI Smoke Test', () {
    testWidgets('Home screen renders 4 main options', (WidgetTester tester) async {
      await tester.pumpWidget(const EzzeControlApp());
      await tester.pumpAndSettle();

      expect(find.text('Ezze Control'), findsOneWidget);
      expect(find.text('Paired Devices'), findsOneWidget);
      expect(find.text('BT Devices'), findsOneWidget);
      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('App Guide'), findsOneWidget);
    });
  });
}
