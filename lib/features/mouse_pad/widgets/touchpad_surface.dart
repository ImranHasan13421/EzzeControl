import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/bluetooth_hid_repository.dart';
import '../../../data/settings_repository.dart';

class TouchpadSurface extends StatefulWidget {
  final BluetoothHidRepository hidRepo;
  final SettingsRepository settingsRepo;

  const TouchpadSurface({
    super.key,
    required this.hidRepo,
    required this.settingsRepo,
  });

  @override
  State<TouchpadSurface> createState() => _TouchpadSurfaceState();
}

class _TouchpadSurfaceState extends State<TouchpadSurface> {
  // Tracking pointers
  final Map<int, Offset> _activePointers = {};
  Offset? _lastSinglePointerPos;
  double _accumulatedScrollY = 0;
  double _accumulatedDx = 0;
  double _accumulatedDy = 0;
  bool _isDispatching = false;

  // Tap & Drag state
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  bool _isDragging = false;
  bool _hasMoved = false;
  int _tapCount = 0;

  // Two finger detection
  bool _twoFingerTapPossible = false;
  DateTime? _twoFingerDownTime;

  void _dispatchMovement() {
    if (_isDispatching) return;

    final toSendX = _accumulatedDx.round().clamp(-127, 127);
    final toSendY = _accumulatedDy.round().clamp(-127, 127);

    if (toSendX == 0 && toSendY == 0) return;

    _accumulatedDx -= toSendX;
    _accumulatedDy -= toSendY;
    _isDispatching = true;

    widget.hidRepo.sendMouseMovement(
      dx: toSendX,
      dy: toSendY,
      buttons: _isDragging ? 1 : 0,
    ).then((_) {
      _isDispatching = false;
      if (_accumulatedDx.abs() >= 1.0 || _accumulatedDy.abs() >= 1.0) {
        _dispatchMovement();
      }
    }).catchError((_) {
      _isDispatching = false;
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;

    if (_activePointers.length == 1) {
      _lastSinglePointerPos = event.localPosition;
      _hasMoved = false;
      _accumulatedDx = 0;
      _accumulatedDy = 0;

      // Check for double tap and hold (Select & Drag)
      final now = DateTime.now();
      if (_lastTapTime != null &&
          _lastTapPosition != null &&
          now.difference(_lastTapTime!).inMilliseconds < 350 &&
          (event.localPosition - _lastTapPosition!).distance < 40) {
        // Double tap initiated! If moved, this will become drag.
        _tapCount = 2;
      } else {
        _tapCount = 1;
      }
    } else if (_activePointers.length == 2) {
      // Two finger interaction begins
      _twoFingerTapPossible = true;
      _twoFingerDownTime = DateTime.now();
      _accumulatedScrollY = 0;
      _accumulatedDx = 0;
      _accumulatedDy = 0;
      // If we were dragging with 1 finger, release it
      if (_isDragging) {
        _isDragging = false;
        widget.hidRepo.sendMouseUp();
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event.localPosition;

    if (_activePointers.length == 1) {
      final currentPos = event.localPosition;
      if (_lastSinglePointerPos != null) {
        final delta = currentPos - _lastSinglePointerPos!;
        final dist = delta.distance;

        if (dist > 0.4) {
          _hasMoved = true;

          // If second tap moved, lock into laptop-style Select & Drag!
          if (_tapCount == 2 && !_isDragging) {
            _isDragging = true;
            HapticFeedback.lightImpact();
            // Press left mouse button down
            widget.hidRepo.sendMouseDown(buttons: 1);
          }

          final speed = widget.settingsRepo.pointerSpeed;
          // Smooth progressive acceleration curve for pixel-perfect tracking & fast leaps
          final factor = (1.0 + (dist * 0.04).clamp(0.0, 3.0)) * speed;
          _accumulatedDx += delta.dx * factor;
          _accumulatedDy += delta.dy * factor;

          _dispatchMovement();
        }
      }
      _lastSinglePointerPos = currentPos;
    } else if (_activePointers.length == 2) {
      _twoFingerTapPossible = false;
      // Two finger vertical scrolling
      final deltaY = event.delta.dy;
      _accumulatedScrollY += deltaY * widget.settingsRepo.scrollSpeed;

      const scrollStep = 10.0;
      if (_accumulatedScrollY.abs() >= scrollStep) {
        final wheelSteps = -(_accumulatedScrollY / scrollStep).round();
        if (wheelSteps != 0) {
          widget.hidRepo.sendMouseMovement(
            dx: 0,
            dy: 0,
            buttons: 0,
            wheel: wheelSteps.clamp(-127, 127),
          );
          _accumulatedScrollY = 0;
        }
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    final liftedPos = _activePointers.remove(event.pointer);
    final now = DateTime.now();

    if (_activePointers.isEmpty) {
      // All fingers lifted
      if (_isDragging) {
        // Select & Drag finished, release mouse button
        _isDragging = false;
        widget.hidRepo.sendMouseUp();
        _lastTapTime = null;
        _lastTapPosition = null;
        _tapCount = 0;
      } else if (!_hasMoved && liftedPos != null) {
        // Single or double tap without drag
        if (_tapCount == 1) {
          _lastTapTime = now;
          _lastTapPosition = liftedPos;
          // Send single click
          widget.hidRepo.sendMouseClick('left');
          HapticFeedback.selectionClick();
        } else if (_tapCount == 2) {
          _lastTapTime = null;
          _lastTapPosition = null;
          _tapCount = 0;
          // Double click
          widget.hidRepo.sendMouseClick('left', isDouble: true);
          HapticFeedback.mediumImpact();
        }
      }

      _lastSinglePointerPos = null;
      _accumulatedScrollY = 0;
      _accumulatedDx = 0;
      _accumulatedDy = 0;
    } else if (_activePointers.length == 1 && _twoFingerTapPossible) {
      // Checked if it was a quick two-finger tap (Right Click)
      if (_twoFingerDownTime != null &&
          now.difference(_twoFingerDownTime!).inMilliseconds < 280) {
        widget.hidRepo.sendMouseClick('right');
        HapticFeedback.mediumImpact();
      }
      _twoFingerTapPossible = false;
      _lastSinglePointerPos = _activePointers.values.first;
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_isDragging) {
      _isDragging = false;
      widget.hidRepo.sendMouseUp();
    }
    if (_activePointers.isEmpty) {
      _lastSinglePointerPos = null;
      _accumulatedScrollY = 0;
      _accumulatedDx = 0;
      _accumulatedDy = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF22252C), // Touchpad surface matching 5th image
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isDragging ? const Color(0xFF3B82F6) : const Color(0xFF2D323C),
            width: _isDragging ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Drag indicator badge when active
            if (_isDragging)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Dragging',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Subtle center guide/indicator
            Center(
              child: Opacity(
                opacity: 0.12,
                child: Icon(
                  Icons.mouse,
                  size: 96,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),

            // Right Edge Scroll Strip Indicator
            Positioned(
              right: 2,
              top: 24,
              bottom: 24,
              width: 16,
              child: Center(
                child: Container(
                  width: 3,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
