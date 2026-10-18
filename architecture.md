# Ezze Control — Technical Architecture

**Document type:** Architecture and engineering specification  
**Project:** Ezze Control  
**Primary platform:** Android  
**PC platform:** Windows 10 / Windows 11  
**Client stack:** Flutter + Dart  
**Native integration:** Kotlin + Android Bluetooth HID Device API  
**Minimum Android API:** 28 (Android 9), subject to runtime hardware/firmware support  
**Status:** Proposed architecture; HID support must be verified on the actual device before full implementation.

---

## 1. Purpose and Product Definition

Ezze Control turns a supported Android phone into a wireless mouse and keyboard for a Windows PC. The phone should be recognized by Windows as a **standard Bluetooth Human Interface Device (HID)**.

### Non-negotiable product constraints

- No custom Windows companion application, receiver, service, daemon, or server.
- No cloud backend, account, subscription, or internet connection required for Bluetooth HID use.
- Flutter and Dart provide the application UI and most application logic.
- Kotlin is permitted for Android APIs that Flutter cannot access directly.
- The app must use real operating-system APIs and real HID reports; no simulated connection or fake success states.
- The application must remain free to develop and use, relying on free tools and appropriately licensed dependencies.
- Wi-Fi is not part of the initial release. A Wi-Fi solution that requires PC-side software would violate the no-companion requirement and must not be silently substituted for HID.

### Definition of success

On a compatible phone, a user can pair Ezze Control with Windows using the normal operating-system flow, then use the phone to move the cursor, click, scroll, and send keyboard input without installing software on Windows.

This outcome is conditional on the Android device exposing the required Bluetooth HID Device profile and Windows supporting Bluetooth HID Host operation.

---

## 2. Scope and Non-goals

### MVP scope

1. Bluetooth HID compatibility diagnostics.
2. HID profile acquisition and application registration.
3. Actual connection status reporting.
4. Mouse touchpad and mouse buttons.
5. Virtual keyboard and key combinations.
6. Connectivity and troubleshooting screen.
7. Local preferences such as pointer sensitivity.
8. Error handling, lifecycle cleanup, and basic automated tests.
9. Debug/release APK build instructions.

### Out of scope for MVP

- Windows companion software of any kind.
- Remote desktop, screen streaming, or file transfer.
- Cloud sync, user accounts, telemetry, ads, and analytics.
- Internet-based discovery or relay.
- Wi-Fi control that requires a receiver on the PC.
- Guaranteed operation on every Android phone or OEM firmware.
- Guaranteed Unicode text entry for every language and Windows keyboard layout.
- Guaranteed operation on Windows secure desktop/UAC screens or applications that restrict injected/remote input.
- Guaranteed persistent HID registration while the app is backgrounded if Android unregisters the HID app.

Optional later features must not compromise the core no-PC-software constraint.

---

## 3. Platform and Compatibility Requirements

### Android

- Minimum API level: 28 (Android 9), because the public `BluetoothHidDevice` API was introduced at API 28.
- Primary validation device: Infinix X6833B running Android 14.
- Use a current stable compile SDK supported by the installed Flutter/Android Gradle toolchain.
- Set `targetSdk` according to the selected distribution channel and current Android/Play requirements. Do not hard-code an obsolete target just to make development easier.
- Request only permissions needed for the OS versions actually supported.
- Check hardware/profile availability at runtime. Android version alone does not prove that an OEM exposes the profile.

### Bluetooth permissions

Review official Android permission requirements for the chosen `targetSdk` and handle version differences. On Android 12/API 31 and later, nearby-device Bluetooth permissions such as `BLUETOOTH_CONNECT` and, if needed by the actual APIs used, `BLUETOOTH_SCAN` must be handled appropriately. Legacy Bluetooth permissions may need legacy-version declarations with `maxSdkVersion` constraints. Do not request location permission unless the selected scanning/discovery behavior genuinely requires it under the relevant Android version.

Use runtime permission requests where required. Permission denial must produce an explanatory state and a recoverable path to system settings.

### Windows

