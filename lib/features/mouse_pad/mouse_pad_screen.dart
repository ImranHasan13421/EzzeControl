import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/bluetooth_hid_repository.dart';
import '../../data/settings_repository.dart';
import '../../domain/models.dart';
import 'widgets/function_keys_sheet.dart';
import 'widgets/media_remote_sheet.dart';
import 'widgets/number_pad_sheet.dart';
import 'widgets/speed_dialog.dart';
import 'widgets/text_input_dialog.dart';
import 'widgets/touchpad_surface.dart';

class MousePadScreen extends StatefulWidget {
  final BtDevice device;

  const MousePadScreen({
    super.key,
    required this.device,
  });

  @override
  State<MousePadScreen> createState() => _MousePadScreenState();
}

class _MousePadScreenState extends State<MousePadScreen> {
  final BluetoothHidRepository _hidRepo = BluetoothHidRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _keyboardController = TextEditingController();
  bool _isSoftKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _settingsRepo.init();
    _keyboardFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSoftKeyboardVisible = _keyboardFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _keyboardController.dispose();
    super.dispose();
  }

  void _disconnectAndExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disconnect Device', style: TextStyle(color: Colors.white)),
        content: Text(
          'Disconnect from ${widget.device.name} and return to main menu?',
          style: const TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Disconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _hidRepo.disconnect();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _toggleSoftKeyboard() {
    if (_keyboardFocusNode.hasFocus) {
      _keyboardFocusNode.unfocus();
    } else {
      _keyboardFocusNode.requestFocus();
    }
  }

  void _onLiveKeyTyped(String newText) {
    if (newText.isNotEmpty) {
      // Send the newly typed character to the PC
      final char = newText[newText.length - 1];
      _hidRepo.sendText(char);
      // Keep controller empty to accept continuous typing & backspaces cleanly
      _keyboardController.clear();
    }
  }

  void _openFunctionKeys() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FunctionKeysSheet(
        onKeyPressed: (code, {modifier = 0}) {
          _hidRepo.sendKey(code, modifier: modifier);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _openTextInput() {
    showDialog(
      context: context,
      builder: (_) => TextInputDialog(
        onSend: (text) {
          _hidRepo.sendText(text);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Text sent to PC'),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF22C55E),
            ),
          );
        },
      ),
    );
  }

  void _openNumberPad() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NumberPadSheet(
        onKeyPressed: (code, {modifier = 0}) {
          _hidRepo.sendKey(code, modifier: modifier);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _startSpeakToType() async {
    final text = await _hidRepo.requestSpeechInput();
    if (text != null && text.isNotEmpty) {
      await _hidRepo.sendText(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Typed: "$text"'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    }
  }

  void _openPointerSpeedDialog() {
    showDialog(
      context: context,
      builder: (_) => SpeedDialog(
        title: 'Select Mouse Pointer Speed',
        currentSpeed: _settingsRepo.pointerSpeed,
        onSpeedChanged: (speed) {
          _settingsRepo.setPointerSpeed(speed);
        },
        onResetDefault: () {
          _settingsRepo.resetPointerSpeed();
        },
      ),
    );
  }

  void _openScrollSpeedDialog() {
    showDialog(
      context: context,
      builder: (_) => SpeedDialog(
        title: 'Select Mouse Scroll Speed',
        currentSpeed: _settingsRepo.scrollSpeed,
        onSpeedChanged: (speed) {
          _settingsRepo.setScrollSpeed(speed);
        },
        onResetDefault: () {
          _settingsRepo.resetScrollSpeed();
        },
      ),
    );
  }

  void _openMediaRemote() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaRemoteSheet(
        onKeyPressed: (code, {modifier = 0}) {
          _hidRepo.sendKey(code, modifier: modifier);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  void _showTroubleshootingGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E222A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF475569),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Icon(Icons.build_circle, color: Color(0xFF38BDF8), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'PC Not Receiving Input?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Text(
                'Windows queries Bluetooth capabilities ONLY during initial pairing. If your phone was paired before Ezze Control was installed, Windows treats it as an Audio device instead of Mouse & Keyboard.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick 30-Second Fix:',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildGuideBullet('1', 'On PC, open Settings > Bluetooth & devices'),
            _buildGuideBullet('2', 'Click the 3 dots on your phone and select "Remove device"'),
            _buildGuideBullet('3', 'Tap "Make Discoverable" below, then on PC click "Add device" > "Bluetooth"'),
            _buildGuideBullet('4', 'Select your phone. Windows will instantly bind the HID Mouse & Keyboard drivers!'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.bluetooth_searching, size: 20),
                    label: const Text('Make Phone Discoverable', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _hidRepo.makeDiscoverable();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideBullet(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.device.name.isNotEmpty
        ? widget.device.name
        : widget.device.address;

    return ListenableBuilder(
      listenable: _hidRepo,
      builder: (context, _) {
        final isConnected = _hidRepo.isConnected;
        final isConnecting = _hidRepo.isConnecting;

        return Scaffold(
          backgroundColor: const Color(0xFF131519),
          appBar: AppBar(
            backgroundColor: const Color(0xFF131519),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  deviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? const Color(0xFF22C55E)
                            : (isConnecting ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isConnected
                          ? 'Connected'
                          : (isConnecting ? 'Connecting...' : 'Disconnected'),
                      style: TextStyle(
                        fontSize: 11,
                        color: isConnected
                            ? const Color(0xFF86EFAC)
                            : (isConnecting ? const Color(0xFFFCD34D) : const Color(0xFFFCA5A5)),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Power / Disconnect button
              IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.white),
                tooltip: 'Disconnect',
                onPressed: _disconnectAndExit,
              ),
              // Mouse pointer indicator icon
              IconButton(
                icon: const Icon(Icons.mouse, color: Colors.white),
                tooltip: 'Mouse Mode',
                onPressed: () {},
              ),
              // Soft keyboard toggle button
              IconButton(
                icon: Icon(
                  Icons.keyboard,
                  color: _isSoftKeyboardVisible ? const Color(0xFF3B82F6) : Colors.white,
                ),
                tooltip: 'Toggle Keyboard',
                onPressed: _toggleSoftKeyboard,
              ),
              // 3-Dot Overflow Menu (matching 7th image)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: Colors.white, // Light popup menu matching 7th image
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  switch (val) {
                    case 'function_keys':
                      _openFunctionKeys();
                      break;
                    case 'text_input':
                      _openTextInput();
                      break;
                    case 'number_pad':
                      _openNumberPad();
                      break;
                    case 'media_remote':
                      _openMediaRemote();
                      break;
                    case 'speak_to_type':
                      _startSpeakToType();
                      break;
                    case 'mouse_speed':
                      _openPointerSpeedDialog();
                      break;
                    case 'scroll_speed':
                      _openScrollSpeedDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  _buildMenuItem('function_keys', 'Function Keys'),
                  _buildMenuItem('text_input', 'Text Input'),
                  _buildMenuItem('number_pad', 'Number Pad'),
                  _buildMenuItem('media_remote', 'Media Remote'),
                  _buildMenuItem('speak_to_type', 'Speak-To-Type'),
                  _buildMenuItem('mouse_speed', 'Mouse Speed'),
                  _buildMenuItem('scroll_speed', 'Mouse Scroll Speed'),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Real-time connection status banner if not connected
                if (!isConnected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isConnecting ? const Color(0xFF1E3A8A) : const Color(0xFF450A0A),
                    child: Row(
                      children: [
                        if (isConnecting)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF87171)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isConnecting
                                ? 'Connecting Bluetooth HID to host PC...'
                                : 'Bluetooth HID is not connected to PC',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                        if (!isConnecting) ...[
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF38BDF8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.help_outline, size: 16),
                            label: const Text('Guide', style: TextStyle(fontSize: 12)),
                            onPressed: _showTroubleshootingGuide,
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _hidRepo.connect(widget.device),
                            child: const Text('Reconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Hidden TextField for system soft keyboard input (6th image)
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 1,
                    width: 1,
                    child: TextField(
                      focusNode: _keyboardFocusNode,
                      controller: _keyboardController,
                      autocorrect: false,
                      enableSuggestions: false,
                      onChanged: _onLiveKeyTyped,
                    ),
                  ),
                ),

                // Large Usable Touchpad Area (5th image)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: TouchpadSurface(
                      hidRepo: _hidRepo,
                      settingsRepo: _settingsRepo,
                    ),
                  ),
                ),

            // Bottom Mouse Click Buttons (matching 5th image)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMouseButton(
                      title: 'Left Click',
                      onPressed: () {
                        _hidRepo.sendMouseClick('left');
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMouseButton(
                      title: 'Right Click',
                      onPressed: () {
                        _hidRepo.sendMouseClick('right');
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
);
}

  PopupMenuItem<String> _buildMenuItem(String value, String title) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B), // Dark text on light menu matching 7th image
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMouseButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 96,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // Blue matching 5th image
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mouse, size: 28, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
