import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';
import '../../../data/bluetooth_hid_repository.dart';
import '../../../domain/models/mouse_settings.dart';

/// Ultra-responsive, smooth Touchpad surface implementing:
/// 1. Sub-pixel residual accumulation (zero deadzone, pixel-perfect micro-targeting).
/// 2. Adaptive low-pass jitter filter (Dual-Alpha filter: smooth at low speeds, raw zero-latency at high speeds).
/// 3. Continuous smooth power-curve ballistics acceleration (effortless swipes across PC screens).
/// 4. In-flight coalescing dispatcher (strictly 1 IPC message in flight, zero queue delay, instant stopping).
/// 5. ValueNotifier-driven visual feedback (zero widget tree rebuilds during touch moves for solid 120 FPS).
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
  // Active touch points tracking
  final Map<int, Offset> _pointers = {};
  final Map<int, Offset> _pointerDownPos = {};
  final Map<int, DateTime> _pointerDownTime = {};

  // Timing and velocity tracking
  DateTime? _lastMoveTime;
  double _filteredDx = 0.0;
  double _filteredDy = 0.0;

  // Sub-pixel residual accumulators (crucial for physical wireless mouse precision)
  double _residualDx = 0.0;
  double _residualDy = 0.0;
  double _residualWheel = 0.0;

  // Coalescing dispatcher queue (prevents platform channel congestion & latency buildup)
  int _queuedDx = 0;
  int _queuedDy = 0;
  int _queuedWheel = 0;
  bool _isDispatching = false;

  // Gestures & state
  Timer? _tapAndHoldTimer;
  bool _isDragging = false;
  bool _isDoubleTapCandidate = false;
  DateTime? _lastTapTime;
  Offset? _lastTapPos;

  // ValueNotifiers for isolated 120 FPS visual updates without rebuilding widget tree
  final ValueNotifier<Offset?> _touchPointNotifier = ValueNotifier<Offset?>(null);
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isMultiTouchNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _tapAndHoldTimer?.cancel();
    if (_isDragging) {
      widget.repository.releaseAllInputs();
    }
    _touchPointNotifier.dispose();
    _isDraggingNotifier.dispose();
    _isMultiTouchNotifier.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (!widget.isConnected) return;

    final now = DateTime.now();
    _pointers[e.pointer] = e.position;
    _pointerDownPos[e.pointer] = e.position;
    _pointerDownTime[e.pointer] = now;

    // Reset smoothing & timing state on new touch contact
    _lastMoveTime = now;
    _filteredDx = 0.0;
    _filteredDy = 0.0;

    _touchPointNotifier.value = e.localPosition;
    _isMultiTouchNotifier.value = _pointers.length > 1;

    if (_pointers.length == 1) {
      // Check for double-tap candidate (< 300ms, < 24px)
      if (_lastTapTime != null && _lastTapPos != null) {
        final elapsed = now.difference(_lastTapTime!).inMilliseconds;
        final dist = (e.position - _lastTapPos!).distance;
        _isDoubleTapCandidate = (elapsed < 300 && dist < 24.0);
      } else {
        _isDoubleTapCandidate = false;
      }

      // Schedule tap-and-hold drag detection (320ms)
      _tapAndHoldTimer?.cancel();
      _tapAndHoldTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted || _pointers.length != 1) return;
        final downPos = _pointerDownPos[e.pointer];
        final currentPos = _pointers[e.pointer];
        if (downPos != null && currentPos != null) {
          final dist = (currentPos - downPos).distance;
          if (dist < 14.0) {
            // Engage Left Drag
            _isDragging = true;
            _isDraggingNotifier.value = true;
            _queueMovement(0, 0, 0); // Immediately inform host of left button hold
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

    final now = DateTime.now();
    final prevPos = _pointers[e.pointer]!;
    final rawDelta = e.position - prevPos;
    _pointers[e.pointer] = e.position;

    // Fast isolated visual indicator update (0 full widget rebuilds!)
    _touchPointNotifier.value = e.localPosition;

    // Cancel tap-and-hold timer if finger moved beyond stationary radius
    final downPos = _pointerDownPos[e.pointer];
    if (downPos != null && (e.position - downPos).distance > 10.0) {
      if (!_isDragging) {
        _tapAndHoldTimer?.cancel();
      }
    }

    if (_pointers.length == 1) {
      // Calculate elapsed time in milliseconds for velocity
      final dtMs = _lastMoveTime != null
          ? (now.difference(_lastMoveTime!).inMicroseconds / 1000.0).clamp(1.0, 80.0)
          : 16.0;
      _lastMoveTime = now;

      // Velocity in pixels per millisecond
      final rawDist = rawDelta.distance;
      final velocity = rawDist / dtMs;

      // 1. Adaptive Low-Pass Filter (Dual-Alpha):
      // - Low speeds (< 0.15 px/ms): alpha is 0.65 to cancel digitizer noise & jitter
      // - High speeds (> 0.75 px/ms): alpha is 1.0 (raw input, zero delay)
      final double alpha;
      if (velocity < 0.15) {
        alpha = 0.65;
      } else if (velocity > 0.75) {
        alpha = 1.0;
      } else {
        alpha = 0.65 + ((velocity - 0.15) / 0.60) * 0.35;
      }

      _filteredDx = alpha * rawDelta.dx + (1.0 - alpha) * _filteredDx;
      _filteredDy = alpha * rawDelta.dy + (1.0 - alpha) * _filteredDy;

      // 2. Smooth Continuous Ballistics Acceleration
      double accel = 1.0;
      if (widget.settings.accelerationEnabled) {
        if (velocity > 0.20) {
          // Smooth power curve with natural falloff
          final normV = (velocity - 0.20) / 0.35;
          accel = 1.0 + math.min(2.8, 0.48 * math.pow(normV, 1.25));
        } else {
          // Precision micro-targeting dampener
          accel = 0.94;
        }
      }

      // Base scale calibrated for smooth Windows desktop control
      const double baseScale = 1.45;
      final targetDx = _filteredDx * widget.settings.sensitivity * baseScale * accel;
      final targetDy = _filteredDy * widget.settings.sensitivity * baseScale * accel;

      // 3. Sub-Pixel Precision Accumulator (Zero Deadzone!)
      _residualDx += targetDx;
      _residualDy += targetDy;

      final int sendX = _residualDx.truncate();
      final int sendY = _residualDy.truncate();

      _residualDx -= sendX;
      _residualDy -= sendY;

      if (sendX != 0 || sendY != 0) {
        _queueMovement(sendX, sendY, 0);
      }
    } else if (_pointers.length == 2) {
      // Two-Finger Vertical Scroll Wheel
      _tapAndHoldTimer?.cancel();
      _isDoubleTapCandidate = false;

      // Natural vs Inverted vertical scroll
      double rawDy = rawDelta.dy * widget.settings.scrollSensitivity * 1.35;
      if (widget.settings.invertScroll) {
        rawDy = -rawDy;
      }

      // Windows HID Wheel: moving fingers up (delta.dy < 0) naturally scrolls UP (+wheel)
      _residualWheel += (-rawDy);
      final int sendWheel = _residualWheel.truncate();
      _residualWheel -= sendWheel;

      if (sendWheel != 0) {
        _queueMovement(0, 0, sendWheel);
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
      _isDraggingNotifier.value = false;
      _queueMovement(0, 0, 0); // Immediately release left button hold
      if (widget.settings.hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
    } else if (_pointers.length == 1 && widget.settings.tapToClick) {
      // Single finger tap detection (< 12px displacement, < 240ms duration)
      if (displacement < 12.0 && durationMs < 240) {
        if (_isDoubleTapCandidate) {
          // Double click
          _sendLeftClick();
          Future.delayed(const Duration(milliseconds: 55), () {
            _sendLeftClick();
          });
          _isDoubleTapCandidate = false;
        } else {
          // Single left click
          _sendLeftClick();
          _lastTapTime = now;
          _lastTapPos = e.position;
        }
      }
    } else if (_pointers.length == 2 && widget.settings.tapToClick) {
      // Two-finger tap -> Right Click
      if (displacement < 16.0 && durationMs < 260) {
        _sendRightClick();
      }
    }

    _cleanupPointer(e.pointer);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _tapAndHoldTimer?.cancel();
    if (_isDragging) {
      _isDragging = false;
      _isDraggingNotifier.value = false;
      widget.repository.releaseAllInputs();
    }
    _cleanupPointer(e.pointer);
  }

  void _cleanupPointer(int pointerId) {
    _pointers.remove(pointerId);
    _pointerDownPos.remove(pointerId);
    _pointerDownTime.remove(pointerId);

    if (_pointers.isEmpty) {
      _touchPointNotifier.value = null;
      _isMultiTouchNotifier.value = false;
      _filteredDx = 0.0;
      _filteredDy = 0.0;
      _lastMoveTime = null;
    } else {
      _isMultiTouchNotifier.value = _pointers.length > 1;
    }
  }

  /// Queues movement deltas and starts coalescing dispatch loop if idle.
  /// Guarantees that at most 1 IPC call is in flight across platform channel at any time,
  /// completely eliminating backlog latency and providing wireless-mouse responsiveness.
  void _queueMovement(int dx, int dy, int wheel) {
    _queuedDx += dx;
    _queuedDy += dy;
    _queuedWheel += wheel;

    if (!_isDispatching) {
      _dispatchLoop();
    }
  }

  Future<void> _dispatchLoop() async {
    if (_isDispatching) return;
    _isDispatching = true;

    while (mounted && (_queuedDx != 0 || _queuedDy != 0 || _queuedWheel != 0 || _isDragging)) {
      final toSendX = _queuedDx.clamp(-127, 127);
      final toSendY = _queuedDy.clamp(-127, 127);
      final toSendWheel = _queuedWheel.clamp(-127, 127);

      _queuedDx -= toSendX;
      _queuedDy -= toSendY;
      _queuedWheel -= toSendWheel;

      final currentButtons = _isDragging
          ? (widget.activeButtons | 0x01)
          : widget.activeButtons;

      try {
        await widget.repository.sendMouseMovement(
          buttons: currentButtons,
          dx: toSendX,
          dy: toSendY,
          wheel: toSendWheel,
        );
      } catch (_) {}

      // If no more deltas remain and not dragging, exit loop
      if (_queuedDx == 0 && _queuedDy == 0 && _queuedWheel == 0) {
        break;
      }
    }

    _isDispatching = false;
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
    await Future.delayed(const Duration(milliseconds: 30));
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
    await Future.delayed(const Duration(milliseconds: 35));
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
      child: AnimatedBuilder(
        animation: Listenable.merge([_isDraggingNotifier, _isMultiTouchNotifier]),
        builder: (context, _) {
          final isDragging = _isDraggingNotifier.value;
          final isMultiTouch = _isMultiTouchNotifier.value;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDragging
                    ? AppTheme.primary
                    : (isMultiTouch
                        ? AppTheme.info.withValues(alpha: 0.6)
                        : AppTheme.borderSubtle),
                width: isDragging ? 2.0 : 1.2,
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
                        isDragging: isDragging,
                        isMultiTouch: isMultiTouch,
                      ),
                    ),
                  ),

                  // Status indicator overlay if disconnected
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
                  else if (isDragging)
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
                  else if (isMultiTouch)
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

                  // Isolated visual touch point follower (runs without rebuilding container or canvas)
                  ValueListenableBuilder<Offset?>(
                    valueListenable: _touchPointNotifier,
                    builder: (context, touchPos, _) {
                      if (touchPos == null || !widget.isConnected) {
                        return const SizedBox.shrink();
                      }
                      return Positioned(
                        left: touchPos.dx - 22,
                        top: touchPos.dy - 22,
                        child: IgnorePointer(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isDragging
                                      ? AppTheme.primary
                                      : (isMultiTouch ? AppTheme.info : AppTheme.primaryLight))
                                  .withValues(alpha: 0.18),
                              border: Border.all(
                                color: isDragging
                                    ? AppTheme.primary
                                    : (isMultiTouch ? AppTheme.info : AppTheme.primaryLight),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
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
