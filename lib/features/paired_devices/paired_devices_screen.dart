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
  bool _navigatedToMousePad = false;

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
    if (!mounted) return;
    setState(() {});

    // Auto-navigate to Mouse Pad if device connected and user hasn't navigated yet
    if (_hidRepo.connectionState == 'CONNECTED' && !_navigatedToMousePad) {
      final dev = _hidRepo.activeDevice ?? _hidRepo.pairedDevices.firstOrNull;
      if (dev != null) {
        _navigatedToMousePad = true;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MousePadScreen(device: dev),
          ),
        ).then((_) {
          _navigatedToMousePad = false;
        });
      }
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connecting to ${device.name}...'),
              duration: const Duration(seconds: 1),
            ),
          );

          // Initiate connection
          await _hidRepo.connect(device);

          if (mounted) {
            _navigatedToMousePad = true;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MousePadScreen(device: device),
              ),
            ).then((_) {
              _navigatedToMousePad = false;
            });
          }
        },
      ),
    );
  }

  void _showPairDialog(BtDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pair with ${device.name}?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Address: ${device.address}',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ezze Control will initiate Bluetooth pairing with your PC and connect as a composite Mouse & Keyboard.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keep this app open and confirm the pairing PIN code on both your PC and phone.',
                      style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pairing with ${device.name}... Confirm PIN on screen'),
                  backgroundColor: const Color(0xFF2563EB),
                  duration: const Duration(seconds: 4),
                ),
              );
              await _hidRepo.pair(device);
            },
            child: const Text('Pair & Connect', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startPairPcWorkflow() async {
    await _hidRepo.makeDiscoverable();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E222A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final isConnected = _hidRepo.connectionState == 'CONNECTED';
            final activeDev = _hidRepo.activeDevice ?? _hidRepo.pairedDevices.firstOrNull;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bluetooth_searching, color: Color(0xFF38BDF8), size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pairing with Windows PC',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Phone is visible for 5 minutes',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131519),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Follow these steps on your PC now:',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        _buildStepItem('1', 'Open Windows Settings > Bluetooth & devices'),
                        _buildStepItem('2', 'Click "Add device" -> "Bluetooth"'),
                        _buildStepItem('3', 'Select your phone from the list'),
                        _buildStepItem('4', 'Confirm the PIN on PC and Phone'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFF87171), size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Keep Ezze Control open! Do not switch to phone settings, so Windows connects as a Mouse & Keyboard.',
                            style: TextStyle(color: Color(0xFFFECACA), fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isConnected) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22C55E)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Connected to ${activeDev?.name ?? "PC"}!',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              if (activeDev != null) {
                                _navigatedToMousePad = true;
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => MousePadScreen(device: activeDev)),
                                ).then((_) => _navigatedToMousePad = false);
                              }
                            },
                            child: const Text('Open Mouse Pad'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Waiting for Windows to discover phone...',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close', style: TextStyle(color: Color(0xFF94A3B8))),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
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
          // Make Discoverable to PC button
          IconButton(
            icon: const Icon(Icons.bluetooth_searching, color: Color(0xFF38BDF8), size: 24),
            tooltip: 'Make Discoverable to PC',
            onPressed: _startPairPcWorkflow,
          ),
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
            // Pro-tip card for Windows pairing
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.laptop_chromebook, color: Color(0xFF60A5FA), size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pairing with a PC?',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Stay in Ezze Control while pairing so Windows detects it as Mouse & Keyboard.',
                          style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _startPairPcWorkflow,
                    child: const Text('Pair PC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ),

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

            // Section 2 Header: Available Devices (matching 2nd image) with rescan button
            _buildSectionHeader(
              'Available Devices',
              trailing: IconButton(
                icon: _hidRepo.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh, color: Colors.white70, size: 20),
                tooltip: 'Scan for Devices',
                onPressed: () => _hidRepo.startDiscovery(),
              ),
            ),
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
                        )
                      else
                        TextButton.icon(
                          icon: const Icon(Icons.search, size: 18),
                          label: const Text('Scan Now'),
                          onPressed: () => _hidRepo.startDiscovery(),
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

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E222A), // Dark container matching 2nd image
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 24), // Spacer for centering
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (trailing != null) trailing else const SizedBox(width: 24),
        ],
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
          onTap: () {
            if (isAvailable) {
              _showPairDialog(device);
            } else {
              _showConnectDialog(device);
            }
          },
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
