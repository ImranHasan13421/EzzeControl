import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../data/bluetooth_hid_repository.dart';
import '../../data/settings_repository.dart';
import '../../domain/models/hid_status.dart';
import '../../domain/models/mouse_settings.dart';
import 'widgets/mouse_buttons_bar.dart';
import 'widgets/mouse_settings_sheet.dart';
import 'widgets/scroll_strip.dart';
import 'widgets/touchpad_surface.dart';

class MouseScreen extends StatefulWidget {
  final BluetoothHidRepository repository;
  final SettingsRepository settingsRepository;
  final VoidCallback? onNavigateToConnectivity;

  const MouseScreen({
    super.key,
    required this.repository,
    required this.settingsRepository,
    this.onNavigateToConnectivity,
  });

  @override
  State<MouseScreen> createState() => _MouseScreenState();
}

class _MouseScreenState extends State<MouseScreen> with WidgetsBindingObserver {
  HidStatus _status = const HidStatus();
  MouseSettings _settings = const MouseSettings();
  int _activeButtons = 0;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _refreshStatus();

    _eventSubscription = widget.repository.eventStream.listen((event) {
      if (mounted) {
        _refreshStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    widget.repository.releaseAllInputs();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      widget.repository.releaseAllInputs();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await widget.settingsRepository.loadMouseSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MouseSettingsSheet(
        initialSettings: _settings,
        onSettingsChanged: (newSettings) {
          setState(() {
            _settings = newSettings;
          });
          widget.settingsRepository.saveMouseSettings(newSettings);
        },
      ),
    );
  }

  Future<void> _emergencyRelease() async {
    setState(() {
      _activeButtons = 0;
    });
    await widget.repository.releaseAllInputs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All mouse & keyboard inputs released.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppTheme.surfaceVariant,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _status.isConnected;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.mouse,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Touchpad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.back_hand_outlined),
            tooltip: 'Emergency Release Inputs',
            onPressed: _emergencyRelease,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Touchpad Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Column(
            children: [
              // Host status bar
              _buildHostStatusBar(isConnected),
              const SizedBox(height: 10),

              // Main Touchpad Area with side scroll strip
              Expanded(
                child: Row(
                  children: [
                    // Main Touchpad
                    Expanded(
                      child: TouchpadSurface(
                        repository: widget.repository,
                        settings: _settings,
                        activeButtons: _activeButtons,
                        isConnected: isConnected,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Dedicated Scroll Strip
                    ScrollStrip(
                      repository: widget.repository,
                      settings: _settings,
                      isConnected: isConnected,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Tactile Mouse Buttons Bar
              MouseButtonsBar(
                repository: widget.repository,
                isConnected: isConnected,
                hapticsEnabled: _settings.hapticsEnabled,
                onButtonsChanged: (buttons) {
                  setState(() {
                    _activeButtons = buttons;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostStatusBar(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppTheme.success : AppTheme.warning,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected
                      ? (_status.connectedDeviceName ?? 'Connected Host')
                      : 'No Host Connected',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isConnected
                      ? 'Active HID • ${_settings.sensitivity.toStringAsFixed(1)}x speed'
                      : 'Pair or connect via Bluetooth to use mouse',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isConnected && widget.onNavigateToConnectivity != null)
            TextButton(
              onPressed: widget.onNavigateToConnectivity,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppTheme.primaryLight,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Connect', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
