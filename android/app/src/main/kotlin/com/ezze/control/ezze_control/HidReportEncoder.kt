package com.ezze.control.ezze_control

/**
 * Encodes mouse and keyboard events into standard USB HID reports.
 */
object HidReportEncoder {

    // Modifiers (Bitmask for Byte 0 of Keyboard Report)
    const val MODIFIER_NONE: Byte = 0x00
    const val MODIFIER_LEFT_CTRL: Byte = 0x01
    const val MODIFIER_LEFT_SHIFT: Byte = 0x02
    const val MODIFIER_LEFT_ALT: Byte = 0x04
    const val MODIFIER_LEFT_GUI: Byte = 0x08
    const val MODIFIER_RIGHT_CTRL: Byte = 0x10
    const val MODIFIER_RIGHT_SHIFT: Byte = 0x20
    const val MODIFIER_RIGHT_ALT: Byte = 0x40
    const val MODIFIER_RIGHT_GUI: Byte = 0x80.toByte()

    // Mouse Buttons (Bitmask for Byte 0 of Mouse Report)
    const val MOUSE_BUTTON_NONE: Byte = 0x00
    const val MOUSE_BUTTON_LEFT: Byte = 0x01
    const val MOUSE_BUTTON_RIGHT: Byte = 0x02
    const val MOUSE_BUTTON_MIDDLE: Byte = 0x04
    const val MOUSE_BUTTON_BACK: Byte = 0x08
    const val MOUSE_BUTTON_FORWARD: Byte = 0x10

    // Common HID Keycodes (USB HID Usage Tables)
    const val KEY_NONE: Byte = 0x00
    const val KEY_A: Byte = 0x04
    const val KEY_Z: Byte = 0x1D
    const val KEY_1: Byte = 0x1E
    const val KEY_0: Byte = 0x27
    const val KEY_ENTER: Byte = 0x28
    const val KEY_ESCAPE: Byte = 0x29
    const val KEY_BACKSPACE: Byte = 0x2A
    const val KEY_TAB: Byte = 0x2B
    const val KEY_SPACE: Byte = 0x2C
    const val KEY_MINUS: Byte = 0x2D
    const val KEY_EQUAL: Byte = 0x2E
    const val KEY_LEFTBRACE: Byte = 0x2F
    const val KEY_RIGHTBRACE: Byte = 0x30
    const val KEY_BACKSLASH: Byte = 0x31
    const val KEY_SEMICOLON: Byte = 0x33
    const val KEY_APOSTROPHE: Byte = 0x34
    const val KEY_GRAVE: Byte = 0x35
    const val KEY_COMMA: Byte = 0x36
    const val KEY_DOT: Byte = 0x37
    const val KEY_SLASH: Byte = 0x38
    const val KEY_CAPSLOCK: Byte = 0x39

    // Function Keys
    const val KEY_F1: Byte = 0x3A
    const val KEY_F2: Byte = 0x3B
    const val KEY_F3: Byte = 0x3C
    const val KEY_F4: Byte = 0x3D
    const val KEY_F5: Byte = 0x3E
    const val KEY_F6: Byte = 0x3F
    const val KEY_F7: Byte = 0x40
    const val KEY_F8: Byte = 0x41
    const val KEY_F9: Byte = 0x42
    const val KEY_F10: Byte = 0x43
    const val KEY_F11: Byte = 0x44
    const val KEY_F12: Byte = 0x45

    // Control & Navigation Keys
    const val KEY_PRINTSCREEN: Byte = 0x46
    const val KEY_SCROLLLOCK: Byte = 0x47
    const val KEY_PAUSE: Byte = 0x48
    const val KEY_INSERT: Byte = 0x49
    const val KEY_HOME: Byte = 0x4A
    const val KEY_PAGEUP: Byte = 0x4B
    const val KEY_DELETE: Byte = 0x4C
    const val KEY_END: Byte = 0x4D
    const val KEY_PAGEDOWN: Byte = 0x4E
    const val KEY_RIGHT: Byte = 0x4F
    const val KEY_LEFT: Byte = 0x50
    const val KEY_DOWN: Byte = 0x51
    const val KEY_UP: Byte = 0x52

