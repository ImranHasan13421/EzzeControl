import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../data/bluetooth_hid_repository.dart';
import '../bt_devices/bt_devices_screen.dart';
import '../guide/app_guide_screen.dart';
import '../paired_devices/paired_devices_screen.dart';
import '../settings/app_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothHidRepository _hidRepo = BluetoothHidRepository();

  @override
  void initState() {
    super.initState();
    _hidRepo.addListener(_onRepoChanged);
    _checkStatus();
  }

  @override
  void dispose() {
    _hidRepo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _checkStatus() async {
    await _hidRepo.init();
    if (!_hidRepo.capabilities.hasPermissions) {
      await _hidRepo.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final caps = _hidRepo.capabilities;

    return Scaffold(
      backgroundColor: const Color(0xFF131519),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Header Section with Logo and Name (matching 1st image & prompt specifications)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Logo with rounded corner size
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/icons/app_logo.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.mouse, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // App's Name and Subtitle
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ezze Control',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Wireless Mouse & Keypad',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Top Right Settings / Guide shortcut
                  IconButton(
                    icon: const Icon(
                      Icons.settings_suggest_rounded,
                      color: Color(0xFFF59E0B),
                      size: 32,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Permissions / Bluetooth warning banner (if needed)
              if (!caps.hasPermissions)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bluetooth permissions required for Android 14',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _hidRepo.requestPermissions(),
                        child: const Text('Grant', style: TextStyle(color: Color(0xFF38BDF8))),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // 4 Options Grid (2x2) matching 1st image
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    // Option 1: Paired Devices (Muted Teal #485E5A)
                    _buildMenuCard(
                      title: 'Paired Devices',
                      color: AppTheme.tilePaired,
                      iconWidget: _buildPhoneBtIcon(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PairedDevicesScreen(),
                          ),
                        );
                      },
                    ),

                    // Option 2: BT Devices (Muted Mauve #675854)
                    _buildMenuCard(
                      title: 'BT Devices',
                      color: AppTheme.tileBt,
                      iconWidget: _buildBtEmblemIcon(),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BtDevicesScreen(),
                          ),
                        );
                      },
                    ),

                    // Option 3: App Settings (Muted Slate Blue #3B4A5C)
                    _buildMenuCard(
                      title: 'App Settings',
                      color: AppTheme.tileSettings,
                      iconWidget: const Icon(
                        Icons.settings,
                        size: 52,
                        color: Colors.white,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    // Option 4: App Guide (Dark Charcoal #282D34)
                    _buildMenuCard(
                      title: 'App Guide',
                      color: AppTheme.tileGuide,
                      iconWidget: const Icon(
                        Icons.menu_book_rounded,
                        size: 52,
                        color: Colors.white,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppGuideScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required Color color,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneBtIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.phone_android,
          size: 56,
          color: Colors.white,
        ),
        Positioned(
          top: 18,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth,
              size: 16,
              color: Color(0xFF485E5A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBtEmblemIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(
          Icons.phone_android,
          size: 56,
          color: Colors.white,
        ),
        Positioned(
          top: 18,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_audio,
              size: 16,
              color: Color(0xFF675854),
            ),
          ),
        ),
      ],
    );
  }
}
