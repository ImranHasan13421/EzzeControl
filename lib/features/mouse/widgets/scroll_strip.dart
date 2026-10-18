import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';
import '../../../data/bluetooth_hid_repository.dart';
import '../../../domain/models/mouse_settings.dart';

class ScrollStrip extends StatefulWidget {
  final BluetoothHidRepository repository;
  final MouseSettings settings;
  final bool isConnected;

  const ScrollStrip({
    super.key,
    required this.repository,
    required this.settings,
    required this.isConnected,
  });

  @override
  State<ScrollStrip> createState() => _ScrollStripState();
}

class _ScrollStripState extends State<ScrollStrip> {
  bool _isInteracting = false;
  double _accumulatedDelta = 0.0;
  double _thumbPositionRatio = 0.5; // Visual feedback position

  void _onVerticalDragStart(DragStartDetails details) {
    if (!widget.isConnected) return;
    setState(() {
      _isInteracting = true;
      _accumulatedDelta = 0.0;
    });
    if (widget.settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!widget.isConnected) return;

    double dy = details.delta.dy;
    if (widget.settings.invertScroll) {
      dy = -dy;
    }

    _accumulatedDelta += dy;

    // Send wheel event every small step (e.g., 4 logical px)
    if (_accumulatedDelta.abs() >= 4.0) {
      // In Windows HID: positive is UP (+wheel), negative is DOWN (-wheel)
      // Dragging downward (dy > 0) means scroll down (-wheel)
      final wheelUnits = ((-_accumulatedDelta / 4.0) * widget.settings.scrollSensitivity * 3.0)
          .round()
          .clamp(-127, 127);

      if (wheelUnits != 0) {
        widget.repository.sendMouseMovement(
          buttons: 0,
          dx: 0,
          dy: 0,
          wheel: wheelUnits,
        );
        if (widget.settings.hapticsEnabled) {
          HapticFeedback.selectionClick();
        }
      }
      _accumulatedDelta = 0.0;
    }

    setState(() {
      _thumbPositionRatio = (_thumbPositionRatio + details.delta.dy / 300.0).clamp(0.1, 0.9);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    setState(() {
      _isInteracting = false;
      _thumbPositionRatio = 0.5;
    });
  }

  void _onVerticalDragCancel() {
    setState(() {
      _isInteracting = false;
      _thumbPositionRatio = 0.5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onVerticalDragCancel: _onVerticalDragCancel,
      child: Container(
        width: 38,
        decoration: BoxDecoration(
          color: _isInteracting
              ? AppTheme.surfaceHover
              : AppTheme.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isInteracting ? AppTheme.primaryLight : AppTheme.borderSubtle,
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(
                Icons.keyboard_arrow_up,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ),
            const Spacer(),
            // Animated tactile thumb indicator
            Container(
              width: 22,
              height: 48,
              decoration: BoxDecoration(
                color: _isInteracting
                    ? AppTheme.primary
                    : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isInteracting
                      ? AppTheme.primaryLight
                      : AppTheme.borderSubtle,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 2,
                      decoration: BoxDecoration(
                        color: _isInteracting ? Colors.white : AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 12,
                      height: 2,
                      decoration: BoxDecoration(
                        color: _isInteracting ? Colors.white : AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 12,
                      height: 2,
                      decoration: BoxDecoration(
                        color: _isInteracting ? Colors.white : AppTheme.textMuted,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