    // Keypad (Desktop Numpad)
    const val KEY_NUMLOCK: Byte = 0x53
    const val KEY_KPSLASH: Byte = 0x54
    const val KEY_KPASTERISK: Byte = 0x55
    const val KEY_KPMINUS: Byte = 0x56
    const val KEY_KPPLUS: Byte = 0x57
    const val KEY_KPENTER: Byte = 0x58
    const val KEY_KP1: Byte = 0x59
    const val KEY_KP2: Byte = 0x5A
    const val KEY_KP3: Byte = 0x5B
    const val KEY_KP4: Byte = 0x5C
    const val KEY_KP5: Byte = 0x5D
    const val KEY_KP6: Byte = 0x5E
    const val KEY_KP7: Byte = 0x5F
    const val KEY_KP8: Byte = 0x60
    const val KEY_KP9: Byte = 0x61
    const val KEY_KP0: Byte = 0x62
    const val KEY_KPDOT: Byte = 0x63

    /**
     * Clamps an integer to signed 8-bit range (-127 to 127).
     */
    fun clampToByte(value: Int): Byte {
        val clamped = when {
            value > 127 -> 127
            value < -127 -> -127
            else -> value
        }
        return clamped.toByte()
    }

    /**
     * Creates an empty mouse report (all buttons released, 0 movement).
     */
    fun emptyMouse(): ByteArray {
        return byteArrayOf(0, 0, 0, 0)
    }

    /**
     * Creates an empty keyboard report (no modifiers, no keys pressed).
     */
    fun emptyKeyboard(): ByteArray {
        return ByteArray(8)
    }

    /**
     * Encodes a mouse report:
     * Byte 0: Buttons
     * Byte 1: dX (-127..127)
     * Byte 2: dY (-127..127)
     * Byte 3: Wheel (-127..127)
     */
    fun encodeMouse(buttons: Byte, dx: Int, dy: Int, wheel: Int = 0): ByteArray {
        return byteArrayOf(
            buttons,
            clampToByte(dx),
            clampToByte(dy),
            clampToByte(wheel)
        )
    }

    /**
     * Encodes a keyboard report:
     * Byte 0: Modifiers bitmask
     * Byte 1: Reserved (0x00)
     * Bytes 2..7: Up to 6 keycodes
     */
    fun encodeKeyboard(modifiers: Byte, keyCodes: ByteArray): ByteArray {
        val report = ByteArray(8)
        report[0] = modifiers
        report[1] = 0 // Reserved
        val copyLen = minOf(keyCodes.size, 6)
        for (i in 0 until copyLen) {
            report[2 + i] = keyCodes[i]
        }
        return report
    }

    /**
     * Data class representing a keycode and required modifier for an ASCII char.
     */
    data class HidKeyStroke(val keyCode: Byte, val modifier: Byte)

