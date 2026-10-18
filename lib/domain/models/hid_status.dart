class HidStatus {
  final bool supportedApi;
  final int sdkInt;
  final String deviceModel;
  final String androidVersion;
  final bool bluetoothSupported;
  final bool bluetoothEnabled;
  final bool permissionsGranted;
  final List<String> missingPermissions;
  final bool profileAvailable;
  final bool profilePending;
  final bool isRegistered;
  final bool isRegistering;
  final String connectionState;
  final String? connectedDeviceName;
  final String? connectedDeviceAddress;
  final String? lastError;

  const HidStatus({
    this.supportedApi = false,
    this.sdkInt = 0,
    this.deviceModel = 'Unknown',
    this.androidVersion = 'Unknown',
    this.bluetoothSupported = false,
    this.bluetoothEnabled = false,
    this.permissionsGranted = false,
    this.missingPermissions = const [],
    this.profileAvailable = false,
    this.profilePending = false,
    this.isRegistered = false,
    this.isRegistering = false,
    this.connectionState = 'DISCONNECTED',
    this.connectedDeviceName,
    this.connectedDeviceAddress,
    this.lastError,
  });

  factory HidStatus.fromMap(Map<dynamic, dynamic> map) {
    return HidStatus(
      supportedApi: map['supportedApi'] as bool? ?? false,
      sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
      deviceModel: map['deviceModel'] as String? ?? 'Unknown',
      androidVersion: map['androidVersion'] as String? ?? 'Unknown',
      bluetoothSupported: map['bluetoothSupported'] as bool? ?? false,
      bluetoothEnabled: map['bluetoothEnabled'] as bool? ?? false,
      permissionsGranted: map['permissionsGranted'] as bool? ?? false,
      missingPermissions: (map['missingPermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      profileAvailable: map['profileAvailable'] as bool? ?? false,
      profilePending: map['profilePending'] as bool? ?? false,
      isRegistered: map['isRegistered'] as bool? ?? false,
      isRegistering: map['isRegistering'] as bool? ?? false,
      connectionState: map['connectionState'] as String? ?? 'DISCONNECTED',
      connectedDeviceName: map['connectedDeviceName'] as String?,
      connectedDeviceAddress: map['connectedDeviceAddress'] as String?,
      lastError: map['lastError'] as String?,
    );
  }

  bool get isReadyToRegister =>
      supportedApi && bluetoothSupported && bluetoothEnabled && permissionsGranted;

  bool get isConnected => connectionState == 'CONNECTED';
  bool get isConnecting => connectionState == 'CONNECTING';

  @override
  String toString() {
    return 'HidStatus(api=$supportedApi, bt=$bluetoothEnabled, perms=$permissionsGranted, '
        'profile=$profileAvailable, reg=$isRegistered, state=$connectionState, error=$lastError)';
  }
}

class DiagnosticLog {
  final DateTime timestamp;
  final String type;
  final String message;

  DiagnosticLog({
    DateTime? timestamp,
    required this.type,
    required this.message,
  }) : timestamp = timestamp ?? DateTime.now();
}
