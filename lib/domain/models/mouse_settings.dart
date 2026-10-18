class MouseSettings {
  final double sensitivity;
  final double scrollSensitivity;
  final bool accelerationEnabled;
  final bool invertScroll;
  final bool tapToClick;
  final bool hapticsEnabled;

  const MouseSettings({
    this.sensitivity = 1.2,
    this.scrollSensitivity = 1.0,
    this.accelerationEnabled = true,
    this.invertScroll = false,
    this.tapToClick = true,
    this.hapticsEnabled = true,
  });

  MouseSettings copyWith({
    double? sensitivity,
    double? scrollSensitivity,
    bool? accelerationEnabled,
    bool? invertScroll,
    bool? tapToClick,
    bool? hapticsEnabled,
  }) {
    return MouseSettings(
      sensitivity: sensitivity ?? this.sensitivity,
      scrollSensitivity: scrollSensitivity ?? this.scrollSensitivity,
      accelerationEnabled: accelerationEnabled ?? this.accelerationEnabled,
      invertScroll: invertScroll ?? this.invertScroll,
      tapToClick: tapToClick ?? this.tapToClick,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sensitivity': sensitivity,
      'scrollSensitivity': scrollSensitivity,
      'accelerationEnabled': accelerationEnabled,
      'invertScroll': invertScroll,
      'tapToClick': tapToClick,
      'hapticsEnabled': hapticsEnabled,
    };
  }

  factory MouseSettings.fromMap(Map<String, dynamic> map) {
    return MouseSettings(
      sensitivity: (map['sensitivity'] as num?)?.toDouble() ?? 1.2,
      scrollSensitivity: (map['scrollSensitivity'] as num?)?.toDouble() ?? 1.0,
      accelerationEnabled: (map['accelerationEnabled'] as bool?) ?? true,
      invertScroll: (map['invertScroll'] as bool?) ?? false,
      tapToClick: (map['tapToClick'] as bool?) ?? true,
      hapticsEnabled: (map['hapticsEnabled'] as bool?) ?? true,
    );
  }
}
