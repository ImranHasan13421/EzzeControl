import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../data/bluetooth_hid_repository.dart';
import '../../domain/models/hid_status.dart';

class ConnectivityScreen extends StatefulWidget {
  final BluetoothHidRepository repository;

  const ConnectivityScreen({super.key, required this.repository});

  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen>
    with WidgetsBindingObserver {
  HidStatus _status = const HidStatus();
  bool _isLoading = true;
  bool _userIntendedRegistration = false;
  StreamSubscription? _subscription;
  final List<DiagnosticLog> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  List<Map<String, String>> _bondedDevices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDiagnostic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _addLog('lifecycle', 'App resumed in foreground. Checking HID state...');
      _refresh();
      if (_userIntendedRegistration && !_status.isRegistered) {
        _registerHid();
      }
    }
  }

  void _addLog(String type, String message) {
    setState(() {
      _logs.insert(0, DiagnosticLog(type: type, message: message));
      if (_logs.length > 60) {
        _logs.removeLast();
      }
    });
  }

  Future<void> _initDiagnostic() async {
    setState(() => _isLoading = true);
    _addLog('sys', 'Initializing Ezze Control diagnostics...');

    final initial = await widget.repository.getCapabilities();
    final bonded = await widget.repository.getBondedDevices();
    if (mounted) {
      setState(() {
        _status = initial;
        _bondedDevices = bonded;
        _isLoading = false;
      });
      _addLog('status', 'Device: ${initial.deviceModel} (Android ${initial.androidVersion}, SDK ${initial.sdkInt})');
      if (initial.supportedApi) {
        _addLog('status', 'Android API 28+ check: PASSED');
      } else {
        _addLog('error', 'Android API 28+ check: FAILED (Current SDK ${initial.sdkInt})');
      }
    }

    _subscription = widget.repository.eventStream.listen(
      (data) {
        if (!mounted) return;
        final type = data['type']?.toString() ?? 'event';
        final message = data['message']?.toString() ?? '';
        final updatedStatus = HidStatus.fromMap(data);

        setState(() {
          _status = updatedStatus;
        });

        _addLog(type, message.isNotEmpty ? message : 'Native event: $type');

        // Refresh bonded list on connection or status changes
        if (type == 'connected' || type == 'disconnected' || type == 'profile_connected') {
          _loadBondedDevices();
        }
      },
      onError: (err) {
        _addLog('error', 'Event stream error: $err');
      },
    );
  }

  Future<void> _loadBondedDevices() async {
    final bonded = await widget.repository.getBondedDevices();
    if (mounted) {
      setState(() => _bondedDevices = bonded);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    _addLog('action', 'Refreshing device status and paired hosts...');
    final caps = await widget.repository.getCapabilities();
    final bonded = await widget.repository.getBondedDevices();
    if (mounted) {
      setState(() {
        _status = caps;
        _bondedDevices = bonded;
        _isLoading = false;
      });
      _addLog('status', 'Status refreshed.');
    }
  }

  Future<void> _requestPermissions() async {
    _addLog('action', 'Requesting required Bluetooth permissions...');
    final granted = await widget.repository.requestPermissions();
    _addLog('action', granted ? 'All permissions granted!' : 'Permissions not fully granted.');
    await _refresh();
  }

  Future<void> _registerHid() async {
    _userIntendedRegistration = true;
    _addLog('action', 'Requesting Bluetooth HID Device registration...');
    final success = await widget.repository.requestHidRegistration();
    if (!success) {
      _addLog('error', 'HID registration request failed to send.');
    }
  }

  Future<void> _unregisterHid() async {
    _userIntendedRegistration = false;
    _addLog('action', 'Requesting HID unregistration...');
    final success = await widget.repository.unregisterHid();
    _addLog('action', success ? 'HID unregistered.' : 'Unregister call returned false.');
  }

  Future<void> _connectHost(String address) async {
    _addLog('action', 'Connecting to host device ($address)...');
    final success = await widget.repository.connectHost(address);
    if (!success) {
      _addLog('error', 'Could not initiate connection to $address.');
    }
  }

  Future<void> _unpairHost(String address) async {
    _addLog('action', 'Removing bond for device ($address)...');
    final success = await widget.repository.unpairHost(address);
    _addLog('action', success ? 'Bond removed.' : 'Unpair requested.');
    await _refresh();
  }

  Future<void> _makeDiscoverable() async {
    _addLog('action', 'Making phone discoverable for 300s...');
    await widget.repository.makeDiscoverable();
  }

  Future<void> _openBluetoothSettings() async {
    _addLog('action', 'Opening system Bluetooth settings...');
    await widget.repository.openBluetoothSettings();
  }

  Future<void> _sendTestMouse() async {
    _addLog('action', 'Triggering test mouse movement report...');
    final success = await widget.repository.sendTestMouseMovement();
    if (!success) {
      _addLog('error', 'Failed to send test mouse movement.');
    }
  }

  Future<void> _sendTestKey() async {
    _addLog('action', 'Triggering test keyboard report (Space key)...');
    final success = await widget.repository.sendTestKey();
    if (!success) {
      _addLog('error', 'Failed to send test key.');
    }
  }

  Future<void> _disconnect() async {
    _addLog('action', 'Disconnecting from host...');
    final success = await widget.repository.disconnect();
    _addLog('action', success ? 'Disconnect request sent.' : 'Disconnect failed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.bluetooth_audio,
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ezze Control',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  'Bluetooth HID Controller & Diagnostic',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              color: AppTheme.primary,
              backgroundColor: AppTheme.surfaceVariant,
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusHeroCard(),
                  const SizedBox(height: 16),
                  if (_status.lastError != null && _status.lastError!.isNotEmpty)
                    _buildErrorCard(_status.lastError!),
                  const SizedBox(height: 16),
                  _buildActionControls(),
                  const SizedBox(height: 16),
                  _buildPhase2VerificationCard(),
                  const SizedBox(height: 16),
                  _buildPairedDevicesCard(),
                  const SizedBox(height: 16),
                  _buildCompatibilityMatrix(),
                  const SizedBox(height: 16),
                  _buildWindowsPairingCard(),
                  const SizedBox(height: 16),
                  _buildDiagnosticsConsole(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusHeroCard() {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (_status.isConnected) {
      badgeColor = AppTheme.success;
      badgeText = 'Connected to Host';
      badgeIcon = Icons.bluetooth_connected;
    } else if (_status.isConnecting) {
      badgeColor = AppTheme.info;
      badgeText = 'Connecting...';
      badgeIcon = Icons.bluetooth_searching;
    } else if (_status.isRegistered) {
      badgeColor = AppTheme.success;
      badgeText = 'HID Registered (Ready for Host)';
      badgeIcon = Icons.check_circle_outline;
    } else if (_status.isRegistering || _status.profilePending) {
      badgeColor = AppTheme.warning;
      badgeText = 'Registering with Android...';
      badgeIcon = Icons.hourglass_top;
    } else if (!_status.permissionsGranted) {
      badgeColor = AppTheme.warning;
      badgeText = 'Permissions Required';
      badgeIcon = Icons.security;
    } else if (!_status.bluetoothEnabled) {
      badgeColor = AppTheme.error;
      badgeText = 'Bluetooth Disabled';
      badgeIcon = Icons.bluetooth_disabled;
    } else if (!_status.supportedApi) {
      badgeColor = AppTheme.error;
      badgeText = 'Unsupported Android Version';
      badgeIcon = Icons.error_outline;
    } else {
      badgeColor = AppTheme.primaryLight;
      badgeText = 'Ready to Register';
      badgeIcon = Icons.bluetooth;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surface,
            AppTheme.surfaceVariant.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'API ${_status.sdkInt}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _status.isConnected
                ? (_status.connectedDeviceName ?? 'Connected Windows PC')
                : (_status.isRegistered
                    ? 'Broadcasting as HID Mouse & Keyboard'
                    : 'Ezze Control HID Service'),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _status.isConnected
                ? 'Address: ${_status.connectedDeviceAddress ?? "Unknown"} • Active HID link established'
                : (_status.isRegistered
                    ? 'Open Windows Bluetooth settings to discover and pair with this phone.'
                    : 'Standard Bluetooth HID emulation without any companion PC software.'),
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diagnostic Notice',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionControls() {
    if (!_status.permissionsGranted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _requestPermissions,
          icon: const Icon(Icons.security, size: 20),
          label: const Text('Grant Bluetooth Permissions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warning,
            foregroundColor: Colors.black87,
          ),
        ),
      );
    }

    if (_status.isConnected) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _disconnect,
          icon: const Icon(Icons.bluetooth_disabled, size: 20, color: AppTheme.error),
          label: const Text('Disconnect from Host', style: TextStyle(color: AppTheme.error)),
        ),
      );
    }

    if (_status.isRegistered) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _unregisterHid,
              icon: const Icon(Icons.stop_circle_outlined, size: 18),
              label: const Text('Unregister HID'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Check Host'),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_status.isRegistering || _status.profilePending) ? null : _registerHid,
        icon: (_status.isRegistering || _status.profilePending)
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.bluetooth_searching, size: 20),
        label: Text(
          (_status.isRegistering || _status.profilePending)
              ? 'Registering HID Device...'
              : 'Register Bluetooth HID Device',
        ),
      ),
    );
  }

  Widget _buildPhase2VerificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _status.isConnected ? AppTheme.primary : AppTheme.border,
          width: _status.isConnected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mouse,
                color: _status.isConnected ? AppTheme.primaryLight : AppTheme.textMuted,
                size: 20,
              ),
              const Expanded(
                child: Text(
                  'Phase 2 — Windows HID Verification',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _status.isConnected
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _status.isConnected ? 'ACTIVE' : 'READY TO TEST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _status.isConnected ? AppTheme.success : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Test real HID report transmission without any software on Windows PC:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _status.isConnected ? _sendTestMouse : null,
                  icon: const Icon(Icons.open_with, size: 18),
                  label: const Text('Move Cursor', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _status.isConnected ? _sendTestKey : null,
                  icon: const Icon(Icons.space_bar, size: 18),
                  label: const Text('Tap Space Key', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppTheme.surfaceHover,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Interactive touch test surface
          GestureDetector(
            onPanUpdate: _status.isConnected
                ? (details) {
                    widget.repository.sendMouseMovement(
                      dx: (details.delta.dx * 1.5).round().clamp(-127, 127),
                      dy: (details.delta.dy * 1.5).round().clamp(-127, 127),
                    );
                  }
                : null,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _status.isConnected
                    ? AppTheme.surfaceVariant
                    : AppTheme.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _status.isConnected ? AppTheme.borderSubtle : AppTheme.border,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: _status.isConnected ? AppTheme.primaryLight : AppTheme.textMuted,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _status.isConnected
                          ? 'Drag finger here to move Windows cursor in real time'
                          : 'Pair & connect to Windows above to enable live trackpad test',
                      style: TextStyle(
                        fontSize: 12,
                        color: _status.isConnected ? AppTheme.textPrimary : AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_status.isConnected) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.repository.sendMouseMovement(buttons: 0x01); // Left click down
                      Future.delayed(const Duration(milliseconds: 60), () {
                        widget.repository.sendMouseMovement(buttons: 0x00); // Release
                      });
                    },
                    child: const Text('Left Click'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.repository.sendMouseMovement(buttons: 0x02); // Right click down
                      Future.delayed(const Duration(milliseconds: 60), () {
                        widget.repository.sendMouseMovement(buttons: 0x00); // Release
                      });
                    },
                    child: const Text('Right Click'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPairedDevicesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.devices, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Paired Host Devices',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _makeDiscoverable,
                  icon: const Icon(Icons.visibility, size: 15),
                  label: const Text('Make Discoverable', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (_bondedDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No paired devices found yet.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. Tap "Make Discoverable" above.\n2. Open Windows Bluetooth settings and pair with this phone.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openBluetoothSettings,
                    icon: const Icon(Icons.settings_bluetooth, size: 16),
                    label: const Text('Open Phone Bluetooth Settings', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _bondedDevices.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final dev = _bondedDevices[index];
                final name = dev['name'] ?? 'Unknown';
                final addr = dev['address'] ?? '';
                final isCurrent = _status.connectedDeviceAddress == addr;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isCurrent ? Icons.bluetooth_connected : Icons.laptop,
                    color: isCurrent ? AppTheme.success : AppTheme.primaryLight,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    addr,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrent)
                        const Text(
                          'Connected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.success,
                          ),
                        )
                      else ...[
                        TextButton(
                          onPressed: _status.isRegistered ? () => _connectHost(addr) : null,
                          child: const Text('Connect Host'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.link_off, size: 18, color: AppTheme.textMuted),
                          tooltip: 'Unpair / Forget',
                          onPressed: () => _unpairHost(addr),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityMatrix() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.fact_check_outlined, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Compatibility Matrix',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _buildMatrixRow(
            title: 'Android API Support',
            subtitle: 'Target API 28+ required (Device: Android ${_status.androidVersion}, API ${_status.sdkInt})',
            passed: _status.supportedApi,
          ),
          const Divider(),
          _buildMatrixRow(
            title: 'Bluetooth Hardware',
            subtitle: _status.bluetoothSupported ? 'Hardware adapter available' : 'No Bluetooth chip detected',
            passed: _status.bluetoothSupported,
          ),
          const Divider(),
          _buildMatrixRow(
            title: 'Bluetooth Enabled',
            subtitle: _status.bluetoothEnabled ? 'Bluetooth is powered on' : 'Bluetooth is currently turned off',
            passed: _status.bluetoothEnabled,
          ),
          const Divider(),
          _buildMatrixRow(
            title: 'Bluetooth Permissions',
            subtitle: _status.permissionsGranted
                ? 'Nearby device permissions granted'
                : 'Missing: ${_status.missingPermissions.join(", ")}',
            passed: _status.permissionsGranted,
            actionLabel: !_status.permissionsGranted ? 'Grant' : null,
            onAction: !_status.permissionsGranted ? _requestPermissions : null,
          ),
          const Divider(),
          _buildMatrixRow(
            title: 'HID Device Profile Proxy',
            subtitle: _status.profileAvailable
                ? 'HID profile proxy connected'
                : (_status.profilePending
                    ? 'Request pending with Bluetooth stack'
                    : 'Not connected (Requires registration)'),
            passed: _status.profileAvailable,
          ),
          const Divider(),
          _buildMatrixRow(
            title: 'SDP HID Registration',
            subtitle: _status.isRegistered
                ? 'Registered as Combo Mouse/Keyboard'
                : (_status.isRegistering ? 'Registration in progress' : 'Not registered'),
            passed: _status.isRegistered,
          ),
          const Divider(),
          _buildMatrixRow(
            title: 'Host Connection',
            subtitle: _status.connectionState,
            passed: _status.isConnected,
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow({
    required String title,
    required String subtitle,
    required bool passed,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: passed ? AppTheme.success : AppTheme.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildWindowsPairingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.laptop_windows_outlined, color: AppTheme.primary, size: 22),
        title: const Text(
          'Windows Pairing Guidance',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: const Text(
          'Standard OS Bluetooth pairing (No software on PC)',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildStep(1, 'Tap "Register Bluetooth HID Device" above.'),
          _buildStep(2, 'On your Windows 10/11 PC, open Settings > Bluetooth & devices.'),
          _buildStep(3, 'Click "Add device" and select "Bluetooth".'),
          _buildStep(4, 'Select this phone ("${_status.deviceModel}") from the list.'),
          _buildStep(5, 'Accept the Bluetooth pairing code on both PC and phone.'),
          _buildStep(6, 'Windows automatically loads standard HID drivers. No companion software needed!'),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsConsole() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: AppTheme.info, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Live Diagnostics Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _logs.clear()),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            color: Colors.black.withValues(alpha: 0.3),
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet. Events will appear here in real-time.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollController,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color logColor = AppTheme.textSecondary;
                      if (log.type.contains('error') || log.type.contains('failed')) {
                        logColor = AppTheme.error;
                      } else if (log.type.contains('success') || log.type.contains('connected')) {
                        logColor = AppTheme.success;
                      } else if (log.type.contains('request') || log.type.contains('action') || log.type.contains('input')) {
                        logColor = AppTheme.info;
                      }

                      final timeStr =
                          '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '[$timeStr] [${log.type.toUpperCase()}] ${log.message}',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: logColor,
                            height: 1.3,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
