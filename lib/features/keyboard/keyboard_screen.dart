import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../data/bluetooth_hid_repository.dart';
import '../../data/settings_repository.dart';
import '../../domain/models/hid_key_codes.dart';
import '../../domain/models/hid_status.dart';
import '../home/widgets/app_settings_sheet.dart';
import 'widgets/function_keys_bar.dart';
import 'widgets/keyboard_key_button.dart';
import 'widgets/shortcuts_bar.dart';
import 'widgets/text_input_bar.dart';

class KeyboardScreen extends StatefulWidget {
  final BluetoothHidRepository repository;
  final VoidCallback? onNavigateToConnectivity;

  final SettingsRepository? settingsRepository;

  const KeyboardScreen({
    super.key,
    required this.repository,
    this.settingsRepository,
    this.onNavigateToConnectivity,
  });

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> with WidgetsBindingObserver {
  HidStatus _status = const HidStatus();
  StreamSubscription? _eventSubscription;

  // Modifier latching state
  bool _shiftLatched = false;
  bool _capsLock = false;
  bool _ctrlLatched = false;
  bool _altLatched = false;
  bool _winLatched = false;

  // Keyboard layer
  bool _isSymbolLayer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();

    _eventSubscription = widget.repository.eventStream.listen((_) {
      if (mounted) _refreshStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    widget.repository.releaseAllInputs();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      widget.repository.releaseAllInputs();
    }
  }

  Future<void> _refreshStatus() async {
    final status = await widget.repository.getCapabilities();
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  int get _currentModifiers {
    int mods = HidModifiers.none;
    if (_shiftLatched || _capsLock) mods |= HidModifiers.leftShift;
    if (_ctrlLatched) mods |= HidModifiers.leftCtrl;
    if (_altLatched) mods |= HidModifiers.leftAlt;
    if (_winLatched) mods |= HidModifiers.leftGui;
    return mods;
  }

  Future<void> _sendKey(int keyCode, {bool autoShift = false}) async {
    if (!_status.isConnected) return;

    int mods = _currentModifiers;
    if (autoShift) {
      mods |= HidModifiers.leftShift;
    }

    await widget.repository.sendKeyStroke(modifiers: mods, keyCode: keyCode);

    // Unlatch temporary modifiers after key press (except caps lock)
    if (_shiftLatched || _ctrlLatched || _altLatched || _winLatched) {
      setState(() {
        _shiftLatched = false;
        _ctrlLatched = false;
        _altLatched = false;
        _winLatched = false;
      });
    }
  }

  Future<void> _sendShortcut(int mods, int keyCode) async {
    if (!_status.isConnected) return;
    await widget.repository.sendKeyStroke(modifiers: mods, keyCode: keyCode);
  }

  Future<bool> _sendTextString(String text) async {
    if (!_status.isConnected) return false;
    return await widget.repository.sendTextSequence(text);
  }

  Future<void> _emergencyRelease() async {
    setState(() {
      _shiftLatched = false;
      _capsLock = false;
      _ctrlLatched = false;
      _altLatched = false;
      _winLatched = false;
    });
    await widget.repository.releaseAllInputs();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All keyboard keys & modifiers released.'),
          duration: Duration(milliseconds: 1200),
          backgroundColor: AppTheme.surfaceVariant,
        ),
      );
    }
  }

  void _openSettings() {
    if (widget.settingsRepository != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => AppSettingsSheet(
          settingsRepository: widget.settingsRepository!,
          hidRepository: widget.repository,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _status.isConnected;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.keyboard,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Keyboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.back_hand_outlined),
            tooltip: 'Release Held Keys',
            onPressed: _emergencyRelease,
          ),
          if (widget.settingsRepository != null)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'General Settings',
              onPressed: _openSettings,
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: Column(
            children: [
              // Host status banner
              _buildHostStatusBar(isConnected),
              const SizedBox(height: 8),

              // Text input & paste bar
              TextInputBar(
                onSendText: _sendTextString,
                isConnected: isConnected,
              ),
              const SizedBox(height: 8),

              // Windows shortcuts bar
              ShortcutsBar(onShortcut: _sendShortcut),
              const SizedBox(height: 8),

              // Function keys & navigation bar
              FunctionKeysBar(
                onKeyPress: (code) => _sendKey(code),
                activeModifiers: _currentModifiers,
              ),
              const SizedBox(height: 8),

              // Main On-Screen Keyboard
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: _isSymbolLayer
                      ? _buildSymbolKeyboardLayout()
                      : _buildQwertyKeyboardLayout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostStatusBar(bool isConnected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppTheme.success : AppTheme.warning,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: 0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isConnected
                  ? '${_status.connectedDeviceName ?? "Windows PC"} • Ready to Type'
                  : 'Host Disconnected — Connect via Bluetooth',
              style: TextStyle(
                color: isConnected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isConnected && widget.onNavigateToConnectivity != null)
            TextButton(
              onPressed: widget.onNavigateToConnectivity,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppTheme.primaryLight,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios, size: 10),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQwertyKeyboardLayout() {
    final isUpper = _shiftLatched || _capsLock;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Number row
        Row(
          children: [
            _key('`', '~', HidKeyCodes.keyGrave),
            _key('1', '!', HidKeyCodes.key1),
            _key('2', '@', HidKeyCodes.key2),
            _key('3', '#', HidKeyCodes.key3),
            _key('4', '\$', HidKeyCodes.key4),
            _key('5', '%', HidKeyCodes.key5),
            _key('6', '^', HidKeyCodes.key6),
            _key('7', '&', HidKeyCodes.key7),
            _key('8', '*', HidKeyCodes.key8),
            _key('9', '(', HidKeyCodes.key9),
            _key('0', ')', HidKeyCodes.key0),
            _key('-', '_', HidKeyCodes.keyMinus),
            _key('=', '+', HidKeyCodes.keyEqual),
          ],
        ),

        // QWERTY row 1
        Row(
          children: [
            _key(isUpper ? 'Q' : 'q', null, HidKeyCodes.keyQ),
            _key(isUpper ? 'W' : 'w', null, HidKeyCodes.keyW),
            _key(isUpper ? 'E' : 'e', null, HidKeyCodes.keyE),
            _key(isUpper ? 'R' : 'r', null, HidKeyCodes.keyR),
            _key(isUpper ? 'T' : 't', null, HidKeyCodes.keyT),
            _key(isUpper ? 'Y' : 'y', null, HidKeyCodes.keyY),
            _key(isUpper ? 'U' : 'u', null, HidKeyCodes.keyU),
            _key(isUpper ? 'I' : 'i', null, HidKeyCodes.keyI),
            _key(isUpper ? 'O' : 'o', null, HidKeyCodes.keyO),
            _key(isUpper ? 'P' : 'p', null, HidKeyCodes.keyP),
            _key('[', '{', HidKeyCodes.keyLeftBrace),
            _key(']', '}', HidKeyCodes.keyRightBrace),
          ],
        ),

        // QWERTY row 2
        Row(
          children: [
            _key(isUpper ? 'A' : 'a', null, HidKeyCodes.keyA),
            _key(isUpper ? 'S' : 's', null, HidKeyCodes.keyS),
            _key(isUpper ? 'D' : 'd', null, HidKeyCodes.keyD),
            _key(isUpper ? 'F' : 'f', null, HidKeyCodes.keyF),
            _key(isUpper ? 'G' : 'g', null, HidKeyCodes.keyG),
            _key(isUpper ? 'H' : 'h', null, HidKeyCodes.keyH),
            _key(isUpper ? 'J' : 'j', null, HidKeyCodes.keyJ),
            _key(isUpper ? 'K' : 'k', null, HidKeyCodes.keyK),
            _key(isUpper ? 'L' : 'l', null, HidKeyCodes.keyL),
            _key(';', ':', HidKeyCodes.keySemicolon),
            _key('\'', '"', HidKeyCodes.keyApostrophe),
            _key('\\', '|', HidKeyCodes.keyBackslash),
          ],
        ),

        // QWERTY row 3: Shift, Z-M, Punctuation, Backspace
        Row(
          children: [
            KeyboardKeyButton(
              label: _capsLock ? 'CAPS' : 'SHIFT',
              icon: _capsLock ? Icons.keyboard_capslock : Icons.arrow_upward,
              isLatched: _shiftLatched || _capsLock,
              isSpecial: true,
              activeColor: AppTheme.primary,
              flex: 2,
              onTap: () {
                setState(() {
                  if (_shiftLatched) {
                    _shiftLatched = false;
                    _capsLock = false;
                  } else {
                    _shiftLatched = true;
                  }
                });
              },
              onLongPress: () {
                setState(() {
                  _capsLock = !_capsLock;
                  _shiftLatched = false;
                });
              },
            ),
            _key(isUpper ? 'Z' : 'z', null, HidKeyCodes.keyZ),
            _key(isUpper ? 'X' : 'x', null, HidKeyCodes.keyX),
            _key(isUpper ? 'C' : 'c', null, HidKeyCodes.keyC),
            _key(isUpper ? 'V' : 'v', null, HidKeyCodes.keyV),
            _key(isUpper ? 'B' : 'b', null, HidKeyCodes.keyB),
            _key(isUpper ? 'N' : 'n', null, HidKeyCodes.keyN),
            _key(isUpper ? 'M' : 'm', null, HidKeyCodes.keyM),
            _key(',', '<', HidKeyCodes.keyComma),
            _key('.', '>', HidKeyCodes.keyDot),
            _key('/', '?', HidKeyCodes.keySlash),
            KeyboardKeyButton(
              label: 'BKSP',
              icon: Icons.backspace_outlined,
              isSpecial: true,
              flex: 2,
              onTap: () => _sendKey(HidKeyCodes.keyBackspace),
            ),
          ],
        ),

        // Bottom control row: Symbols switch, Ctrl, Win, Alt, Space, Arrows, Enter
        Row(
          children: [
            KeyboardKeyButton(
              label: '?123',
              isSpecial: true,
              flex: 2,
              onTap: () {
                setState(() => _isSymbolLayer = true);
              },
            ),
            KeyboardKeyButton(
              label: 'CTRL',
              isLatched: _ctrlLatched,
              isSpecial: true,
              activeColor: AppTheme.info,
              flex: 2,
              onTap: () {
                setState(() => _ctrlLatched = !_ctrlLatched);
              },
            ),
            KeyboardKeyButton(
              label: 'WIN',
              icon: Icons.window,
              isLatched: _winLatched,
              isSpecial: true,
              activeColor: Colors.deepPurpleAccent,
              flex: 2,
              onTap: () {
                setState(() => _winLatched = !_winLatched);
              },
            ),
            KeyboardKeyButton(
              label: 'ALT',
              isLatched: _altLatched,
              isSpecial: true,
              activeColor: AppTheme.warning,
              flex: 2,
              onTap: () {
                setState(() => _altLatched = !_altLatched);
              },
            ),
            KeyboardKeyButton(
              label: 'SPACE',
              flex: 5,
              onTap: () => _sendKey(HidKeyCodes.keySpace),
            ),
            // Navigation arrow keys
            KeyboardKeyButton(
              label: 'LEFT',
              icon: Icons.arrow_back_ios_new,
              isSpecial: true,
              flex: 2,
              onTap: () => _sendKey(HidKeyCodes.keyLeft),
            ),
            KeyboardKeyButton(
              label: 'UP',
              icon: Icons.keyboard_arrow_up,
              isSpecial: true,
              flex: 2,
              onTap: () => _sendKey(HidKeyCodes.keyUp),
            ),
            KeyboardKeyButton(
              label: 'DOWN',
              icon: Icons.keyboard_arrow_down,
              isSpecial: true,
              flex: 2,
              onTap: () => _sendKey(HidKeyCodes.keyDown),
            ),
            KeyboardKeyButton(
              label: 'RIGHT',
              icon: Icons.arrow_forward_ios,
              isSpecial: true,
              flex: 2,
              onTap: () => _sendKey(HidKeyCodes.keyRight),
            ),
            KeyboardKeyButton(
              label: 'ENTER',
              icon: Icons.keyboard_return,
              isSpecial: true,
              activeColor: AppTheme.primary,
              flex: 3,
              onTap: () => _sendKey(HidKeyCodes.keyEnter),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSymbolKeyboardLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Symbols row 1
        Row(
          children: [
            _key('~', null, HidKeyCodes.keyGrave, autoShift: true),
            _key('!', null, HidKeyCodes.key1, autoShift: true),
            _key('@', null, HidKeyCodes.key2, autoShift: true),
            _key('#', null, HidKeyCodes.key3, autoShift: true),
            _key('\$', null, HidKeyCodes.key4, autoShift: true),
            _key('%', null, HidKeyCodes.key5, autoShift: true),
            _key('^', null, HidKeyCodes.key6, autoShift: true),
            _key('&', null, HidKeyCodes.key7, autoShift: true),
            _key('*', null, HidKeyCodes.key8, autoShift: true),
            _key('(', null, HidKeyCodes.key9, autoShift: true),
            _key(')', null, HidKeyCodes.key0, autoShift: true),
          ],
        ),

        // Symbols row 2
        Row(
          children: [
            _key('_', null, HidKeyCodes.keyMinus, autoShift: true),
            _key('+', null, HidKeyCodes.keyEqual, autoShift: true),
            _key('{', null, HidKeyCodes.keyLeftBrace, autoShift: true),
            _key('}', null, HidKeyCodes.keyRightBrace, autoShift: true),
            _key('|', null, HidKeyCodes.keyBackslash, autoShift: true),
            _key(':', null, HidKeyCodes.keySemicolon, autoShift: true),
            _key('"', null, HidKeyCodes.keyApostrophe, autoShift: true),
            _key('<', null, HidKeyCodes.keyComma, autoShift: true),
            _key('>', null, HidKeyCodes.keyDot, autoShift: true),
            _key('?', null, HidKeyCodes.keySlash, autoShift: true),
          ],
        ),

        // Symbols row 3
        Row(
          children: [
            KeyboardKeyButton(
              label: 'ABC',
              isSpecial: true,
              activeColor: AppTheme.primary,
              flex: 3,
              onTap: () {
                setState(() => _isSymbolLayer = false);
              },
            ),
            _key('[', null, HidKeyCodes.keyLeftBrace),
            _key(']', null, HidKeyCodes.keyRightBrace),
            _key('\\', null, HidKeyCodes.keyBackslash),
            _key(';', null, HidKeyCodes.keySemicolon),
            _key('\'', null, HidKeyCodes.keyApostrophe),
            _key('/', null, HidKeyCodes.keySlash),
            KeyboardKeyButton(
              label: 'BKSP',
              icon: Icons.backspace_outlined,
              isSpecial: true,
              flex: 3,
              onTap: () => _sendKey(HidKeyCodes.keyBackspace),
            ),
          ],
        ),

        // Bottom row for symbol mode
        Row(
          children: [
            KeyboardKeyButton(
              label: 'ABC',
              isSpecial: true,
              flex: 2,
              onTap: () {
                setState(() => _isSymbolLayer = false);
              },
            ),
            KeyboardKeyButton(
              label: 'CTRL',
              isLatched: _ctrlLatched,
              isSpecial: true,
              activeColor: AppTheme.info,
              flex: 2,
              onTap: () {
                setState(() => _ctrlLatched = !_ctrlLatched);
              },
            ),
            KeyboardKeyButton(
              label: 'ALT',
              isLatched: _altLatched,
              isSpecial: true,
              activeColor: AppTheme.warning,
              flex: 2,
              onTap: () {
                setState(() => _altLatched = !_altLatched);
              },
            ),
            KeyboardKeyButton(
              label: 'SPACE',
              flex: 5,
              onTap: () => _sendKey(HidKeyCodes.keySpace),
            ),
            KeyboardKeyButton(
              label: 'ENTER',
              icon: Icons.keyboard_return,
              isSpecial: true,
              activeColor: AppTheme.primary,
              flex: 3,
              onTap: () => _sendKey(HidKeyCodes.keyEnter),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(String label, String? sub, int code, {bool autoShift = false}) {
    return KeyboardKeyButton(
      label: label,
      subLabel: sub,
      onTap: () => _sendKey(code, autoShift: autoShift),
    );
  }
}
