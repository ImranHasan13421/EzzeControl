import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../data/bluetooth_hid_repository.dart';
import '../../data/settings_repository.dart';
import '../../domain/models/hid_status.dart';
import '../connectivity/connectivity_screen.dart';
import '../keyboard/keyboard_screen.dart';
import '../mouse/mouse_screen.dart';

class HomeShell extends StatefulWidget {
  final BluetoothHidRepository repository;
  final SettingsRepository settingsRepository;

  const HomeShell({
    super.key,
    required this.repository,
    required this.settingsRepository,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  HidStatus _status = const HidStatus();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSettingsAndStatus();
    widget.repository.eventStream.listen((_) {
      if (mounted) _refreshStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initSettingsAndStatus();
    } else if (state == AppLifecycleState.paused) {
      widget.repository.releaseAllInputs();
    }
  }

  Future<void> _initSettingsAndStatus() async {
    final keepAwake = await widget.settingsRepository.getKeepScreenAwake();
    await widget.repository.setKeepScreenOn(keepAwake);

    final defaultTab = await widget.settingsRepository.getDefaultLandingTab();
    var status = await widget.repository.getCapabilities();

    // Auto-register HID profile if permissions are granted
    if (status.permissionsGranted && !status.isRegistered) {
      await widget.repository.requestHidRegistration();
      await Future.delayed(const Duration(milliseconds: 400));
      status = await widget.repository.getCapabilities();
    }

    if (mounted) {
      setState(() {
        _status = status;
        if (_currentIndex == 0 && defaultTab != 0 && !status.isConnected) {
          _currentIndex = defaultTab;
        }
      });
    }
  }

  Future<void> _refreshStatus() async {
    final status = await widget.repository.getCapabilities();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      // Release any active inputs on tab change to prevent stuck keys/buttons
      widget.repository.releaseAllInputs();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _navigateToConnectivity() {
    _onTabSelected(2);
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _status.isConnected;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MouseScreen(
            repository: widget.repository,
            settingsRepository: widget.settingsRepository,
            onNavigateToConnectivity: _navigateToConnectivity,
          ),
          KeyboardScreen(
            repository: widget.repository,
            settingsRepository: widget.settingsRepository,
            onNavigateToConnectivity: _navigateToConnectivity,
          ),
          ConnectivityScreen(
            repository: widget.repository,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: AppTheme.border, width: 1.0),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                );
              }
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: AppTheme.primaryLight,
                  size: 24,
                );
              }
              return const IconThemeData(
                color: AppTheme.textMuted,
                size: 22,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: AppTheme.surface,
            elevation: 0,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.mouse_outlined),
                selectedIcon: Icon(Icons.mouse),
                label: 'Touchpad',
              ),
              const NavigationDestination(
                icon: Icon(Icons.keyboard_outlined),
                selectedIcon: Icon(Icons.keyboard),
                label: 'Keyboard',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: isConnected,
                  backgroundColor: AppTheme.success,
                  smallSize: 8,
                  child: const Icon(Icons.bluetooth_audio),
                ),
                selectedIcon: Badge(
                  isLabelVisible: isConnected,
                  backgroundColor: AppTheme.success,
                  smallSize: 8,
                  child: const Icon(Icons.bluetooth_connected),
                ),
                label: 'Connectivity',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
