package com.ezze.control.ezze_control

import kotlin.math.max
import kotlin.math.min

/**
 * Encodes mouse and keyboard reports adhering to the format defined in HidReportDescriptor.
 */
object HidReportEncoder {

    const val MOUSE_BUTTON_NONE: Byte = 0x00
    const val MOUSE_BUTTON_LEFT: Byte = 0x01
    const val MOUSE_BUTTON_RIGHT: Byte = 0x02
    const val MOUSE_BUTTON_MIDDLE: Byte = 0x04

    const val MODIFIER_NONE: Byte = 0x00
    const val MODIFIER_LEFT_CTRL: Byte = 0x01
    const val MODIFIER_LEFT_SHIFT: Byte = 0x02
    const val MODIFIER_LEFT_ALT: Byte = 0x04
    const val MODIFIER_LEFT_GUI: Byte = 0x08
    const val MODIFIER_RIGHT_CTRL: Byte = 0x10
    const val MODIFIER_RIGHT_SHIFT: Byte = 0x20
    const val MODIFIER_RIGHT_ALT: Byte = 0x40
    const val MODIFIER_RIGHT_GUI: Byte = 0x80.toByte()

    // Common standard HID Usage Codes (USB-IF)
    const val KEY_A: Byte = 0x04
    const val KEY_SPACE: Byte = 0x2C
    const val KEY_ENTER: Byte = 0x28
    const val KEY_BACKSPACE: Byte = 0x2A
    const val KEY_ESCAPE: Byte = 0x29
    const val KEY_TAB: Byte = 0x2B

    /**
     * Mouse report format (4 bytes):
     * [0] Buttons bitmask (bit 0=Left, 1=Right, 2=Middle, 3=Back, 4=Forward, 5..7=0)
     * [1] Relative X movement (-127..127)
     * [2] Relative Y movement (-127..127)
     * [3] Vertical scroll wheel (-127..127)
     */
    fun encodeMouse(buttons: Byte, dx: Int, dy: Int, wheel: Int = 0): ByteArray {
        val clampedX = clampToByte(dx)
        val clampedY = clampToByte(dy)
        val clampedWheel = clampToByte(wheel)

        return byteArrayOf(
            buttons,
            clampedX,
            clampedY,
            clampedWheel
        )
    }

    fun clampToByte(value: Int): Byte {
        val clamped = max(-127, min(127, value))
        return clamped.toByte()
    }

    /**
     * Empty mouse report releasing all buttons and zero movement.
     */
    fun emptyMouse(): ByteArray = ByteArray(4)

    /**
     * Standard keyboard report format (8 bytes):
     * [0] Modifier keys bitmask
     * [1] Reserved (always 0x00)
     * [2..7] Key codes array (up to 6 simultaneously active keys)
     */
    fun encodeKeyboard(modifiers: Byte, keyCodes: ByteArray?): ByteArray {
        val report = ByteArray(8)
        report[0] = modifiers
        report[1] = 0x00 // Reserved

        if (keyCodes != null) {
            val count = min(keyCodes.size, 6)
            for (i in 0 until count) {
                report[2 + i] = keyCodes[i]
            }
        }

        return report
    }

    /**
     * Empty keyboard report releasing all modifiers and keys.
     */
    fun emptyKeyboard(): ByteArray = ByteArray(8)
}
