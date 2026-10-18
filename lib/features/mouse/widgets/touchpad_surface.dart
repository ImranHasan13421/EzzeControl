import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';
import '../../../data/bluetooth_hid_repository.dart';
import '../../../domain/models/mouse_settings.dart';

class TouchpadSurface extends StatefulWidget {
  final BluetoothHidRepository repository;
  final MouseSettings settings;
  final int activeButtons;
  final bool isConnected;

  const TouchpadSurface({
    super.key,
    required this.repository,
    required this.settings,
    this.activeButtons = 0,
    required this.isConnected,
  });

  @override
  State<TouchpadSurface> createState() => _TouchpadSurfaceState();
}

class _TouchpadSurfaceState extends State<TouchpadSurface> {
  final Map<int, Offset> _pointers = {};
  final Map<int, Offset> _pointerDownPos = {};
  final Map<int, DateTime> _pointerDownTime = {};

  Timer? _tapAndHoldTimer;
  bool _isDragging = false;
  bool _isDoubleTapCandidate = false;
  DateTime? _lastTapTime;
  Offset? _lastTapPos;

  // Active touch indicator state for visual ripple/pointer feedback
  Offset? _visualTouchPoint;
  bool _isMultiTouch = false;

  @override
  void dispose() {
    _tapAndHoldTimer?.cancel();
    if (_isDragging) {
      widget.repository.releaseAllInputs();
    }
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!widget.isConnected) return;

    final now = DateTime.now();
    _pointers[e.pointer] = e.position;
    _pointerDownPos[e.pointer] = e.position;
    _pointerDownTime[e.pointer] = now;

    setState(() {
      _visualTouchPoint = e.localPosition;
      _isMultiTouch = _pointers.length > 1;
    });

