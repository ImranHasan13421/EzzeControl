# Ezze Control — System Architecture & Design Specification

## 1. Executive Summary

**Ezze Control** is an offline, production-grade Android utility built with **Flutter & Dart** and native **Android Bluetooth HID Device APIs** (Kotlin). It transforms a supported Android phone (primary test device: **Infinix X6833B** running **Android 14**, API 34) into a plug-and-play standard Bluetooth Mouse and Keyboard for host computers running **Windows 10** and **Windows 11**.

The application requires:
- **No PC-side server or companion software** (Windows recognizes the phone as a native Bluetooth HID Peripheral).
- **No internet, cloud accounts, telemetry, subscriptions, or ads**.
- **Ultra-low latency** HID reporting over Bluetooth L2CAP/HID profile.

---

## 2. Core Feature & Screen Breakdown

### 2.1 Screen 1: Main Menu (`/`)
* **Header**: App name ("Ezze Control") with rounded app icon (`assets/icons/app_logo.png`).
* **Grid Navigation (4 Primary Modules)**:
  1. **Paired Devices**: Navigates to paired devices management and connection initiation.
  2. **BT Devices**: Scans nearby discoverable Bluetooth devices and allows unpairing.
  3. **App Settings**: Minimal placeholder for future configurations.
  4. **App Guide**: Comprehensive user guide, Windows pairing walkthrough, and troubleshooting.

### 2.2 Screen 2: Paired Devices (`/paired`)
* **Header Actions**:
  - System Bluetooth Settings shortcut (opens `android.provider.Settings.ACTION_BLUETOOTH_SETTINGS`).
  - Help / Guide shortcut.
* **Sections**:
  - **Paired Devices List**: Query system bonded devices (`BluetoothAdapter.bondedDevices`) filtered for computers and laptops.
  - **Available Devices**: Discovered Bluetooth devices actively broadcasting.
* **Connection Modal / Dialog**:
  - Displays host PC name and MAC address.
  - Subtitle: *"Connect with PC/Mobile to use Bluetooth Mouse Keyboard now."*
  - **Connect Button** (Green): Initiates Bluetooth HID profile connection and navigates to the Mouse Pad screen.
  - **Cancel Button** (Red): Dismisses dialog.

### 2.3 Screen 3: Bluetooth Devices & Unpairing (`/bt_devices`)
* **Scan Radar Animation**: Visual pulsating radar indicating discovery state.
* **Device Cards**:
  - Host name, MAC address, device type icon (computer, laptop).
  - Prominent **UNPAIR** button: Invokes `BluetoothDevice.removeBond()` via platform channel to unpair cleanly.
* **Available Devices**:
  - Discovered nearby Bluetooth devices with option to pair.

### 2.4 Screen 4: App Settings (`/settings`)
* Minimal clean UI ready for future configurations (theme customization, custom HID profiles, haptic feedback toggles).

### 2.5 Screen 5: App Guide (`/guide`)
* Step-by-step instructions for pairing with Windows 10 & Windows 11.
* Touchpad gestures reference (single tap, two-finger tap, double-tap drag, two-finger scroll).
* Keyboard and speech input instructions.
* Permissions and Bluetooth troubleshooting steps.

### 2.6 Screen 6: Mouse & Keyboard Pad (`/mouse_pad`)
* **Header**:
  - Back arrow to return.
  - Connected PC Name (e.g. `IMRAN-LAPTOP`).
  - Power / Disconnect button: Releases inputs, disconnects HID profile, returns to main menu.
  - Keyboard Toggle button: Pops up the soft keyboard for real-time live typing to PC.
  - 3-Dot Overflow Menu button: Opens the feature drawer / menu.
* **Touchpad Surface**:
  - Dark navy/charcoal responsive touch surface with rounded corners.
  - **Pointer Movement**: Low-latency relative delta tracking with sensitivity and acceleration curves.
  - **Tap to Click**: Single finger tap sends Left Mouse Button click.
  - **Two-Finger Tap**: Sends Right Mouse Button click.
  - **Laptop-style Select & Drag**: Double-tap and hold allows continuous dragging (holding Left Mouse Button down while tracking movement until finger lift).
  - **Scroll**: Two-finger vertical drag sends HID wheel reports.
* **Bottom Controls**:
  - **Left Click** button: Large ergonomic blue button sending Left Mouse Button press & release.
  - **Right Click** button: Large ergonomic blue button sending Right Mouse Button press & release.
* **3-Dot Action Menu**:
  1. **Function Keys (F1 – F12)**: Grid of F1–F12, Esc, Tab, Win, Ctrl, Alt, Del keys.
  2. **Text Input**: "Add Text" dialog with "Clear", "Send", "Cancel". Batch converts text into HID keystrokes and streams to PC.
  3. **Number Pad**: Full desktop 10-key numeric keypad (0–9, Enter, Num Lock, +, -, *, /, Del).
  4. **Speak-to-Type**: Uses Google Speech Recognition (`RecognizerIntent`) to convert spoken speech to text and automatically types it into the active PC window.
  5. **Mouse Pointer Speed**: Dialog slider adjusting cursor sensitivity multiplier with "Default", "OK", "Cancel".
  6. **Mouse Scroll Speed**: Dialog slider adjusting scroll wheel sensitivity with "Default", "OK", "Cancel".
  7. **Clipboard & Media Remote**: Shortcuts for multimedia controls (Play/Pause, Vol+, Vol-, Mute).

