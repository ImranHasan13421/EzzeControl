import 'package:flutter/material.dart';
import '../../../domain/hid_key_codes.dart';

class MediaRemoteSheet extends StatelessWidget {
  final Function(int keyCode, {int modifier}) onKeyPressed;

  const MediaRemoteSheet({
    super.key,
    required this.onKeyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E222A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Media Remote',
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                  icon: Icons.skip_previous,
                  label: 'Prev',
                  onTap: () {
                    // Send Previous Track or Left Arrow
                    onKeyPressed(HidKeyCodes.keyLeft);
                  },
                ),
                _buildCircleButton(
                  icon: Icons.play_arrow,
                  label: 'Play / Pause',
                  isPrimary: true,
                  onTap: () {
                    // Send Space (Standard media play/pause)
                    onKeyPressed(HidKeyCodes.keySpace);
                  },
                ),
                _buildCircleButton(
                  icon: Icons.skip_next,
                  label: 'Next',
                  onTap: () {
                    // Send Next Track or Right Arrow
                    onKeyPressed(HidKeyCodes.keyRight);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                  icon: Icons.volume_down,
                  label: 'Vol -',
                  onTap: () {
                    // Send Down Arrow or custom key
                    onKeyPressed(HidKeyCodes.keyDown);
                  },
                ),
                _buildCircleButton(
                  icon: Icons.volume_mute,
                  label: 'Mute',
                  onTap: () {
                    // Send 'm' key for mute in many PC media players
                    onKeyPressed(HidKeyCodes.keySpace);
                  },
                ),
                _buildCircleButton(
                  icon: Icons.volume_up,
                  label: 'Vol +',
                  onTap: () {
                    // Send Up Arrow or custom key
                    onKeyPressed(HidKeyCodes.keyUp);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        Material(
          color: isPrimary ? const Color(0xFF2563EB) : const Color(0xFF283244),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(isPrimary ? 22 : 18),
              child: Icon(
                icon,
                color: Colors.white,
                size: isPrimary ? 32 : 26,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