    if (_pointers.length == 1) {
      // Check for double-tap candidate
      if (_lastTapTime != null && _lastTapPos != null) {
        final elapsed = now.difference(_lastTapTime!).inMilliseconds;
        final dist = (e.position - _lastTapPos!).distance;
        if (elapsed < 300 && dist < 25) {
          _isDoubleTapCandidate = true;
        } else {
          _isDoubleTapCandidate = false;
        }
      }

      // Schedule tap-and-hold drag detection (320ms)
      _tapAndHoldTimer?.cancel();
      _tapAndHoldTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted || _pointers.length != 1) return;
        final downPos = _pointerDownPos[e.pointer];
        final currentPos = _pointers[e.pointer];
        if (downPos != null && currentPos != null) {
          final dist = (currentPos - downPos).distance;
          if (dist < 15.0) {
            // Tap and hold initiated -> engage left drag
            _isDragging = true;
            widget.repository.sendMouseMovement(
              buttons: widget.activeButtons | 0x01,
              dx: 0,
              dy: 0,
            );
            if (widget.settings.hapticsEnabled) {
              HapticFeedback.mediumImpact();
            }
          }
        }
      });
    } else {
      // Multi-touch active -> cancel drag detection
      _tapAndHoldTimer?.cancel();
      _isDoubleTapCandidate = false;
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!widget.isConnected || !_pointers.containsKey(e.pointer)) return;

    final oldPos = _pointers[e.pointer]!;
    final delta = e.position - oldPos;
    _pointers[e.pointer] = e.position;

    setState(() {
      _visualTouchPoint = e.localPosition;
    });

    final downPos = _pointerDownPos[e.pointer];
    if (downPos != null && (e.position - downPos).distance > 12.0) {
      // If finger moved significantly, cancel tap-and-hold timer if not yet dragging
      if (!_isDragging) {
        _tapAndHoldTimer?.cancel();
      }
    }

    if (_pointers.length == 1) {
      // Single finger: relative mouse movement
      double dx = delta.dx * widget.settings.sensitivity;
      double dy = delta.dy * widget.settings.sensitivity;

      // Pointer acceleration
      if (widget.settings.accelerationEnabled) {
        final dist = math.sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
        if (dist > 6.0) {
          final accel = 1.0 + (math.min(dist, 32.0) - 6.0) / 26.0 * 0.75;
          dx *= accel;
          dy *= accel;
        }
      }

      final clampedX = dx.round().clamp(-127, 127);
      final clampedY = dy.round().clamp(-127, 127);

      if (clampedX != 0 || clampedY != 0) {
        final currentButtons = _isDragging
            ? (widget.activeButtons | 0x01)
            : widget.activeButtons;
        widget.repository.sendMouseMovement(
          buttons: currentButtons,
          dx: clampedX,
          dy: clampedY,
        );
      }
    } else if (_pointers.length == 2) {
      // Two fingers: vertical scroll wheel
      _tapAndHoldTimer?.cancel();
      _isDoubleTapCandidate = false;

      // Vertical delta for scroll
      double rawDy = delta.dy * widget.settings.scrollSensitivity * 0.8;
      if (widget.settings.invertScroll) {
        rawDy = -rawDy;
      }

      // Windows HID Wheel: positive is UP, negative is DOWN
      // Moving fingers up (delta.dy < 0) naturally means scroll UP (+wheel)
      final wheelVal = (-rawDy).round().clamp(-127, 127);
      if (wheelVal != 0) {
        widget.repository.sendMouseMovement(
          buttons: widget.activeButtons,
          dx: 0,
          dy: 0,
          wheel: wheelVal,
        );
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!widget.isConnected) {
      _cleanupPointer(e.pointer);
      return;
    }

    final now = DateTime.now();
    _tapAndHoldTimer?.cancel();

    final downTime = _pointerDownTime[e.pointer];
    final downPos = _pointerDownPos[e.pointer];
    final durationMs = downTime != null ? now.difference(downTime).inMilliseconds : 999;
    final displacement = downPos != null ? (e.position - downPos).distance : 999.0;

    if (_isDragging) {
      // Drag & drop released
      _isDragging = false;
      widget.repository.sendMouseMovement(
        buttons: widget.activeButtons,
        dx: 0,
        dy: 0,
      );
      if (widget.settings.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
    } else if (_pointers.length == 1 && widget.settings.tapToClick) {
      // Single finger tap detection
      if (displacement < 14.0 && durationMs < 260) {
        if (_isDoubleTapCandidate) {
          // Double tap -> double click
          _sendLeftClick();
          Future.delayed(const Duration(milliseconds: 60), () {
            _sendLeftClick();
          });
          _isDoubleTapCandidate = false;
        } else {
          // Single tap -> left click
          _sendLeftClick();
          _lastTapTime = now;
          _lastTapPos = e.position;
        }
      }
    } else if (_pointers.length == 2 && widget.settings.tapToClick) {
      // Two-finger tap -> Right Click
      if (displacement < 18.0 && durationMs < 280) {
        _sendRightClick();
      }
    }

    _cleanupPointer(e.pointer);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _tapAndHoldTimer?.cancel();
    if (_isDragging) {
      _isDragging = false;
      widget.repository.releaseAllInputs();
    }
    _cleanupPointer(e.pointer);
  }

  void _cleanupPointer(int pointerId) {
    _pointers.remove(pointerId);
    _pointerDownPos.remove(pointerId);
    _pointerDownTime.remove(pointerId);

    if (mounted) {
      setState(() {
        if (_pointers.isEmpty) {
          _visualTouchPoint = null;
          _isMultiTouch = false;
        } else {
          _isMultiTouch = _pointers.length > 1;
        }
      });
    }
  }

  Future<void> _sendLeftClick() async {
    if (widget.settings.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    // Left Down (0x01)
    await widget.repository.sendMouseMovement(
      buttons: widget.activeButtons | 0x01,
      dx: 0,
      dy: 0,
    );
    await Future.delayed(const Duration(milliseconds: 35));
    // Left Up
    await widget.repository.sendMouseMovement(
      buttons: widget.activeButtons,
      dx: 0,
      dy: 0,
    );
  }

  Future<void> _sendRightClick() async {
    if (widget.settings.hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    // Right Down (0x02)
    await widget.repository.sendMouseMovement(
      buttons: widget.activeButtons | 0x02,
      dx: 0,
      dy: 0,
    );
    await Future.delayed(const Duration(milliseconds: 40));
    // Right Up
    await widget.repository.sendMouseMovement(
      buttons: widget.activeButtons,
      dx: 0,
      dy: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isDragging
                ? AppTheme.primary
                : (_isMultiTouch
                    ? AppTheme.info.withValues(alpha: 0.6)
                    : AppTheme.borderSubtle),
            width: _isDragging ? 2.0 : 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Subtle background guide lines / grid
              Positioned.fill(
                child: CustomPaint(
                  painter: _TouchpadGridPainter(
                    isDragging: _isDragging,
                    isMultiTouch: _isMultiTouch,
                  ),
                ),
              ),

              // Status indicator overlay if disconnected or dragging
              if (!widget.isConnected)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled_rounded,
                        color: AppTheme.textMuted.withValues(alpha: 0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Touchpad Inactive',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Connect to a Windows PC to control cursor',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_isDragging)
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pan_tool, color: AppTheme.primaryLight, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Drag & Drop Active',
                          style: TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isMultiTouch)
                Positioned(
                  top: 14,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.info),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.unfold_more, color: AppTheme.info, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Two-Finger Scrolling',
                          style: TextStyle(
                            color: AppTheme.info,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Touch cursor / ripple follower
              if (_visualTouchPoint != null && widget.isConnected)
                Positioned(
                  left: _visualTouchPoint!.dx - 24,
                  top: _visualTouchPoint!.dy - 24,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_isDragging
                              ? AppTheme.primary
                              : (_isMultiTouch ? AppTheme.info : AppTheme.primaryLight))
                          .withValues(alpha: 0.2),
                      border: Border.all(
                        color: _isDragging
                            ? AppTheme.primary
                            : (_isMultiTouch ? AppTheme.info : AppTheme.primaryLight),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TouchpadGridPainter extends CustomPainter {
  final bool isDragging;
  final bool isMultiTouch;

  _TouchpadGridPainter({
    required this.isDragging,
    required this.isMultiTouch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    // Center crosshairs
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.drawLine(
      Offset(centerX - 16, centerY),
      Offset(centerX + 16, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - 16),
      Offset(centerX, centerY + 16),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TouchpadGridPainter oldDelegate) {
    return oldDelegate.isDragging != isDragging || oldDelegate.isMultiTouch != isMultiTouch;
  }
}
