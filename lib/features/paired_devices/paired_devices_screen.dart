import 'package:flutter/material.dart';
import '../../data/bluetooth_hid_repository.dart';
import '../../domain/models.dart';
import '../guide/app_guide_screen.dart';
import '../mouse_pad/mouse_pad_screen.dart';
import 'widgets/connect_dialog.dart';

class PairedDevicesScreen extends StatefulWidget {
  const PairedDevicesScreen({super.key});

  @override
  State<PairedDevicesScreen> createState() => _PairedDevicesScreenState();
}

class _PairedDevicesScreenState extends State<PairedDevicesScreen> {
  final BluetoothHidRepository _hidRepo = BluetoothHidRepository();

  @override
  void initState() {
    super.initState();
    _hidRepo.addListener(_onRepoChanged);
    _loadDevices();
  }

  @override
  void dispose() {
    _hidRepo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _loadDevices() async {
    await _hidRepo.refreshPairedDevices();
    await _hidRepo.startDiscovery();
  }

  void _showConnectDialog(BtDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => ConnectDialog(
        device: device,
        onConnect: () async {
          Navigator.of(ctx).pop(); // Dismiss dialog
          // Show connecting indicator
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connecting to ${device.name}...'),
              duration: const Duration(seconds: 1),
            ),
          );

          // Initiate connection
          await _hidRepo.connect(device);

          if (mounted) {
            // Navigate to Mouse Pad screen (5th image)
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MousePadScreen(device: device),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pairedList = _hidRepo.pairedDevices;
    final availableList = _hidRepo.discoveredDevices
        .where((d) => !pairedList.any((p) => p.address == d.address))
        .toList();

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
          'Paired Devices',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Open phone Bluetooth settings button (matching 2nd image)
          IconButton(
            icon: const Icon(Icons.bluetooth, color: Colors.white, size: 26),
            tooltip: 'Bluetooth Settings',
            onPressed: () => _hidRepo.openBluetoothSettings(),
          ),
          // Help / App Guide instruction button (matching 2nd image)
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 26),
            tooltip: 'Help Guide',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppGuideScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _hidRepo.refreshPairedDevices();
          await _hidRepo.startDiscovery();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Section 1 Header: Paired Devices (matching 2nd image)
            _buildSectionHeader('Paired Devices'),
            const SizedBox(height: 12),

            if (pairedList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.devices, size: 48, color: Color(0xFF64748B)),
                      const SizedBox(height: 12),
                      const Text(
                        'No paired devices found',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.settings_bluetooth, size: 18),
                        label: const Text('Open Bluetooth Settings'),
                        onPressed: () => _hidRepo.openBluetoothSettings(),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...pairedList.map((device) => _buildDeviceCard(device)),

            const SizedBox(height: 24),

            // Section 2 Header: Available Devices (matching 2nd image)
            _buildSectionHeader('Available Devices'),
            const SizedBox(height: 16),

            if (availableList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        'No near by devices available!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_hidRepo.isScanning)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                    ],
                  ),
                ),
              )
            else
              ...availableList.map((device) => _buildDeviceCard(device, isAvailable: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A), // Dark container matching 2nd image
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BtDevice device, {bool isAvailable = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A), // Card background matching 2nd image
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showConnectDialog(device),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Blue circular icon (matching 2nd image)
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB), // Blue circle
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.desktop_windows,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.address,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAvailable ? 'Available' : 'Computer',
                        style: TextStyle(
                          color: isAvailable ? const Color(0xFF38BDF8) : const Color(0xFF22C55E), // Green Computer
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF64748B),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
