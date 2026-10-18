import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';
import '../../../data/bluetooth_hid_repository.dart';

class MouseButtonsBar extends StatefulWidget {
  final BluetoothHidRepository repository;
  final bool isConnected;
  final bool hapticsEnabled;
  final ValueChanged<int> onButtonsChanged;

  const MouseButtonsBar({
    super.key,
    required this.repository,
    required this.isConnected,
    required this.hapticsEnabled,
    required this.onButtonsChanged,
  });

  @override
  State<MouseButtonsBar> createState() => _MouseButtonsBarState();
}

class _MouseButtonsBarState extends State<MouseButtonsBar> {
  int _activeButtons = 0;

  void _setButton(int bitmask, bool isDown) {
    if (!widget.isConnected) return;

    final newButtons = isDown ? (_activeButtons | bitmask) : (_activeButtons & ~bitmask);
    if (newButtons != _activeButtons) {
      setState(() {
        _activeButtons = newButtons;
      });
      widget.onButtonsChanged(_activeButtons);
      widget.repository.sendMouseMovement(
        buttons: _activeButtons,
        dx: 0,
        dy: 0,
      );

      if (widget.hapticsEnabled) {
        if (isDown) {
          HapticFeedback.selectionClick();
        } else {
          HapticFeedback.lightImpact();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leftDown = (_activeButtons & 0x01) != 0;
    final rightDown = (_activeButtons & 0x02) != 0;
    final middleDown = (_activeButtons & 0x04) != 0;

    return SizedBox(
      height: 72,
      child: Row(
        children: [
          // Left Click Button
          Expanded(
            flex: 5,
            child: _buildTactileButton(
              title: 'LEFT CLICK',
              subtitle: 'Select / Drag',
              icon: Icons.mouse,
              isPressed: leftDown,
              activeColor: AppTheme.primary,
              onDown: () => _setButton(0x01, true),
              onUp: () => _setButton(0x01, false),
            ),
          ),
          const SizedBox(width: 8),

          // Middle Click Button
          Expanded(
            flex: 2,
            child: _buildTactileButton(
              title: 'MID',
              subtitle: 'Wheel',
              icon: Icons.adjust,
              isPressed: middleDown,
              activeColor: AppTheme.info,
              onDown: () => _setButton(0x04, true),
              onUp: () => _setButton(0x04, false),
            ),
          ),
          const SizedBox(width: 8),

          // Right Click Button
          Expanded(
            flex: 4,
            child: _buildTactileButton(
              title: 'RIGHT CLICK',
              subtitle: 'Context Menu',
              icon: Icons.menu_open,
              isPressed: rightDown,
              activeColor: AppTheme.warning,
              onDown: () => _setButton(0x02, true),
              onUp: () => _setButton(0x02, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTactileButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isPressed,
    required Color activeColor,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    return Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp(),
      onPointerCancel: (_) => onUp(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        decoration: BoxDecoration(
          color: isPressed
              ? activeColor.withValues(alpha: 0.3)
              : AppTheme.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPressed ? activeColor : AppTheme.borderSubtle,
            width: isPressed ? 2.0 : 1.2,
          ),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isPressed ? activeColor : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isPressed ? Colors.white : AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isPressed ? Colors.white70 : AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