- Target Windows 10 and Windows 11.
- Require a Bluetooth adapter and Bluetooth HID Host support.
- Pair using normal Windows settings/system UX.
- Do not require installation of a custom executable, driver, service, script, or application on Windows.
- Validate on real Windows hardware before claiming compatibility.

### Compatibility states

Model these states distinctly:
- Bluetooth unavailable
- Bluetooth disabled
- Permission required
- Permission denied
- HID profile request pending
- HID profile unsupported/unavailable
- HID application registration pending
- HID registration failed
- HID registered but not connected
- Connecting
- Connected
- Disconnecting
- Disconnected
- Recoverable error
- Unsupported/unknown state

Do not collapse “profile obtained,” “application registered,” “paired,” and “connected” into one generic connected state.

---

## 4. High-level Architecture

```text
┌──────────────────────────────────────────────────────────────┐
│                    Ezze Control (Android)                    │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Flutter Presentation (Dart)                            │  │
│  │ Mouse Screen | Keyboard Screen | Connectivity Screen   │  │
│  └──────────────────────────┬─────────────────────────────┘  │
│                             │                                │
│  ┌──────────────────────────▼─────────────────────────────┐  │
│  │ Application / Domain Layer (Dart)                      │  │
│  │ Input models | Connection state | Settings | Use cases │  │
│  └──────────────────────────┬─────────────────────────────┘  │
│                             │                                │
│  ┌──────────────────────────▼─────────────────────────────┐  │
│  │ Bluetooth HID Service Interface (Dart)                 │  │
│  │ MethodChannel commands + EventChannel/event stream     │  │
│  └──────────────────────────┬─────────────────────────────┘  │
│                             │ Flutter platform channel       │
│  ┌──────────────────────────▼─────────────────────────────┐  │
│  │ Native Android Adapter (Kotlin)                        │  │
│  │ Permissions | Bluetooth adapter | HID profile callbacks│  │
│  │ HID registration | connection state | report sending   │  │
│  └──────────────────────────┬─────────────────────────────┘  │
│                             │                                │
│  ┌──────────────────────────▼─────────────────────────────┐  │
│  │ Android Bluetooth Stack → Bluetooth HID → Windows      │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Architectural principles

- Keep UI independent of Android Bluetooth classes.
- Keep Kotlin APIs behind a typed platform-channel boundary.
- Treat the native layer as the source of truth for Bluetooth/HID state.
- Send high-frequency mouse movement efficiently; avoid excessive per-event logging or unnecessary UI rebuilds.
- Ensure key/button state cleanup on screen changes, errors, disconnections, and lifecycle transitions.
- Use one connection/state service shared by all screens.
- Persist only user preferences, not typed content or sensitive input.

---

## 5. Suggested Project Structure

Adapt this structure to the actual generated Flutter project; do not create empty abstractions merely to match the tree.

```text
ezze_control/
├── README.md
├── ARCHITECTURE.md
├── PROMPT.md
├── analysis_options.yaml
├── pubspec.yaml
├── assets/
│   ├── icons/
│   └── images/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── app_theme.dart
│   │   └── app_routes.dart
│   ├── core/
│   │   ├── errors/
│   │   ├── logging/
│   │   ├── platform/
│   │   └── widgets/
│   ├── domain/
│   │   ├── models/
│   │   │   ├── hid_status.dart
│   │   │   ├── mouse_input.dart
│   │   │   ├── keyboard_input.dart
│   │   │   └── app_settings.dart
│   │   └── services/
│   │       └── hid_controller.dart
│   ├── data/
│   │   ├── bluetooth_hid_repository.dart
│   │   └── settings_repository.dart
│   ├── features/
│   │   ├── mouse/
│   │   │   ├── mouse_screen.dart
│   │   │   ├── mouse_controller.dart
│   │   │   └── widgets/
│   │   ├── keyboard/
│   │   │   ├── keyboard_screen.dart
│   │   │   ├── keyboard_controller.dart
│   │   │   └── widgets/
│   │   ├── connectivity/
│   │   │   ├── connectivity_screen.dart
│   │   │   └── connectivity_controller.dart
│   │   └── settings/
│   │       └── settings_screen.dart
│   └── navigation/
│       └── bottom_navigation.dart
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/<package-path>/
│           ├── MainActivity.kt
│           ├── BluetoothHidManager.kt
│           ├── HidPlatformChannel.kt
│           ├── HidReportDescriptor.kt
│           └── HidReportEncoder.kt
└── test/
    ├── domain/
    ├── mouse/
    ├── keyboard/
    └── report_encoding/
