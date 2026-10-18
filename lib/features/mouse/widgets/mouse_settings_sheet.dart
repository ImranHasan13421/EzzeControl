import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';
import '../../../domain/models/mouse_settings.dart';

class MouseSettingsSheet extends StatefulWidget {
  final MouseSettings initialSettings;
  final ValueChanged<MouseSettings> onSettingsChanged;

  const MouseSettingsSheet({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<MouseSettingsSheet> createState() => _MouseSettingsSheetState();
}

class _MouseSettingsSheetState extends State<MouseSettingsSheet> {
  late MouseSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  void _update(MouseSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
    if (_settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
                  Icon(Icons.tune, color: AppTheme.primaryLight, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Touchpad Preferences',
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
          const SizedBox(height: 16),
          // Sensitivity Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pointer Sensitivity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${_settings.sensitivity.toStringAsFixed(1)}x',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          Slider(
            value: _settings.sensitivity.clamp(0.4, 3.5),
            min: 0.4,
            max: 3.5,
            divisions: 31,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surfaceVariant,
            onChanged: (val) {
              _update(_settings.copyWith(sensitivity: val));
            },
          ),
          const SizedBox(height: 10),
          // Scroll Sensitivity Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Scroll Speed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '${_settings.scrollSensitivity.toStringAsFixed(1)}x',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          Slider(
            value: _settings.scrollSensitivity,
            min: 0.5,
            max: 3.0,
            divisions: 25,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surfaceVariant,
            onChanged: (val) {
              _update(_settings.copyWith(scrollSensitivity: val));
            },
          ),
          const Divider(height: 24),
          // Acceleration toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Pointer Acceleration',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Accelerate cursor dynamically on fast finger swipes',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            activeThumbColor: AppTheme.primary,
            value: _settings.accelerationEnabled,
            onChanged: (val) {
              _update(_settings.copyWith(accelerationEnabled: val));
            },
          ),
          // Invert scroll direction
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Invert Scroll Direction',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Reverse natural two-finger vertical scroll wheel',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            activeThumbColor: AppTheme.primary,
            value: _settings.invertScroll,
            onChanged: (val) {
              _update(_settings.copyWith(invertScroll: val));
            },
          ),
          // Tap to click
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Tap-to-Click',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Single tap for left click, two fingers for right click',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            activeThumbColor: AppTheme.primary,
            value: _settings.tapToClick,
            onChanged: (val) {
              _update(_settings.copyWith(tapToClick: val));
            },
          ),
          // Haptics toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Haptic Feedback',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Provide vibration pulses on taps, clicks, and scroll limits',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            activeThumbColor: AppTheme.primary,
            value: _settings.hapticsEnabled,
            onChanged: (val) {
              _update(_settings.copyWith(hapticsEnabled: val));
            },
          ),
        ],
      ),
    );
  }
}