    /**
     * Translates a standard character into its HID keycode and modifier (e.g. Shift).
     */
    fun charToHid(ch: Char): HidKeyStroke? {
        return when (ch) {
            in 'a'..'z' -> HidKeyStroke((KEY_A + (ch - 'a')).toByte(), MODIFIER_NONE)
            in 'A'..'Z' -> HidKeyStroke((KEY_A + (ch - 'A')).toByte(), MODIFIER_LEFT_SHIFT)
            '1' -> HidKeyStroke(KEY_1, MODIFIER_NONE)
            '2' -> HidKeyStroke((KEY_1 + 1).toByte(), MODIFIER_NONE)
            '3' -> HidKeyStroke((KEY_1 + 2).toByte(), MODIFIER_NONE)
            '4' -> HidKeyStroke((KEY_1 + 3).toByte(), MODIFIER_NONE)
            '5' -> HidKeyStroke((KEY_1 + 4).toByte(), MODIFIER_NONE)
            '6' -> HidKeyStroke((KEY_1 + 5).toByte(), MODIFIER_NONE)
            '7' -> HidKeyStroke((KEY_1 + 6).toByte(), MODIFIER_NONE)
            '8' -> HidKeyStroke((KEY_1 + 7).toByte(), MODIFIER_NONE)
            '9' -> HidKeyStroke((KEY_1 + 8).toByte(), MODIFIER_NONE)
            '0' -> HidKeyStroke(KEY_0, MODIFIER_NONE)

            '!' -> HidKeyStroke(KEY_1, MODIFIER_LEFT_SHIFT)
            '@' -> HidKeyStroke((KEY_1 + 1).toByte(), MODIFIER_LEFT_SHIFT)
            '#' -> HidKeyStroke((KEY_1 + 2).toByte(), MODIFIER_LEFT_SHIFT)
            '$' -> HidKeyStroke((KEY_1 + 3).toByte(), MODIFIER_LEFT_SHIFT)
            '%' -> HidKeyStroke((KEY_1 + 4).toByte(), MODIFIER_LEFT_SHIFT)
            '^' -> HidKeyStroke((KEY_1 + 5).toByte(), MODIFIER_LEFT_SHIFT)
            '&' -> HidKeyStroke((KEY_1 + 6).toByte(), MODIFIER_LEFT_SHIFT)
            '*' -> HidKeyStroke((KEY_1 + 7).toByte(), MODIFIER_LEFT_SHIFT)
            '(' -> HidKeyStroke((KEY_1 + 8).toByte(), MODIFIER_LEFT_SHIFT)
            ')' -> HidKeyStroke(KEY_0, MODIFIER_LEFT_SHIFT)

            ' ' -> HidKeyStroke(KEY_SPACE, MODIFIER_NONE)
            '\n', '\r' -> HidKeyStroke(KEY_ENTER, MODIFIER_NONE)
            '\t' -> HidKeyStroke(KEY_TAB, MODIFIER_NONE)
            '\b' -> HidKeyStroke(KEY_BACKSPACE, MODIFIER_NONE)

            '-' -> HidKeyStroke(KEY_MINUS, MODIFIER_NONE)
            '_' -> HidKeyStroke(KEY_MINUS, MODIFIER_LEFT_SHIFT)
            '=' -> HidKeyStroke(KEY_EQUAL, MODIFIER_NONE)
            '+' -> HidKeyStroke(KEY_EQUAL, MODIFIER_LEFT_SHIFT)
            '[' -> HidKeyStroke(KEY_LEFTBRACE, MODIFIER_NONE)
            '{' -> HidKeyStroke(KEY_LEFTBRACE, MODIFIER_LEFT_SHIFT)
            ']' -> HidKeyStroke(KEY_RIGHTBRACE, MODIFIER_NONE)
            '}' -> HidKeyStroke(KEY_RIGHTBRACE, MODIFIER_LEFT_SHIFT)
            '\\' -> HidKeyStroke(KEY_BACKSLASH, MODIFIER_NONE)
            '|' -> HidKeyStroke(KEY_BACKSLASH, MODIFIER_LEFT_SHIFT)
            ';' -> HidKeyStroke(KEY_SEMICOLON, MODIFIER_NONE)
            ':' -> HidKeyStroke(KEY_SEMICOLON, MODIFIER_LEFT_SHIFT)
            '\'' -> HidKeyStroke(KEY_APOSTROPHE, MODIFIER_NONE)
            '"' -> HidKeyStroke(KEY_APOSTROPHE, MODIFIER_LEFT_SHIFT)
            '`' -> HidKeyStroke(KEY_GRAVE, MODIFIER_NONE)
            '~' -> HidKeyStroke(KEY_GRAVE, MODIFIER_LEFT_SHIFT)
            ',' -> HidKeyStroke(KEY_COMMA, MODIFIER_NONE)
            '<' -> HidKeyStroke(KEY_COMMA, MODIFIER_LEFT_SHIFT)
            '.' -> HidKeyStroke(KEY_DOT, MODIFIER_NONE)
            '>' -> HidKeyStroke(KEY_DOT, MODIFIER_LEFT_SHIFT)
            '/' -> HidKeyStroke(KEY_SLASH, MODIFIER_NONE)
            '?' -> HidKeyStroke(KEY_SLASH, MODIFIER_LEFT_SHIFT)

            else -> null
        }
    }
}
