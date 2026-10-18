import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../domain/models/hid_key_codes.dart';

class FunctionKeysBar extends StatelessWidget {
  final Function(int keyCode) onKeyPress;
  final int activeModifiers;

  const FunctionKeysBar({
    super.key,
    required this.onKeyPress,
    required this.activeModifiers,
  });

  @override
  Widget build(BuildContext context) {
    final fKeys = [
      {'label': 'ESC', 'code': HidKeyCodes.keyEscape, 'special': true},
      {'label': 'TAB', 'code': HidKeyCodes.keyTab, 'special': true},
      {'label': 'F1', 'code': HidKeyCodes.keyF1, 'special': false},
      {'label': 'F2', 'code': HidKeyCodes.keyF2, 'special': false},
      {'label': 'F3', 'code': HidKeyCodes.keyF3, 'special': false},
      {'label': 'F4', 'code': HidKeyCodes.keyF4, 'special': false},
      {'label': 'F5', 'code': HidKeyCodes.keyF5, 'special': false},
      {'label': 'F6', 'code': HidKeyCodes.keyF6, 'special': false},
      {'label': 'F7', 'code': HidKeyCodes.keyF7, 'special': false},
      {'label': 'F8', 'code': HidKeyCodes.keyF8, 'special': false},
      {'label': 'F9', 'code': HidKeyCodes.keyF9, 'special': false},
      {'label': 'F10', 'code': HidKeyCodes.keyF10, 'special': false},
      {'label': 'F11', 'code': HidKeyCodes.keyF11, 'special': false},
      {'label': 'F12', 'code': HidKeyCodes.keyF12, 'special': false},
      {'label': 'INS', 'code': HidKeyCodes.keyInsert, 'special': true},
      {'label': 'DEL', 'code': HidKeyCodes.keyDelete, 'special': true},
      {'label': 'HOME', 'code': HidKeyCodes.keyHome, 'special': true},
      {'label': 'END', 'code': HidKeyCodes.keyEnd, 'special': true},
      {'label': 'PGUP', 'code': HidKeyCodes.keyPageUp, 'special': true},
      {'label': 'PGDN', 'code': HidKeyCodes.keyPageDown, 'special': true},
      {'label': 'PRTSC', 'code': HidKeyCodes.keyPrintScreen, 'special': true},
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: fKeys.length,
        separatorBuilder: (context, index) => const SizedBox(width: 4),
        itemBuilder: (context, index) {
          final item = fKeys[index];
          final label = item['label'] as String;
          final code = item['code'] as int;
          final isSpecial = item['special'] as bool;

          return SizedBox(
            width: label.length > 3 ? 54 : 46,
            child: Material(
              color: isSpecial ? AppTheme.surfaceHover : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onKeyPress(code),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSpecial ? AppTheme.primaryLight : AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
