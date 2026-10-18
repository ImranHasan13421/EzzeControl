import 'package:flutter/material.dart';
import '../../../domain/hid_key_codes.dart';

class FunctionKeysSheet extends StatelessWidget {
  final Function(int keyCode, {int modifier}) onKeyPressed;

  const FunctionKeysSheet({
    super.key,
    required this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    final functionKeys = [
      {'label': 'F1', 'code': HidKeyCodes.keyF1},
      {'label': 'F2', 'code': HidKeyCodes.keyF2},
      {'label': 'F3', 'code': HidKeyCodes.keyF3},
      {'label': 'F4', 'code': HidKeyCodes.keyF4},
      {'label': 'F5', 'code': HidKeyCodes.keyF5},
      {'label': 'F6', 'code': HidKeyCodes.keyF6},
      {'label': 'F7', 'code': HidKeyCodes.keyF7},
      {'label': 'F8', 'code': HidKeyCodes.keyF8},
      {'label': 'F9', 'code': HidKeyCodes.keyF9},
      {'label': 'F10', 'code': HidKeyCodes.keyF10},
      {'label': 'F11', 'code': HidKeyCodes.keyF11},
      {'label': 'F12', 'code': HidKeyCodes.keyF12},
    ];

    final controlKeys = [
      {'label': 'Esc', 'code': HidKeyCodes.keyEscape},
      {'label': 'Tab', 'code': HidKeyCodes.keyTab},
      {'label': 'Win', 'code': 0, 'mod': HidKeyCodes.modifierLeftGui},
      {'label': 'Ctrl', 'code': 0, 'mod': HidKeyCodes.modifierLeftCtrl},
      {'label': 'Alt', 'code': 0, 'mod': HidKeyCodes.modifierLeftAlt},
      {'label': 'Del', 'code': HidKeyCodes.keyDelete},
      {'label': 'Home', 'code': HidKeyCodes.keyHome},
      {'label': 'End', 'code': HidKeyCodes.keyEnd},
      {'label': 'PgUp', 'code': HidKeyCodes.keyPageUp},
      {'label': 'PgDn', 'code': HidKeyCodes.keyPageDown},
      {'label': 'Enter', 'code': HidKeyCodes.keyEnter},
      {'label': 'Bksp', 'code': HidKeyCodes.keyBackspace},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E222A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Function Keys',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // F1 - F12 Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: functionKeys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final item = functionKeys[index];
                return _buildKeyButton(
                  context: context,
                  label: item['label'] as String,
                  onTap: () {
                    onKeyPressed(item['code'] as int);
                  },
                  isFunctionKey: true,
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Control Keys',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 10),
            // Control Keys Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controlKeys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.8,
              ),
              itemBuilder: (context, index) {
                final item = controlKeys[index];
                return _buildKeyButton(
                  context: context,
                  label: item['label'] as String,
                  onTap: () {
                    final code = item['code'] as int;
                    final mod = item['mod'] as int? ?? 0;
                    onKeyPressed(code, modifier: mod);
                  },
                  isFunctionKey: false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
    required bool isFunctionKey,
  }) {
    return Material(
      color: isFunctionKey ? const Color(0xFF283244) : const Color(0xFF232832),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        splashColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isFunctionKey ? const Color(0xFF93C5FD) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
