/// Standard USB HID Keycodes and Modifiers
class HidKeyCodes {
  // Modifiers
  static const int modifierNone = 0x00;
  static const int modifierLeftCtrl = 0x01;
  static const int modifierLeftShift = 0x02;
  static const int modifierLeftAlt = 0x04;
  static const int modifierLeftGui = 0x08; // Windows key
  static const int modifierRightCtrl = 0x10;
  static const int modifierRightShift = 0x20;
  static const int modifierRightAlt = 0x40;
  static const int modifierRightGui = 0x80;

  // Mouse Buttons Bitmask
  static const int mouseButtonNone = 0x00;
  static const int mouseButtonLeft = 0x01;
  static const int mouseButtonRight = 0x02;
  static const int mouseButtonMiddle = 0x04;

  // Function Keys F1 - F12
  static const int keyF1 = 0x3A;
  static const int keyF2 = 0x3B;
  static const int keyF3 = 0x3C;
  static const int keyF4 = 0x3D;
  static const int keyF5 = 0x3E;
  static const int keyF6 = 0x3F;
  static const int keyF7 = 0x40;
  static const int keyF8 = 0x41;
  static const int keyF9 = 0x42;
  static const int keyF10 = 0x43;
  static const int keyF11 = 0x44;
  static const int keyF12 = 0x45;

  // Common Control & Navigation Keys
  static const int keyEnter = 0x28;
  static const int keyEscape = 0x29;
  static const int keyBackspace = 0x2A;
  static const int keyTab = 0x2B;
  static const int keySpace = 0x2C;
  static const int keyPrintScreen = 0x46;
  static const int keyScrollLock = 0x47;
  static const int keyPause = 0x48;
  static const int keyInsert = 0x49;
  static const int keyHome = 0x4A;
  static const int keyPageUp = 0x4B;
  static const int keyDelete = 0x4C;
  static const int keyEnd = 0x4D;
  static const int keyPageDown = 0x4E;
  static const int keyRight = 0x4F;
  static const int keyLeft = 0x50;
  static const int keyDown = 0x51;
  static const int keyUp = 0x52;

  // Desktop Number Pad (Keypad)
  static const int keyNumLock = 0x53;
  static const int keyKpSlash = 0x54;
  static const int keyKpAsterisk = 0x55
  ;
  static const int keyKpMinus = 0x56;
  static const int keyKpPlus = 0x57;
  static const int keyKpEnter = 0x58;
  static const int keyKp1 = 0x59;
  static const int keyKp2 = 0x5A;
  static const int keyKp3 = 0x5B;
  static const int keyKp4 = 0x5C;
  static const int keyKp5 = 0x5D;
  static const int keyKp6 = 0x5E;
  static const int keyKp7 = 0x5F;
  static const int keyKp8 = 0x60;
  static const int keyKp9 = 0x61;
  static const int keyKp0 = 0x62;
  static const int keyKpDot = 0x63;
}
