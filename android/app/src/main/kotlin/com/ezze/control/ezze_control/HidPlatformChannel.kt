package com.ezze.control.ezze_control

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter Platform Channel bridging Dart calls to native Bluetooth HID Manager.
 */
class HidPlatformChannel(
    private val context: Context,
    private val hidManager: BluetoothHidManager,
    private val activityCallbacks: ActivityCallbacks
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    interface ActivityCallbacks {
        fun requestPermissions(callback: (Boolean) -> Unit)
        fun startSpeechRecognition(callback: (String?) -> Unit)
        fun makeDiscoverable(durationSeconds: Int, callback: (Boolean) -> Unit)
    }

    companion object {
        private const val METHOD_CHANNEL = "com.ezze.control/hid"
        private const val EVENT_CHANNEL = "com.ezze.control/events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    fun register(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).apply {
            setMethodCallHandler(this@HidPlatformChannel)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).apply {
            setStreamHandler(this@HidPlatformChannel)
        }

        hidManager.onEventCallback = { payload ->
            eventSink?.success(payload)
        }
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        hidManager.onEventCallback = null
        methodChannel = null
        eventChannel = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> {
                result.success(hidManager.getCapabilities())
            }

            "initProfile" -> {
                val ok = hidManager.initProfile()
                result.success(ok)
            }

            "registerApp" -> {
                val ok = hidManager.registerHid()
                result.success(ok)
            }

            "unregisterApp" -> {
                val ok = hidManager.unregisterHid()
                result.success(ok)
            }

            "getPairedDevices" -> {
                val devices = hidManager.getPairedDevices()
                result.success(devices)
            }

            "startDiscovery" -> {
                val ok = hidManager.startDiscovery()
                result.success(ok)
            }

            "stopDiscovery" -> {
                val ok = hidManager.stopDiscovery()
                result.success(ok)
            }

            "getDiscoveredDevices" -> {
                val devices = hidManager.getDiscoveredDevices()
                result.success(devices)
            }

            "connect" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrEmpty()) {
                    result.error("INVALID_ARG", "Device address cannot be empty.", null)
                } else {
                    val ok = hidManager.connectToDevice(address)
                    result.success(ok)
                }
            }

            "disconnect" -> {
                val ok = hidManager.disconnect()
                result.success(ok)
            }

            "unpair" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrEmpty()) {
                    result.error("INVALID_ARG", "Device address cannot be empty.", null)
                } else {
                    val ok = hidManager.unpairDevice(address)
                    result.success(ok)
                }
            }

            "pair" -> {
                val address = call.argument<String>("address")
                if (address.isNullOrEmpty()) {
                    result.error("INVALID_ARG", "Device address cannot be empty.", null)
                } else {
                    val ok = hidManager.pairDevice(address)
                    result.success(ok)
                }
            }

            "openBluetoothSettings" -> {
                try {
                    val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("INTENT_ERROR", "Could not open Bluetooth settings: ${e.message}", null)
                }
            }

            "sendMouseMovement" -> {
                val dx = call.argument<Int>("dx") ?: 0
                val dy = call.argument<Int>("dy") ?: 0
                val buttons = (call.argument<Int>("buttons") ?: 0).toByte()
                val wheel = call.argument<Int>("wheel") ?: 0
                val ok = hidManager.sendMouseMovement(buttons, dx, dy, wheel)
                result.success(ok)
            }

            "sendMouseClick" -> {
                val buttonStr = call.argument<String>("button") ?: "left"
                val isDouble = call.argument<Boolean>("isDouble") ?: false
                val mask: Byte = when (buttonStr.lowercase()) {
                    "right" -> HidReportEncoder.MOUSE_BUTTON_RIGHT
                    "middle" -> HidReportEncoder.MOUSE_BUTTON_MIDDLE
                    else -> HidReportEncoder.MOUSE_BUTTON_LEFT
                }
                val ok = hidManager.sendMouseClick(mask, isDouble)
                result.success(ok)
            }

            "sendMouseDown" -> {
                val buttons = (call.argument<Int>("buttons") ?: HidReportEncoder.MOUSE_BUTTON_LEFT.toInt()).toByte()
                val ok = hidManager.sendMouseMovement(buttons, 0, 0, 0)
                result.success(ok)
            }

            "sendMouseUp" -> {
                val ok = hidManager.sendMouseMovement(0, 0, 0, 0)
                result.success(ok)
            }

            "sendKey" -> {
                val keyCode = (call.argument<Int>("keyCode") ?: 0).toByte()
                val modifier = (call.argument<Int>("modifier") ?: 0).toByte()
                val ok = hidManager.sendKey(keyCode, modifier)
                result.success(ok)
            }

            "sendText" -> {
                val text = call.argument<String>("text") ?: ""
                val ok = hidManager.sendText(text)
                result.success(ok)
            }

            "releaseAll" -> {
                val ok = hidManager.releaseAllInputs()
                result.success(ok)
            }

            "requestSpeechInput" -> {
                activityCallbacks.startSpeechRecognition { recognizedText ->
                    result.success(recognizedText)
                }
            }

            "makeDiscoverable" -> {
                val duration = call.argument<Int>("duration") ?: 300
                activityCallbacks.makeDiscoverable(duration) { success ->
                    result.success(success)
                }
            }

            "checkPermissions" -> {
                val missing = hidManager.getMissingPermissions()
                result.success(missing)
            }

            "requestPermissions" -> {
                activityCallbacks.requestPermissions { granted ->
                    result.success(granted)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        this.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        this.eventSink = null
    }
}
