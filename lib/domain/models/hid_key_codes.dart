class HidModifiers {
  static const int none = 0x00;
  static const int leftCtrl = 0x01;
  static const int leftShift = 0x02;
  static const int leftAlt = 0x04;
  static const int leftGui = 0x08; // Windows key
  static const int rightCtrl = 0x10;
  static const int rightShift = 0x20;
  static const int rightAlt = 0x40;
  static const int rightGui = 0x80;
}

class HidKeyCodes {
  // Letters (0x04 - 0x1D)
  static const int keyA = 0x04;
  static const int keyB = 0x05;
  static const int keyC = 0x06;
  static const int keyD = 0x07;
  static const int keyE = 0x08;
  static const int keyF = 0x09;
  static const int keyG = 0x0A;
  static const int keyH = 0x0B;
  static const int keyI = 0x0C;
  static const int keyJ = 0x0D;
  static const int keyK = 0x0E;
  static const int keyL = 0x0F;
  static const int keyM = 0x10;
  static const int keyN = 0x11;
  static const int keyO = 0x12;
  static const int keyP = 0x13;
  static const int keyQ = 0x14;
  static const int keyR = 0x15;
  static const int keyS = 0x16;
  static const int keyT = 0x17;
  static const int keyU = 0x18;
  static const int keyV = 0x19;
  static const int keyW = 0x1A;
  static const int keyX = 0x1B;
  static const int keyY = 0x1C;
  static const int keyZ = 0x1D;

  // Numbers (0x1E - 0x27)
  static const int key1 = 0x1E;
  static const int key2 = 0x1F;
  static const int key3 = 0x20;
  static const int key4 = 0x21;
  static const int key5 = 0x22;
  static const int key6 = 0x23;
  static const int key7 = 0x24;
  static const int key8 = 0x25;
  static const int key9 = 0x26;
  static const int key0 = 0x27;

  // Control & Whitespace
  static const int keyEnter = 0x28;
  static const int keyEscape = 0x29;
  static const int keyBackspace = 0x2A;
  static const int keyTab = 0x2B;
  static const int keySpace = 0x2C;

  // Symbols & Punctuation
  static const int keyMinus = 0x2D; // - and _
  static const int keyEqual = 0x2E; // = and +
  static const int keyLeftBrace = 0x2F; // [ and {
  static const int keyRightBrace = 0x30; // ] and }
  static const int keyBackslash = 0x31; // \ and |
  static const int keySemicolon = 0x33; // ; and :
  static const int keyApostrophe = 0x34; // ' and "
  static const int keyGrave = 0x35; // ` and ~
  static const int keyComma = 0x36; // , and <
  static const int keyDot = 0x37; // . and >
  static const int keySlash = 0x38; // / and ?
  static const int keyCapsLock = 0x39;

  // Function Keys
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

  // Editing & Navigation
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

  // Media / System Keys
  static const int keyMute = 0x7F;
  static const int keyVolumeUp = 0x80;
  static const int keyVolumeDown = 0x81;

