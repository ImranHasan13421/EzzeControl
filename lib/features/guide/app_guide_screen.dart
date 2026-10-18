import 'package:flutter/material.dart';

class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131519),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131519),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'App Guide',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildGuideSection(
            stepNumber: '1',
            title: 'Pairing with Windows PC',
            icon: Icons.bluetooth_connected,
            items: [
              'On Windows 10/11: Go to Settings > Bluetooth & devices > Add device.',
              'Ensure Bluetooth is turned ON on your phone and Windows PC.',
              'Select your phone from the list of available devices on Windows.',
              'Confirm the pairing code on both Windows and your phone.',
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            stepNumber: '2',
            title: 'Connecting Ezze Control',
            icon: Icons.link,
            items: [
              'Open Ezze Control and tap "Paired Devices".',
              'Locate your PC in the list and tap on it.',
              'Tap the green "Connect" button in the dialog.',
              'Ezze Control will establish a standard Bluetooth HID connection to your PC.',
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            stepNumber: '3',
            title: 'Touchpad & Mouse Gestures',
            icon: Icons.mouse,
            items: [
              'Pointer Move: Slide one finger on the touchpad surface.',
              'Left Click: Single tap on the touchpad, or tap the large "Left Click" button below.',
              'Right Click: Tap with two fingers simultaneously, or tap the "Right Click" button.',
              'Select & Drag: Double tap and hold your finger down on the touchpad, then slide to select text or drag items like on a laptop touchpad.',
              'Scrolling: Slide two fingers up or down vertically to scroll through pages and documents.',
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            stepNumber: '4',
            title: 'Keyboard & Typing Options',
            icon: Icons.keyboard,
            items: [
              'Live Typing: Tap the keyboard icon in the header to open your phone\'s soft keyboard. Typed characters stream live to your PC.',
              'Text Input: In the 3-dot menu, select "Text Input" to write or paste full text, then tap "Send" to batch type it to PC.',
              'Speak-to-Type: In the 3-dot menu, select "Speak-to-Type". Google Speech Services converts your spoken voice into text and types it directly into the active PC window.',
              'Function Keys: Open "Function Keys" to access F1–F12, Esc, Tab, Win, Ctrl, Alt, and navigation shortcuts.',
              'Number Pad: Open "Number Pad" for a 10-key desktop keypad with NumLock.',
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            stepNumber: '5',
            title: 'Speed & Sensitivity',
            icon: Icons.speed,
            items: [
              'From the 3-dot menu in the Mouse Pad screen, tap "Mouse Speed" to adjust cursor sensitivity.',
              'Tap "Mouse Scroll Speed" to adjust scroll sensitivity.',
              'Use "Default" at any time to restore factory calibration.',
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGuideSection({
    required String stepNumber,
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF282E38)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(icon, color: const Color(0xFF60A5FA), size: 22),
            ],
          ),
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