---

## 3. Technology Stack & System Architecture

```
+-------------------------------------------------------------------+
|                        Flutter UI Layer (Dart)                    |
|  - Main Menu       - Paired Devices Screen   - BT Devices Screen  |
|  - Mouse Pad       - Keyboards & Numpad      - Dialogs & Sheets   |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|              State Management & Business Logic (Dart)             |
|  - BluetoothHidRepository (Device management, connection state)   |
|  - MouseSettingsRepository (Speed, scroll, haptics)               |
|  - SpeechInputService (Google Speech to Text transcription)       |
+-------------------------------------------------------------------+
                                  | MethodChannel & EventChannel
                                  v
+-------------------------------------------------------------------+
|               Android Platform Channel (Kotlin)                   |
|  - HidPlatformChannel.kt (Method calls & Stream handlers)         |
|  - BluetoothHidManager.kt (Android BluetoothHidDevice wrapper)    |
|  - HidReportEncoder.kt (Mouse & Keyboard packet serializer)       |
|  - HidReportDescriptor.kt (USB-IF compliant HID Report Descriptor)|
+-------------------------------------------------------------------+
                                  | Android Bluetooth Subsystem
                                  v
+-------------------------------------------------------------------+
|                     Android 14 OS (Bluetooth HID)                 |
|             Host Windows 10 / Windows 11 PC (L2CAP/HID)           |
+-------------------------------------------------------------------+
```

---

## 4. USB HID Protocol Specification

Standard USB-IF HID composite device descriptor with two report IDs:
- **Report ID 1: Mouse** (4-byte packet):
  - Byte 0: Buttons bitmask (`0x01` Left, `0x02` Right, `0x04` Middle, `0x08` Back, `0x10` Forward)
  - Byte 1: Relative X displacement (`-127` to `+127`)
  - Byte 2: Relative Y displacement (`-127` to `+127`)
  - Byte 3: Relative Wheel displacement (`-127` to `+127`)
- **Report ID 2: Keyboard** (8-byte standard boot report):
  - Byte 0: Modifier bitmask (Left Ctrl `0x01`, Left Shift `0x02`, Left Alt `0x04`, Left GUI `0x08`, Right Ctrl `0x10`, Right Shift `0x20`, Right Alt `0x40`, Right GUI `0x80`)
  - Byte 1: Reserved (`0x00`)
  - Bytes 2–7: Keycodes array (up to 6 simultaneous keys, USB HID Usage Tables for Keyboard/Keypad)

---

## 5. Security & Android 14 Permissions

Targeting Android 14 (API 34) with runtime permissions:
- `android.permission.BLUETOOTH_CONNECT`
- `android.permission.BLUETOOTH_ADVERTISE`
- `android.permission.BLUETOOTH_SCAN`
- `android.permission.RECORD_AUDIO` (for Google Speech recognition)
- `android.permission.ACCESS_FINE_LOCATION` (fallback for discovery on Android 11 and below)

---

## 6. Directory Structure

```
EzzeControl/
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/com/ezze/control/ezze_control/
│   │           ├── MainActivity.kt
│   │           ├── BluetoothHidManager.kt
│   │           ├── HidPlatformChannel.kt
│   │           ├── HidReportDescriptor.kt
│   │           └── HidReportEncoder.kt
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── assets/
│   ├── icons/
│   │   └── app_logo.png
│   └── sample/
│       └── [reference images 1-10]
├── lib/
│   ├── app/
│   │   ├── app_theme.dart
│   │   └── routes.dart
│   ├── data/
│   │   ├── bluetooth_hid_repository.dart
│   │   ├── settings_repository.dart
│   │   └── speech_service.dart
│   ├── domain/
│   │   ├── hid_key_codes.dart
│   │   └── models.dart
│   ├── features/
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── paired_devices/
│   │   │   ├── paired_devices_screen.dart
│   │   │   └── widgets/connect_dialog.dart
│   │   ├── bt_devices/
│   │   │   └── bt_devices_screen.dart
│   │   ├── mouse_pad/
│   │   │   ├── mouse_pad_screen.dart
│   │   │   ├── widgets/touchpad_surface.dart
│   │   │   ├── widgets/speed_dialog.dart
│   │   │   ├── widgets/text_input_dialog.dart
│   │   │   ├── widgets/function_keys_sheet.dart
│   │   │   └── widgets/number_pad_sheet.dart
│   │   ├── guide/
│   │   │   └── app_guide_screen.dart
│   │   └── settings/
│   │       └── app_settings_screen.dart
│   └── main.dart
├── test/
│   ├── hid_report_encoder_test.dart
│   └── widget_test.dart
├── pubspec.yaml
└── architecture.md
```

---

## 7. Quality Assurance & Verification Targets

1. `flutter pub get` — dependencies resolved cleanly.
2. `flutter analyze` — 0 errors, 0 warnings.
3. `flutter test` — unit tests passing for HID report generation and key mapping.
4. `flutter build apk --debug` — Gradle Android build passes cleanly on Android 14 SDK.
5. Git synchronization to `https://github.com/ImranHasan13421/EzzeControl`.