  /// Translates standard ASCII characters into USB HID KeyCode and Modifier combination.
  static HidKeyStroke? fromChar(String char) {
    if (char.isEmpty) return null;
    final code = char.codeUnitAt(0);

    // Lowercase a-z
    if (code >= 97 && code <= 122) {
      return HidKeyStroke(keyCode: keyA + (code - 97), modifier: HidModifiers.none);
    }
    // Uppercase A-Z
    if (code >= 65 && code <= 90) {
      return HidKeyStroke(keyCode: keyA + (code - 65), modifier: HidModifiers.leftShift);
    }
    // Digits 1-9
    if (code >= 49 && code <= 57) {
      return HidKeyStroke(keyCode: key1 + (code - 49), modifier: HidModifiers.none);
    }
    // Digit 0
    if (code == 48) {
      return const HidKeyStroke(keyCode: key0, modifier: HidModifiers.none);
    }

    // Common Whitespace & Punctuation
    switch (char) {
      case ' ':
        return const HidKeyStroke(keyCode: keySpace, modifier: HidModifiers.none);
      case '\n':
      case '\r':
        return const HidKeyStroke(keyCode: keyEnter, modifier: HidModifiers.none);
      case '\t':
        return const HidKeyStroke(keyCode: keyTab, modifier: HidModifiers.none);
      case '-':
        return const HidKeyStroke(keyCode: keyMinus, modifier: HidModifiers.none);
      case '_':
        return const HidKeyStroke(keyCode: keyMinus, modifier: HidModifiers.leftShift);
      case '=':
        return const HidKeyStroke(keyCode: keyEqual, modifier: HidModifiers.none);
      case '+':
        return const HidKeyStroke(keyCode: keyEqual, modifier: HidModifiers.leftShift);
      case '[':
        return const HidKeyStroke(keyCode: keyLeftBrace, modifier: HidModifiers.none);
      case '{':
        return const HidKeyStroke(keyCode: keyLeftBrace, modifier: HidModifiers.leftShift);
      case ']':
        return const HidKeyStroke(keyCode: keyRightBrace, modifier: HidModifiers.none);
      case '}':
        return const HidKeyStroke(keyCode: keyRightBrace, modifier: HidModifiers.leftShift);
      case '\\':
        return const HidKeyStroke(keyCode: keyBackslash, modifier: HidModifiers.none);
      case '|':
        return const HidKeyStroke(keyCode: keyBackslash, modifier: HidModifiers.leftShift);
      case ';':
        return const HidKeyStroke(keyCode: keySemicolon, modifier: HidModifiers.none);
      case ':':
        return const HidKeyStroke(keyCode: keySemicolon, modifier: HidModifiers.leftShift);
      case '\'':
        return const HidKeyStroke(keyCode: keyApostrophe, modifier: HidModifiers.none);
      case '"':
        return const HidKeyStroke(keyCode: keyApostrophe, modifier: HidModifiers.leftShift);
      case '`':
        return const HidKeyStroke(keyCode: keyGrave, modifier: HidModifiers.none);
      case '~':
        return const HidKeyStroke(keyCode: keyGrave, modifier: HidModifiers.leftShift);
      case ',':
        return const HidKeyStroke(keyCode: keyComma, modifier: HidModifiers.none);
      case '<':
        return const HidKeyStroke(keyCode: keyComma, modifier: HidModifiers.leftShift);
      case '.':
        return const HidKeyStroke(keyCode: keyDot, modifier: HidModifiers.none);
      case '>':
        return const HidKeyStroke(keyCode: keyDot, modifier: HidModifiers.leftShift);
      case '/':
        return const HidKeyStroke(keyCode: keySlash, modifier: HidModifiers.none);
      case '?':
        return const HidKeyStroke(keyCode: keySlash, modifier: HidModifiers.leftShift);
      case '!':
        return const HidKeyStroke(keyCode: key1, modifier: HidModifiers.leftShift);
      case '@':
        return const HidKeyStroke(keyCode: key2, modifier: HidModifiers.leftShift);
      case '#':
        return const HidKeyStroke(keyCode: key3, modifier: HidModifiers.leftShift);
      case '\$':
        return const HidKeyStroke(keyCode: key4, modifier: HidModifiers.leftShift);
      case '%':
        return const HidKeyStroke(keyCode: key5, modifier: HidModifiers.leftShift);
      case '^':
        return const HidKeyStroke(keyCode: key6, modifier: HidModifiers.leftShift);
      case '&':
        return const HidKeyStroke(keyCode: key7, modifier: HidModifiers.leftShift);
      case '*':
        return const HidKeyStroke(keyCode: key8, modifier: HidModifiers.leftShift);
      case '(':
        return const HidKeyStroke(keyCode: key9, modifier: HidModifiers.leftShift);
      case ')':
        return const HidKeyStroke(keyCode: key0, modifier: HidModifiers.leftShift);
      default:
        return null;
    }
  }
}

class HidKeyStroke {
  final int keyCode;
  final int modifier;

  const HidKeyStroke({
    required this.keyCode,
    required this.modifier,
  });
}
