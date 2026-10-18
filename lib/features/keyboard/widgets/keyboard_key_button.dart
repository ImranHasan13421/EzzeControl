import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/app_theme.dart';

class KeyboardKeyButton extends StatefulWidget {
  final String label;
  final String? subLabel;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isLatched;
  final bool isSpecial;
  final Color? activeColor;
  final int flex;

  const KeyboardKeyButton({
    super.key,
    required this.label,
    this.subLabel,
    this.icon,
    required this.onTap,
    this.onLongPress,
    this.isLatched = false,
    this.isSpecial = false,
    this.activeColor,
    this.flex = 1,
  });

  @override
  State<KeyboardKeyButton> createState() => _KeyboardKeyButtonState();
}

class _KeyboardKeyButtonState extends State<KeyboardKeyButton> {
  bool _isPressed = false;

  void _handleTapDown(_) {
    setState(() => _isPressed = true);
    HapticFeedback.selectionClick();
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.primary;
    final isActive = widget.isLatched || _isPressed;

    final bgColor = widget.isLatched
        ? activeColor.withValues(alpha: 0.35)
        : (_isPressed
            ? activeColor.withValues(alpha: 0.25)
            : (widget.isSpecial
                ? AppTheme.surfaceVariant
                : AppTheme.surfaceVariant.withValues(alpha: 0.7)));

    final borderColor = widget.isLatched
        ? activeColor
        : (_isPressed
            ? activeColor.withValues(alpha: 0.8)
            : AppTheme.borderSubtle);

    final textColor = widget.isLatched
        ? Colors.white
        : (_isPressed ? Colors.white : AppTheme.textPrimary);

    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 3.0),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onLongPress: widget.onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: borderColor, width: widget.isLatched ? 1.5 : 1.0),
              boxShadow: widget.isLatched
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: 18,
                      color: isActive ? Colors.white : AppTheme.textPrimary,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.subLabel != null)
                          Text(
                            widget.subLabel!,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: widget.label.length > 2 ? 11 : 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
