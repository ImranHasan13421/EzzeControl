import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../domain/models/hid_key_codes.dart';

class ShortcutsBar extends StatelessWidget {
  final Function(int modifiers, int keyCode) onShortcut;

  const ShortcutsBar({
    super.key,
    required this.onShortcut,
  });

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      {
        'title': 'Ctrl+C',
        'subtitle': 'Copy',
        'mods': HidModifiers.leftCtrl,
        'code': HidKeyCodes.keyC,
      },
      {
        'title': 'Ctrl+V',
        'subtitle': 'Paste',
        'mods': HidModifiers.leftCtrl,
        'code': HidKeyCodes.keyV,
      },
      {
        'title': 'Ctrl+Z',
        'subtitle': 'Undo',
        'mods': HidModifiers.leftCtrl,
        'code': HidKeyCodes.keyZ,
      },
      {
        'title': 'Ctrl+A',
        'subtitle': 'Select All',
        'mods': HidModifiers.leftCtrl,
        'code': HidKeyCodes.keyA,
      },
      {
        'title': 'Win+D',
        'subtitle': 'Desktop',
        'mods': HidModifiers.leftGui,
        'code': HidKeyCodes.keyD,
      },
      {
        'title': 'Win+E',
        'subtitle': 'Explorer',
        'mods': HidModifiers.leftGui,
        'code': HidKeyCodes.keyE,
      },
      {
        'title': 'Alt+Tab',
        'subtitle': 'Switch',
        'mods': HidModifiers.leftAlt,
        'code': HidKeyCodes.keyTab,
      },
      {
        'title': 'Win+L',
        'subtitle': 'Lock PC',
        'mods': HidModifiers.leftGui,
        'code': HidKeyCodes.keyL,
      },
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: shortcuts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final item = shortcuts[index];
          final title = item['title'] as String;
          final subtitle = item['subtitle'] as String;
          final mods = item['mods'] as int;
          final code = item['code'] as int;

          return Material(
            color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => onShortcut(mods, code),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
