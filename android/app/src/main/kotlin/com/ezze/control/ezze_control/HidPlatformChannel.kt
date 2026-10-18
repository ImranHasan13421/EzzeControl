package com.ezze.control.ezze_control

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles communication between Flutter and native Android BluetoothHidManager.
 */
class HidPlatformChannel(
    private val activity: Activity,
    private val hidManager: BluetoothHidManager
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL_NAME = "com.ezze.control/hid"
        const val EVENT_CHANNEL_NAME = "com.ezze.control/events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    var onRequestPermissionsHandler: ((onResult: (Boolean) -> Unit) -> Unit)? = null

    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME)
        eventChannel?.setStreamHandler(this)

        hidManager.onEventCallback = { event ->
            activity.runOnUiThread {
                eventSink?.success(event)
            }
        }
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
        eventSink = null
        hidManager.onEventCallback = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> {
                result.success(hidManager.getCapabilities())
            }
            "requestPermissions" -> {
                onRequestPermissionsHandler?.invoke { granted ->
                    result.success(granted)
                } ?: run {
                    result.success(hidManager.hasRequiredPermissions())
                }
            }
            "requestHidRegistration" -> {
                val success = hidManager.requestHidRegistration()
                result.success(success)
            }
            "unregisterHid" -> {
                val success = hidManager.unregisterHid()
                result.success(success)
            }
            "getStatus" -> {
                result.success(hidManager.getCapabilities())
            }
            "getBondedDevices" -> {
                result.success(hidManager.getBondedDevices())
            }
            "connectHost" -> {
                val address = call.argument<String>("address")
                if (address != null) {
                    val success = hidManager.connectHost(address)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "Host address cannot be null", null)
                }
            }
            "unpairHost" -> {
                val address = call.argument<String>("address")
                if (address != null) {
                    val success = hidManager.unpairHost(address)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "Host address cannot be null", null)
                }
            }
            "makeDiscoverable" -> {
                hidManager.makeDiscoverable()
                result.success(true)
            }
            "openBluetoothSettings" -> {
                hidManager.openBluetoothSettings()
                result.success(true)
            }
            "sendTestMouseMovement" -> {
                val success = hidManager.sendTestMouseMovement()
                result.success(success)
            }
            "sendTestKey" -> {
                val success = hidManager.sendTestKey()
                result.success(success)
            }
            "sendMouseMovement" -> {
                val buttons = (call.argument<Int>("buttons") ?: 0).toByte()
                val dx = call.argument<Int>("dx") ?: 0
                val dy = call.argument<Int>("dy") ?: 0
                val wheel = call.argument<Int>("wheel") ?: 0
                val success = hidManager.sendMouseMovement(buttons, dx, dy, wheel)
                result.success(success)
            }
            "sendMouseReport" -> {
                val data = call.argument<ByteArray>("data")
                if (data != null) {
                    val success = hidManager.sendReport(HidReportDescriptor.REPORT_ID_MOUSE, data)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "Mouse report data was null", null)
                }
            }
            "sendKeyboardReport" -> {
                val data = call.argument<ByteArray>("data")
                if (data != null) {
                    val success = hidManager.sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, data)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "Keyboard report data was null", null)
                }
            }
            "releaseAllInputs" -> {
                val success = hidManager.releaseAllInputs()
                result.success(success)
            }
            "disconnect" -> {
                val success = hidManager.disconnect()
                result.success(success)
            }
            "setKeepScreenOn" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                activity.runOnUiThread {
                    if (enabled) {
                        activity.window.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        activity.window.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                }
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val initialStatus = mutableMapOf<String, Any?>(
            "type" to "initial_state",
            "message" to "Stream subscribed.",
            "timestamp" to System.currentTimeMillis()
        )
        initialStatus.putAll(hidManager.getCapabilities())
        eventSink?.success(initialStatus)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
