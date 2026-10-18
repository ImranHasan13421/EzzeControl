import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';
import '../../../data/bluetooth_hid_repository.dart';
import '../../../data/settings_repository.dart';

class AppSettingsSheet extends StatefulWidget {
  final SettingsRepository settingsRepository;
  final BluetoothHidRepository hidRepository;

  const AppSettingsSheet({
    super.key,
    required this.settingsRepository,
    required this.hidRepository,
  });

  @override
  State<AppSettingsSheet> createState() => _AppSettingsSheetState();
}

class _AppSettingsSheetState extends State<AppSettingsSheet> {
  bool _keepAwake = true;
  int _defaultTab = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final awake = await widget.settingsRepository.getKeepScreenAwake();
    final tab = await widget.settingsRepository.getDefaultLandingTab();
    if (mounted) {
      setState(() {
        _keepAwake = awake;
        _defaultTab = tab;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleKeepAwake(bool val) async {
    setState(() => _keepAwake = val);
    await widget.settingsRepository.setKeepScreenAwake(val);
    await widget.hidRepository.setKeepScreenOn(val);
    HapticFeedback.selectionClick();
  }

  Future<void> _setDefaultTab(int tab) async {
    setState(() => _defaultTab = tab);
    await widget.settingsRepository.setDefaultLandingTab(tab);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.settings, color: AppTheme.primaryLight, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'General Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Keep Screen Awake',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Prevents phone from locking while using remote control',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  activeThumbColor: AppTheme.primary,
                  value: _keepAwake,
                  onChanged: _toggleKeepAwake,
                ),
                const Divider(height: 20),
                const Text(
                  'Default Starting Screen',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose which tab opens automatically on app launch',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Touchpad')),
                    ButtonSegment(value: 1, label: Text('Keyboard')),
                    ButtonSegment(value: 2, label: Text('Devices')),
                  ],
                  selected: {_defaultTab},
                  onSelectionChanged: (set) {
                    if (set.isNotEmpty) {
                      _setDefaultTab(set.first);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primary.withValues(alpha: 0.3);
                      }
                      return AppTheme.surfaceVariant;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryLight;
                      }
                      return AppTheme.textSecondary;
                    }),
                  ),
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icons/app_logo.png',
                        width: 32,
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ezze Control v1.0.0',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Bluetooth HID standard • Zero PC software',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
