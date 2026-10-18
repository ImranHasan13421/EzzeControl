import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_theme.dart';
import 'data/bluetooth_hid_repository.dart';
import 'data/settings_repository.dart';
import 'features/home/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Dark navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final repository = BluetoothHidRepository();
  final settingsRepository = SettingsRepository();
  runApp(
    EzzeControlApp(
      repository: repository,
      settingsRepository: settingsRepository,
    ),
  );
}

class EzzeControlApp extends StatelessWidget {
  final BluetoothHidRepository repository;
  final SettingsRepository settingsRepository;

  const EzzeControlApp({
    super.key,
    required this.repository,
    required this.settingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ezze Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeShell(
        repository: repository,
        settingsRepository: settingsRepository,
      ),
    );
  }
}
