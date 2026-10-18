# Ezze Control

**Ezze Control** is a production-quality, offline Android utility built with Flutter and native Android Bluetooth HID APIs. It turns a supported Android phone into a plug-and-play standard Bluetooth mouse and keyboard for Windows 10 and Windows 11 PCs.

No PC-side server, internet access, account, advertisements, telemetry, or third-party background daemon is required.

---

## Features

### 1. Main Navigation Menu
- Header with official glowing Ezze Control icon and typography.
- 4 primary modular navigation cards:
  - **Paired Devices**: Access previously paired computers and connect.
  - **BT Devices**: Scan nearby Bluetooth devices and manage unpairing.
  - **App Settings**: Clean placeholder for upcoming preferences.
  - **App Guide**: Comprehensive usage guide and troubleshooting tips.

### 2. Paired Devices Management
- Dedicated list of paired computers with device type and MAC address.
- Available devices scanner for discovering new Bluetooth hosts.
- Quick navigation shortcuts to Android Bluetooth Settings and the App Guide.
- One-tap connection dialog with "Connect" and "Cancel" actions.

### 3. Bluetooth Devices & Unpairing
- Animated pulsating Bluetooth radar scanner.
- Available nearby devices discovery.
- One-tap "UNPAIR" action with confirmation to cleanly remove Bluetooth bonds.

### 4. Interactive Touchpad & Mouse Controller
- **Large Usable Touchpad**: Low-latency relative pointer movement with dynamic acceleration.
- **Laptop-Style Select & Drag**: Double-tap and hold on the touchpad to select text or drag files/folders across the screen just like a laptop trackpad.
- **Tap to Click**: Single-finger tap for Left Click, two-finger tap for Right Click.
- **Ergonomic Buttons**: Large dedicated "Left Click" and "Right Click" buttons.
- **Smooth Scrolling**: Two-finger vertical drag for document and web page scrolling.

### 5. Advanced Input Suite (3-Dot Overflow Menu)
- **Live Keyboard**: Real-time typing streaming from the phone's native keyboard to the PC.
- **Function Keys (F1 – F12)**: Full keyboard function keys with Esc, Tab, Win, Ctrl, Alt, and Del.
- **Text Input Dialog**: Compose, paste, or clear multi-line text and batch-stream to the desktop.
- **Number Pad**: Standard 10-key numeric desktop keypad with NumLock.
- **Speak-to-Type**: Voice-to-text integration using Google Speech Services to convert speech into keystrokes sent directly to the PC.
- **Sensitivity Controls**: Dedicated dialog sliders to calibrate pointer speed and scroll sensitivity with one-click factory reset.
- **Media Remote**: Instant play/pause, volume controls, and track navigation.

---

## Technical Specifications & Architecture

- **Framework**: Flutter 3.41+ (Dart 3.11+)
- **Target OS**: Android 14 (API 34) — Tested on Infinix X6833B
- **Host Compatibility**: Windows 10, Windows 11 (Standard USB HID Specification)
- **Profile**: Native Android `BluetoothHidDevice` API (API 28+)
- **Security & Privacy**: Zero telemetry, zero cloud calls, pure local Bluetooth L2CAP/HID connection.

See [architecture.md](architecture.md) for full architectural blueprints, report descriptors, and platform channel documentation.

---

## Build & Verification

```bash
# Get dependencies
flutter pub get

# Run code analysis
flutter analyze

# Run unit & smoke tests
flutter test

# Build debug APK
flutter build apk --debug
```

---

## License

MIT License. Free and open source for personal and commercial use.