```

Keep report descriptor and report encoding code testable independently where practical. If the actual implementation benefits from a smaller initial structure, start small and refactor only when justified.

---

## 6. Flutter Layer Responsibilities

### Presentation

- Render Mouse, Keyboard, Connectivity, and Settings screens.
- Display status from the shared application state.
- Translate touch gestures and key taps into domain-level input events.
- Never access `BluetoothHidDevice` directly.
- Avoid rebuilding the entire screen for every mouse movement event.

### Domain/application

Define platform-independent types and operations, for example:
- `HidStatus`
- `HidConnectionState`
- `MouseMovement`
- `MouseButton`
- `ScrollDelta`
- `KeyboardKey`
- `ModifierState`
- `AppSettings`

Expose operations such as:
- `checkCompatibility()`
- `requestHidRegistration()`
- `disconnect()`
- `sendMouseMovement(dx, dy)`
- `sendMouseButton(button, pressed)`
- `sendScroll(dx, dy)`
- `sendKeyboardReport(...)`
- `releaseAllInputs()`
- `watchStatus()`

Names may change during implementation, but the API must remain typed and documented.

### Data/platform repository

- Implements the Dart-side platform-channel client.
- Converts native responses to typed models.
- Maps platform errors into user-readable error categories.
- Provides a status event stream.
- Prevents screens from directly depending on channel method names.

### State management

Use Flutter's built-in mechanisms or a small, free, maintained state-management package if there is a clear benefit. Do not add a large framework solely by habit. Keep one authoritative connection state shared across navigation.

---

## 7. Native Kotlin HID Layer

### Responsibilities

`BluetoothHidManager` (or an equivalent focused service) should own:
- Bluetooth adapter access
- HID profile acquisition
- HID profile service listener
- HID registration and unregistration
- HID device connection callbacks
- Connection-state tracking
- Sending validated input reports
- Input release/cleanup
- Native error reporting

`HidPlatformChannel` should expose a narrow, documented method-channel API and a status event stream to Flutter.

`HidReportDescriptor` should contain the reviewed HID report descriptor. `HidReportEncoder` should produce valid reports with clearly documented field ranges, signedness, report IDs (if used), and byte ordering.

### Registration and connection lifecycle

1. Check API level and Bluetooth availability.
2. Confirm required permissions.
3. Request the HID Device profile proxy.
4. Wait for the profile service callback.
5. Register the HID application with the chosen descriptor and callbacks.
6. Wait for the actual registration callback.
7. Present Windows pairing instructions and follow supported OS pairing behavior.
8. Track actual connection callbacks.
9. Send reports only when registration and connection states allow it.
10. On disconnect/error, release input states when possible, update state, and expose recovery guidance.
11. Close/release resources safely according to Android API lifecycle requirements.

Never set `connected = true` because a method call was issued. Only update state from actual platform callbacks.

### Lifecycle limitations

The platform may unregister the HID application when the app is no longer foregrounded. Do not promise indefinite background operation. Test app backgrounding, screen locking, navigation, process termination, Bluetooth toggles, and reconnect behavior on the actual device. Choose a compliant recovery strategy and document any unavoidable limitations.

### Platform-channel contract

Use typed method arguments and typed result maps. Suggested operations:
- `getCapabilities`
- `requestHidRegistration`
- `unregisterHid`
- `getStatus`
- `disconnect`
- `sendMouseReport`
- `sendKeyboardReport`
- `releaseAllInputs`

Status events should report meaningful state changes, error codes, and safe diagnostic messages. Do not include typed text or sensitive input in logs.

The exact contract may be refined during implementation but must be documented and consistent on both sides.

---

## 8. HID Report and Input Design

### Mouse

Implement a descriptor suitable for a standard mouse with:
- Button bits for left, right, middle (additional buttons only if implemented)
- Relative X and Y movement
- Scroll wheel
- Optional horizontal wheel only if descriptor and host behavior are validated

Define report sizes and signed ranges explicitly. Clamp or split out-of-range movement values safely. Use a report format that Windows actually recognizes.

### Keyboard

Use a standard keyboard HID report layout with modifier bits and key usages. Carefully handle:
- Key-down/key-up transitions
- Multiple simultaneous keys
- Modifier ordering
- Rollover limitations
- Key release after touch cancellation
- Keyboard focus changes
- Screen changes and disconnects

Do not send arbitrary Unicode strings as if they were guaranteed to map directly to HID key usages. Host keyboard layout and character mapping affect text input. Document supported behavior and test it with Windows layout settings.

### Input cleanup

Maintain a native and/or domain-level set of currently pressed keys and mouse buttons. On cancellation, navigation away from an active input surface, disconnect, or recoverable error:
- Send releases where the connection allows.
- Clear local pressed-state tracking.
- Ensure a later connection does not inherit stale pressed states.

Avoid unnecessary input report traffic and debug logging. Mouse movement should feel responsive; coalescing may be used carefully if it does not make input laggy or lose important button transitions.

---

## 9. UI/UX Specification

### Navigation

Persistent bottom navigation with three destinations:
1. Mouse
2. Keyboard
3. Connectivity

Settings may be accessible from the app bar or Connectivity screen. Display a compact global connection indicator.

### Mouse screen

- Large touchpad surface covering most available space
- Sensitivity control in settings
- Left/right/middle click controls
- Clear click and gesture feedback
- Optional help hint for two-finger scrolling
- Prevent accidental clicks during scrolling
- Respect safe areas and device rotation

### Keyboard screen

- Dedicated keyboard layout designed for touchscreens
- Readable key labels and comfortable key sizes
- Distinct modifier and special-key styling
- Clear active modifier states
- No unnecessary decorative panels that reduce keyboard area

### Connectivity screen

- Bluetooth/HID status card
- Current status and connected PC name only when actually available
- Clear pairing instructions
- Compatibility check action
- Permission/settings guidance
- Retry/recover action where meaningful
- Troubleshooting for unsupported profile, failed registration, pairing issues, and disconnects

### Visual style

Use a clean, professional utility-app aesthetic:
- Dark navy/charcoal surfaces
- Blue accent
- Readable typography
- Consistent spacing and icons
- Restrained corner radii
- Subtle motion
- High contrast and accessible touch targets

Support light theme if feasible without delaying HID validation. Avoid overdecorated UI and unnecessary animation.

---

## 10. Permissions, Privacy, and Security

- No accounts, cloud services, analytics, advertising SDKs, or remote logging.
- Do not store typed text, keystrokes, passwords, or mouse activity history.
- Store only needed preferences, such as sensitivity and theme.
- Request minimum necessary Bluetooth permissions for the configured target SDK and API range.
- Explain Bluetooth permission requests in context.
- Handle denied/restricted permissions gracefully.
- Never hardcode signing keys, secrets, or private credentials.
- Keep debug logs free of keyboard content and other sensitive input.
- Do not use hidden APIs or attempt to bypass Android/Windows security.
- Do not promise control over protected Windows secure-desktop screens or every elevated application.

---

## 11. Error Handling and Observability

Create typed error categories for:
- Unsupported Android API
- Bluetooth hardware unavailable
- Bluetooth disabled
- Permission denied
- HID profile unavailable
- Profile request failed
- Registration failed
- HID not registered
- Not connected
- Connection lost
- Invalid report
- Platform channel failure
- Unexpected native exception

User messages should be concise and actionable. Technical details may be available in a diagnostics view without exposing sensitive data.

Do not swallow exceptions. Do not loop endlessly on failed registration or reconnect attempts. Retry only when appropriate, with explicit user control or a bounded strategy.

---

## 12. Testing Strategy

### Unit tests

- Mouse report encoding and value clamping
- Keyboard report encoding
- Modifier state transitions
- Key/button release cleanup
- Status mapping
- Error mapping
- Settings serialization

### Widget tests

- Bottom navigation
- Status rendering
- Permission/error screens
- Mouse control interactions where practical
- Keyboard modifier UI states

### Manual device tests

On the actual Infinix Android 14 phone:
- Bluetooth enabled/disabled
- HID profile available/unavailable
- Permission granted/denied
- Registration success/failure
- Windows pairing and actual HID connection
- Cursor movement and all implemented buttons
- Scroll behavior
- Keyboard input and modifier combinations
- Disconnect/reconnect
- App backgrounding and screen lock
- App process termination
- Bluetooth toggle while connected

### Windows tests

Test on Windows 10 and Windows 11 if hardware is available. Confirm Windows recognizes the phone as a standard HID device and works without installing a custom program.

### Reporting rules

Every feature/test must be labeled honestly:
- Implemented
- Compiled
- Unit-tested
- Emulator-tested
- Tested on physical Android device
- Verified on Windows

Do not claim an unperformed test passed.

---

## 13. Build, Release, and Cost

- Use free tools and free dependencies.
- Provide exact commands for `flutter pub get`, `flutter analyze`, `flutter test`, and APK builds.
- Produce a debug APK for initial testing.
- Document release APK signing using a locally stored keystore.
- Never commit signing keys or passwords.
- Explain direct APK installation and its Android security prompts.
- Do not imply Play Store distribution is free; direct installation is available for personal testing.
- The app must not require a server or internet connection for its Bluetooth HID functionality.

---

## 14. Phased Implementation Plan

### Phase 1 — Inspect and verify compatibility
Inspect the workspace and installed toolchain. Create the smallest possible Flutter/Kotlin diagnostic prototype. Check Bluetooth permissions, obtain the HID profile, attempt registration, and report the actual callback result. Build/install if possible. Stop and report findings.

### Phase 2 — Prove real HID operation
Implement a minimal reviewed mouse/keyboard descriptor and report encoder. Establish pairing/connection with Windows. Test a real mouse movement and a real keyboard key without PC-side software. Do not continue if this has not been evaluated.

### Phase 3 — Mouse
Implement movement, clicks, scrolling, drag, sensitivity, and release handling.

### Phase 4 — Keyboard
Implement practical QWERTY input, special keys, modifiers, shortcuts, and release handling.

### Phase 5 — Full UI
Implement Mouse, Keyboard, Connectivity, Settings, shared status, theming, and local preferences.

### Phase 6 — Hardening
Test permissions, failures, lifecycle, disconnect/reconnect, performance, accessibility, static analysis, and release builds.

After each phase, summarize changed files, commands run, test results, known issues, and the next phase. Do not silently skip a failed phase.

---

## 15. Acceptance Criteria

The MVP is accepted only when all achievable core criteria are verified:

- [ ] Minimum API configuration is 28+.
- [ ] Unsupported HID capability is detected and explained.
- [ ] HID registration state comes from real native callbacks.
- [ ] Windows recognizes the phone as a Bluetooth HID device.
- [ ] No custom PC-side application is needed.
- [ ] Mouse movement works.
- [ ] Left/right clicks and scrolling work.
- [ ] Keyboard input works.
- [ ] Modifier and key-release behavior is tested.
- [ ] Connection status is truthful.
- [ ] Disconnect and error recovery are handled.
- [ ] Preferences persist locally.
- [ ] No cloud/backend dependency exists.
- [ ] Automated analysis/tests pass, or failures are documented.
- [ ] APK build instructions are documented.
- [ ] Physical-device and Windows test results are clearly distinguished from unverified behavior.

**Final instruction:** Begin with Phase 1 only. Inspect the existing workspace and environment, implement the compatibility prototype, test it where possible, and report actual results. Do not generate the complete application until the Bluetooth HID foundation has been evaluated.
