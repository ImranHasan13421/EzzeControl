class BtDevice {
  final String name;
  final String address;
  final int type;
  final int deviceClass;
  final int majorDeviceClass;
  final bool isConnected;
  final bool isBonded;

  const BtDevice({
    required this.name,
    required this.address,
    this.type = 0,
    this.deviceClass = 0,
    this.majorDeviceClass = 0,
    this.isConnected = false,
    this.isBonded = true,
  });

  factory BtDevice.fromMap(Map<dynamic, dynamic> map) {
    return BtDevice(
      name: map['name'] as String? ?? 'Unknown Device',
      address: map['address'] as String? ?? '',
      type: (map['type'] as num?)?.toInt() ?? 0,
      deviceClass: (map['deviceClass'] as num?)?.toInt() ?? 0,
      majorDeviceClass: (map['majorDeviceClass'] as num?)?.toInt() ?? 0,
      isConnected: map['isConnected'] as bool? ?? false,
      isBonded: map['isBonded'] as bool? ?? true,
    );
  }

  /// Whether the Bluetooth device is classified as a Computer / Laptop.
  /// Major device class 0x0100 (256 in decimal) indicates a Computer.
  bool get isComputer {
    if (majorDeviceClass == 0x0100 || majorDeviceClass == 256) return true;
    final upper = name.toUpperCase();
    return upper.contains('PC') ||
        upper.contains('LAPTOP') ||
        upper.contains('DESKTOP') ||
        upper.contains('WIN') ||
        upper.contains('MAC');
  }

  BtDevice copyWith({
    String? name,
    String? address,
    int? type,
    int? deviceClass,
    int? majorDeviceClass,
    bool? isConnected,
    bool? isBonded,
  }) {
    return BtDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      deviceClass: deviceClass ?? this.deviceClass,
      majorDeviceClass: majorDeviceClass ?? this.majorDeviceClass,
      isConnected: isConnected ?? this.isConnected,
      isBonded: isBonded ?? this.isBonded,
    );
  }
}

class HidCapabilities {
  final bool isBluetoothSupported;
  final bool isBluetoothEnabled;
  final bool isHidSupported;
  final bool isProfileAvailable;
  final bool isRegistered;
  final bool isRegistering;
  final bool isDiscovering;
  final String connectionState;
  final String? connectedDeviceAddress;
  final String? connectedDeviceName;
  final bool hasPermissions;
  final List<String> missingPermissions;
  final String? lastError;

  const HidCapabilities({
    this.isBluetoothSupported = true,
    this.isBluetoothEnabled = false,
    this.isHidSupported = true,
    this.isProfileAvailable = false,
    this.isRegistered = false,
    this.isRegistering = false,
    this.isDiscovering = false,
    this.connectionState = 'DISCONNECTED',
    this.connectedDeviceAddress,
    this.connectedDeviceName,
    this.hasPermissions = true,
    this.missingPermissions = const [],
    this.lastError,
  });

  bool get isConnected => connectionState == 'CONNECTED';
  bool get isConnecting => connectionState == 'CONNECTING';

  factory HidCapabilities.fromMap(Map<dynamic, dynamic> map) {
    final missingList = (map['missingPermissions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return HidCapabilities(
      isBluetoothSupported: map['isBluetoothSupported'] as bool? ?? true,
      isBluetoothEnabled: map['isBluetoothEnabled'] as bool? ?? false,
      isHidSupported: map['isHidSupported'] as bool? ?? true,
      isProfileAvailable: map['isProfileAvailable'] as bool? ?? false,
      isRegistered: map['isRegistered'] as bool? ?? false,
      isRegistering: map['isRegistering'] as bool? ?? false,
      isDiscovering: map['isDiscovering'] as bool? ?? false,
      connectionState: map['connectionState'] as String? ?? 'DISCONNECTED',
      connectedDeviceAddress: map['connectedDeviceAddress'] as String?,
      connectedDeviceName: map['connectedDeviceName'] as String?,
      hasPermissions: map['hasPermissions'] as bool? ?? true,
      missingPermissions: missingList,
      lastError: map['lastError'] as String?,
    );
  }
}
