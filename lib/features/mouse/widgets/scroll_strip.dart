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
  final ValueNotifier<bool> _isInteractingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<double> _thumbPositionRatio = ValueNotifier<double>(0.5);

  double _residualWheel = 0.0;
  int _queuedWheel = 0;
  bool _isDispatching = false;

  @override
  void dispose() {
    _isInteractingNotifier.dispose();
    _thumbPositionRatio.dispose();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (!widget.isConnected) return;
    _isInteractingNotifier.value = true;
    _residualWheel = 0.0;
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

    // Windows HID wheel: dragging downward (dy > 0) means scroll DOWN (-wheel)
    // Moving up (dy < 0) means scroll UP (+wheel)
    _residualWheel += (-dy * widget.settings.scrollSensitivity * 0.75);

    final int sendWheel = _residualWheel.truncate();
    _residualWheel -= sendWheel;

    if (sendWheel != 0) {
      _queueWheel(sendWheel);
      if (widget.settings.hapticsEnabled && sendWheel.abs() >= 2) {
        HapticFeedback.selectionClick();
      }
    }

    // Smooth visual thumb position update
    final currentRatio = _thumbPositionRatio.value;
    _thumbPositionRatio.value = (currentRatio + details.delta.dy / 280.0).clamp(0.12, 0.88);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isInteractingNotifier.value = false;
    _thumbPositionRatio.value = 0.5;
  }

  void _onVerticalDragCancel() {
    _isInteractingNotifier.value = false;
    _thumbPositionRatio.value = 0.5;
  }

  void _queueWheel(int wheelUnits) {
    _queuedWheel += wheelUnits;
    if (!_isDispatching) {
      _dispatchLoop();
    }
  }

  Future<void> _dispatchLoop() async {
    if (_isDispatching) return;
    _isDispatching = true;

    while (mounted && _queuedWheel != 0) {
      final toSend = _queuedWheel.clamp(-127, 127);
      _queuedWheel -= toSend;

      try {
        await widget.repository.sendMouseMovement(
          buttons: 0,
          dx: 0,
          dy: 0,
          wheel: toSend,
        );
      } catch (_) {}
    }

    _isDispatching = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      onVerticalDragCancel: _onVerticalDragCancel,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isInteractingNotifier,
        builder: (context, isInteracting, _) {
          return Container(
            width: 38,
            decoration: BoxDecoration(
              color: isInteracting
                  ? AppTheme.surfaceHover
                  : AppTheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isInteracting ? AppTheme.primaryLight : AppTheme.borderSubtle,
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _thumbPositionRatio,
                        builder: (context, ratio, _) {
                          final thumbY = (constraints.maxHeight - 48) * ratio;
                          return Stack(
                            children: [
                              Positioned(
                                top: thumbY.clamp(0.0, constraints.maxHeight - 48),
                                left: 7,
                                child: Container(
                                  width: 24,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isInteracting
                                        ? AppTheme.primary
                                        : AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isInteracting
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
                                            color: isInteracting ? Colors.white : AppTheme.textMuted,
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          width: 12,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: isInteracting ? Colors.white : AppTheme.textMuted,
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          width: 12,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            color: isInteracting ? Colors.white : AppTheme.textMuted,
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
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
          );
        },
      ),
    );
  }
}
