import 'package:flutter/material.dart';
import '../../../domain/hid_key_codes.dart';

class NumberPadSheet extends StatelessWidget {
  final Function(int keyCode, {int modifier}) onKeyPressed;

  const NumberPadSheet({
    super.key,
    required this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    final numpadKeys = [
      [
        {'label': 'NumLock', 'code': HidKeyCodes.keyNumLock},
        {'label': '/', 'code': HidKeyCodes.keyKpSlash},
        {'label': '*', 'code': HidKeyCodes.keyKpAsterisk},
        {'label': 'Bksp', 'code': HidKeyCodes.keyBackspace},
      ],
      [
        {'label': '7', 'code': HidKeyCodes.keyKp7},
        {'label': '8', 'code': HidKeyCodes.keyKp8},
        {'label': '9', 'code': HidKeyCodes.keyKp9},
        {'label': '-', 'code': HidKeyCodes.keyKpMinus},
      ],
      [
        {'label': '4', 'code': HidKeyCodes.keyKp4},
        {'label': '5', 'code': HidKeyCodes.keyKp5},
        {'label': '6', 'code': HidKeyCodes.keyKp6},
        {'label': '+', 'code': HidKeyCodes.keyKpPlus},
      ],
      [
        {'label': '1', 'code': HidKeyCodes.keyKp1},
        {'label': '2', 'code': HidKeyCodes.keyKp2},
        {'label': '3', 'code': HidKeyCodes.keyKp3},
        {'label': 'Enter', 'code': HidKeyCodes.keyKpEnter, 'isAction': true},
      ],
      [
        {'label': '0', 'code': HidKeyCodes.keyKp0, 'flex': 2},
        {'label': '.', 'code': HidKeyCodes.keyKpDot},
        {'label': 'Del', 'code': HidKeyCodes.keyDelete},
      ],
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
                  'Number Pad',
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
            for (final row in numpadKeys)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    for (final key in row)
                      Expanded(
                        flex: key['flex'] as int? ?? 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: SizedBox(
                            height: 52,
                            child: Material(
                              color: (key['isAction'] == true)
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF283244),
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  onKeyPressed(key['code'] as int);
                                },
                                child: Center(
                                  child: Text(
                                    key['label'] as String,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: (key['isAction'] == true)
                                          ? Colors.white
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
