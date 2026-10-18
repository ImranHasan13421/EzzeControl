package com.ezze.control.ezze_control

/**
 * Standard HID Report Descriptor combining Mouse (Report ID 1) and Keyboard (Report ID 2).
 * Conforms to standard USB-IF HID specifications for host compatibility (Windows 10/11).
 */
object HidReportDescriptor {

    const val REPORT_ID_MOUSE: Byte = 1
    const val REPORT_ID_KEYBOARD: Byte = 2

    val DESCRIPTOR: ByteArray = byteArrayOf(
        // ==========================================
        // Mouse Descriptor (Report ID 1)
        // ==========================================
        0x05.toByte(), 0x01.toByte(), // Usage Page (Generic Desktop Ctrls)
        0x09.toByte(), 0x02.toByte(), // Usage (Mouse)
        0xA1.toByte(), 0x01.toByte(), // Collection (Application)
        0x85.toByte(), REPORT_ID_MOUSE, //   Report ID (1)
        0x09.toByte(), 0x01.toByte(), //   Usage (Pointer)
        0xA1.toByte(), 0x00.toByte(), //   Collection (Physical)
        // Buttons (Left, Right, Middle, Back, Forward)
        0x05.toByte(), 0x09.toByte(), //     Usage Page (Button)
        0x19.toByte(), 0x01.toByte(), //     Usage Minimum (Button 1)
        0x29.toByte(), 0x05.toByte(), //     Usage Maximum (Button 5)
        0x15.toByte(), 0x00.toByte(), //     Logical Minimum (0)
        0x25.toByte(), 0x01.toByte(), //     Logical Maximum (1)
        0x95.toByte(), 0x05.toByte(), //     Report Count (5)
        0x75.toByte(), 0x01.toByte(), //     Report Size (1)
        0x81.toByte(), 0x02.toByte(), //     Input (Data,Var,Abs)
        // 3 padding bits to complete the button byte
        0x95.toByte(), 0x01.toByte(), //     Report Count (1)
        0x75.toByte(), 0x03.toByte(), //     Report Size (3)
        0x81.toByte(), 0x01.toByte(), //     Input (Const,Array,Abs)
        // X and Y relative movement
        0x05.toByte(), 0x01.toByte(), //     Usage Page (Generic Desktop Ctrls)
        0x09.toByte(), 0x30.toByte(), //     Usage (X)
        0x09.toByte(), 0x31.toByte(), //     Usage (Y)
        0x15.toByte(), 0x81.toByte(), //     Logical Minimum (-127)
        0x25.toByte(), 0x7F.toByte(), //     Logical Maximum (127)
        0x75.toByte(), 0x08.toByte(), //     Report Size (8)
        0x95.toByte(), 0x02.toByte(), //     Report Count (2)
        0x81.toByte(), 0x06.toByte(), //     Input (Data,Var,Rel)
        // Vertical Wheel
        0x09.toByte(), 0x38.toByte(), //     Usage (Wheel)
        0x15.toByte(), 0x81.toByte(), //     Logical Minimum (-127)
        0x25.toByte(), 0x7F.toByte(), //     Logical Maximum (127)
        0x75.toByte(), 0x08.toByte(), //     Report Size (8)
        0x95.toByte(), 0x01.toByte(), //     Report Count (1)
        0x81.toByte(), 0x06.toByte(), //     Input (Data,Var,Rel)
        0xC0.toByte(),                //   End Collection (Physical)
        0xC0.toByte(),                // End Collection (Application)

        // ==========================================
        // Keyboard Descriptor (Report ID 2)
        // ==========================================
        0x05.toByte(), 0x01.toByte(), // Usage Page (Generic Desktop Ctrls)
        0x09.toByte(), 0x06.toByte(), // Usage (Keyboard)
        0xA1.toByte(), 0x01.toByte(), // Collection (Application)
        0x85.toByte(), REPORT_ID_KEYBOARD, // Report ID (2)
        // Modifiers (Left Ctrl, Shift, Alt, GUI, Right Ctrl, Shift, Alt, GUI)
        0x05.toByte(), 0x07.toByte(), //   Usage Page (Kbrd/Keypad)
        0x19.toByte(), 0xE0.toByte(), //   Usage Minimum (0xE0)
        0x29.toByte(), 0xE7.toByte(), //   Usage Maximum (0xE7)
        0x15.toByte(), 0x00.toByte(), //   Logical Minimum (0)
        0x25.toByte(), 0x01.toByte(), //   Logical Maximum (1)
        0x75.toByte(), 0x01.toByte(), //   Report Size (1)
        0x95.toByte(), 0x08.toByte(), //   Report Count (8)
        0x81.toByte(), 0x02.toByte(), //   Input (Data,Var,Abs)
        // Reserved byte
        0x95.toByte(), 0x01.toByte(), //   Report Count (1)
        0x75.toByte(), 0x08.toByte(), //   Report Size (8)
        0x81.toByte(), 0x01.toByte(), //   Input (Const,Array,Abs)
        // 5 LEDs output report
        0x95.toByte(), 0x05.toByte(), //   Report Count (5)
        0x75.toByte(), 0x01.toByte(), //   Report Size (1)
        0x05.toByte(), 0x08.toByte(), //   Usage Page (LEDs)
        0x19.toByte(), 0x01.toByte(), //   Usage Minimum (Num Lock)
        0x29.toByte(), 0x05.toByte(), //   Usage Maximum (Kana)
        0x91.toByte(), 0x02.toByte(), //   Output (Data,Var,Abs)
        // 3 bits LED padding
        0x95.toByte(), 0x01.toByte(), //   Report Count (1)
        0x75.toByte(), 0x03.toByte(), //   Report Size (3)
        0x91.toByte(), 0x01.toByte(), //   Output (Const,Array,Abs)
        // Key codes array (6 keys rollover)
        0x95.toByte(), 0x06.toByte(), //   Report Count (6)
        0x75.toByte(), 0x08.toByte(), //   Report Size (8)
        0x15.toByte(), 0x00.toByte(), //   Logical Minimum (0)
        0x25.toByte(), 0x65.toByte(), //   Logical Maximum (101)
        0x05.toByte(), 0x07.toByte(), //   Usage Page (Kbrd/Keypad)
        0x19.toByte(), 0x00.toByte(), //   Usage Minimum (0)
        0x29.toByte(), 0x65.toByte(), //   Usage Maximum (101)
        0x81.toByte(), 0x00.toByte(), //   Input (Data,Array,Abs)
        0xC0.toByte()                 // End Collection
    )
}
