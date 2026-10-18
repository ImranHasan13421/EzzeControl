package com.ezze.control.ezze_control

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppQosSettings
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.concurrent.Executors

/**
 * Native manager for Android Bluetooth HID Device profile (API 28+).
 * Handles profile acquisition, SDP registration, discovery, pairing/unpairing,
 * report sending, and input lifecycle management.
 */
@SuppressLint("MissingPermission")
class BluetoothHidManager(private val context: Context) {

    companion object {
        private const val TAG = "BluetoothHidManager"
        const val SUBCLASS_COMBO: Byte = 0xC0.toByte() // 0x80 Mouse | 0x40 Keyboard
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    private val bluetoothManager: BluetoothManager? =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    val bluetoothAdapter: BluetoothAdapter? =
        bluetoothManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()

    var hidProxy: BluetoothHidDevice? = null
    var connectedDevice: BluetoothDevice? = null

    // State tracking
    var isProfileRequestPending = false
    var isProfileAvailable = false
    var isRegistered = false
    var isRegistering = false
    var isDiscovering = false
    var connectionState = BluetoothProfile.STATE_DISCONNECTED
    var lastError: String? = null

    // Discovered devices collection (address -> Map)
    private val discoveredDevices = mutableMapOf<String, Map<String, Any?>>()
    private var discoveryReceiver: BroadcastReceiver? = null

    // Listener callback for Flutter channel events
    var onEventCallback: ((event: Map<String, Any?>) -> Unit)? = null

    // Profile service listener
    private val profileServiceListener = object : BluetoothProfile.ServiceListener {
        override fun onServiceConnected(profile: Int, proxy: BluetoothProfile) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.i(TAG, "Bluetooth HID Device profile proxy connected.")
                hidProxy = proxy as BluetoothHidDevice
                isProfileAvailable = true
                isProfileRequestPending = false
                lastError = null

                checkConnectedDevicesInternal()

                notifyEvent(
                    "profile_connected",
                    "Bluetooth HID profile proxy acquired successfully."
                )

                if (isRegistering) {
                    executeRegistration()
                }
            }
        }

        override fun onServiceDisconnected(profile: Int) {
            if (profile == BluetoothProfile.HID_DEVICE) {
                Log.w(TAG, "Bluetooth HID Device profile proxy disconnected.")
                hidProxy = null
                isProfileAvailable = false
                isProfileRequestPending = false
                isRegistered = false
                isRegistering = false
                connectionState = BluetoothProfile.STATE_DISCONNECTED
                connectedDevice = null

                notifyEvent(
                    "profile_disconnected",
                    "Bluetooth HID profile proxy disconnected by system."
                )
            }
        }
    }

    // HID Device callbacks from Android OS
    private val hidCallback = object : BluetoothHidDevice.Callback() {
        override fun onAppStatusChanged(pluggedDevice: BluetoothDevice?, registered: Boolean) {
            super.onAppStatusChanged(pluggedDevice, registered)
            Log.i(TAG, "onAppStatusChanged: registered=$registered, pluggedDevice=${pluggedDevice?.address}")
            isRegistered = registered
            isRegistering = false

            if (registered) {
                lastError = null
                if (pluggedDevice != null) {
                    checkDeviceConnectionState(pluggedDevice)
                } else {
                    checkConnectedDevicesInternal()
                }

                notifyEvent(
                    "registration_success",
                    "HID Application successfully registered with Android Bluetooth stack."
                )
            } else {
                lastError = "HID application registration was rejected or revoked by Android."
                notifyEvent(
                    "registration_failed",
                    lastError ?: "Registration failed."
                )
            }
        }

        override fun onConnectionStateChanged(device: BluetoothDevice?, state: Int) {
            super.onConnectionStateChanged(device, state)
            Log.i(TAG, "onConnectionStateChanged: device=${device?.address}, state=$state (${connectionStateToString(state)})")
            connectionState = state

            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevice = device
                    lastError = null
                    notifyEvent("device_connected", "Connected to host: ${safeGetDeviceName(device)}")
                }
                BluetoothProfile.STATE_CONNECTING -> {
                    connectedDevice = device
                    notifyEvent("device_connecting", "Connecting to host: ${safeGetDeviceName(device)}...")
                }
                BluetoothProfile.STATE_DISCONNECTING -> {
                    notifyEvent("device_disconnecting", "Disconnecting from host...")
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    releaseAllInputs()
                    if (connectedDevice?.address == device?.address) {
                        connectedDevice = null
                    }
                    notifyEvent("device_disconnected", "Disconnected from host.")
                }
            }
        }
    }

    /**
     * Initializes the HID Device profile proxy.
     */
    fun initProfile(): Boolean {
        val adapter = bluetoothAdapter ?: run {
            lastError = "Bluetooth is not supported on this device."
            return false
        }

        if (!adapter.isEnabled) {
            lastError = "Bluetooth is turned off."
            return false
        }

        if (hidProxy != null) {
            isProfileAvailable = true
            return true
        }

        if (isProfileRequestPending) {
            return true
        }

        return try {
            isProfileRequestPending = true
            adapter.getProfileProxy(context, profileServiceListener, BluetoothProfile.HID_DEVICE)
        } catch (se: SecurityException) {
            isProfileRequestPending = false
            lastError = "SecurityException while requesting HID profile proxy: ${se.message}"
            notifyEvent("error", lastError!!)
            false
        } catch (e: Exception) {
            isProfileRequestPending = false
            lastError = "Exception while requesting HID profile proxy: ${e.message}"
            notifyEvent("error", lastError!!)
            false
        }
    }

    /**
     * Registers the application as a Bluetooth HID composite device (Mouse + Keyboard).
     */
    fun registerHid(): Boolean {
        if (isRegistered) {
            return true
        }

        isRegistering = true
        if (hidProxy == null) {
            return initProfile()
        }

        return executeRegistration()
    }

    private fun executeRegistration(): Boolean {
        val proxy = hidProxy ?: return false

        val sdp = BluetoothHidDeviceAppSdpSettings(
            "Ezze Control",
            "Bluetooth Mouse and Keyboard",
            "Ezze",
            SUBCLASS_COMBO,
            HidReportDescriptor.DESCRIPTOR
        )

        val qos = BluetoothHidDeviceAppQosSettings(
            BluetoothHidDeviceAppQosSettings.SERVICE_BEST_EFFORT,
            800,
            9,
            0,
            11250,
            BluetoothHidDeviceAppQosSettings.MAX
        )

        return try {
            proxy.registerApp(sdp, null, qos, executor, hidCallback)
        } catch (se: SecurityException) {
            isRegistering = false
            lastError = "SecurityException during registerApp: ${se.message}"
            notifyEvent("error", lastError!!)
            false
        } catch (e: Exception) {
            isRegistering = false
            lastError = "Exception during registerApp: ${e.message}"
            notifyEvent("error", lastError!!)
            false
        }
    }

    /**
     * Unregisters the HID application.
     */
    fun unregisterHid(): Boolean {
        val proxy = hidProxy ?: return true
        return try {
            releaseAllInputs()
            val result = proxy.unregisterApp()
            isRegistered = false
            isRegistering = false
            notifyEvent("unregistered", "HID application unregistered.")
            result
        } catch (e: Exception) {
            lastError = "Error unregistering HID: ${e.message}"
            notifyEvent("error", lastError!!)
            false
        }
    }

    /**
     * Connects HID profile to target Bluetooth device.
     */
    fun connectToDevice(address: String): Boolean {
        val adapter = bluetoothAdapter ?: return false
        val proxy = hidProxy ?: run {
            lastError = "HID profile is not ready."
            return false
        }

        val device = try {
            adapter.getRemoteDevice(address)
        } catch (e: Exception) {
            lastError = "Invalid device address: $address"
            return false
        }

        return try {
            registerHid()
            connectedDevice = device
            connectionState = BluetoothProfile.STATE_CONNECTING
            notifyEvent("device_connecting", "Connecting to ${safeGetDeviceName(device)}...")
            proxy.connect(device)
        } catch (e: Exception) {
            lastError = "Error connecting to device: ${e.message}"
            notifyEvent("error", lastError!!)
            false
        }
    }

    /**
     * Disconnects from current host.
     */
    fun disconnect(): Boolean {
        val proxy = hidProxy ?: return true
        val device = connectedDevice ?: return true
        return try {
            releaseAllInputs()
            val result = proxy.disconnect(device)
            notifyEvent("disconnecting", "Disconnect request sent to host.")
            result
        } catch (e: Exception) {
            Log.e(TAG, "disconnect error: ${e.message}")
            false
        }
    }

    /**
     * Unpairs a Bluetooth device by removing its bond.
     */
    fun unpairDevice(address: String): Boolean {
        val adapter = bluetoothAdapter ?: return false
        return try {
            val device = adapter.getRemoteDevice(address)
            if (connectedDevice?.address == address) {
                disconnect()
            }
            // Use reflection to call hidden removeBond() API
            val method = device.javaClass.getMethod("removeBond")
            val result = method.invoke(device) as? Boolean ?: false
            if (result) {
                notifyEvent("device_unpaired", "Device $address unpaired successfully.")
            }
            result
        } catch (e: Exception) {
            Log.e(TAG, "unpairDevice error: ${e.message}")
            false
        }
    }

    /**
     * Returns a list of bonded (paired) devices formatted for Flutter.
     */
    fun getPairedDevices(): List<Map<String, Any?>> {
        val adapter = bluetoothAdapter ?: return emptyList()
        val devices = mutableListOf<Map<String, Any?>>()
        try {
            val bonded = adapter.bondedDevices ?: return emptyList()
            for (dev in bonded) {
                val isConnected = (connectedDevice?.address == dev.address &&
                        connectionState == BluetoothProfile.STATE_CONNECTED)
                devices.add(
                    mapOf(
                        "name" to (dev.name ?: "Unknown Device"),
                        "address" to dev.address,
                        "type" to dev.type,
                        "deviceClass" to (dev.bluetoothClass?.deviceClass ?: 0),
                        "majorDeviceClass" to (dev.bluetoothClass?.majorDeviceClass ?: 0),
                        "isConnected" to isConnected
                    )
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "getPairedDevices error: ${e.message}")
        }
        return devices
    }

    /**
     * Starts Bluetooth discovery for nearby available devices.
     */
    fun startDiscovery(): Boolean {
        val adapter = bluetoothAdapter ?: return false
        if (isDiscovering) return true

        discoveredDevices.clear()

        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }

        discoveryReceiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                when (intent?.action) {
                    BluetoothDevice.ACTION_FOUND -> {
                        val device = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                        }
                        if (device != null && device.address != null) {
                            val name = device.name ?: "Unknown Device"
                            val info = mapOf(
                                "name" to name,
                                "address" to device.address,
                                "type" to device.type,
                                "deviceClass" to (device.bluetoothClass?.deviceClass ?: 0),
                                "majorDeviceClass" to (device.bluetoothClass?.majorDeviceClass ?: 0),
                                "isBonded" to (device.bondState == BluetoothDevice.BOND_BONDED)
                            )
                            discoveredDevices[device.address] = info
                            notifyEvent("device_found", "Found device: $name")
                        }
                    }
                    BluetoothAdapter.ACTION_DISCOVERY_FINISHED -> {
                        isDiscovering = false
                        notifyEvent("discovery_finished", "Discovery finished.")
                    }
                }
            }
        }

        try {
            context.registerReceiver(discoveryReceiver, filter)
            isDiscovering = adapter.startDiscovery()
            notifyEvent("discovery_started", "Scanning for nearby devices...")
            return isDiscovering
        } catch (e: Exception) {
            Log.e(TAG, "startDiscovery error: ${e.message}")
            return false
        }
    }

    /**
     * Stops Bluetooth discovery.
     */
    fun stopDiscovery(): Boolean {
        val adapter = bluetoothAdapter ?: return true
        isDiscovering = false
        try {
            if (discoveryReceiver != null) {
                try {
                    context.unregisterReceiver(discoveryReceiver)
                } catch (_: Exception) {}
                discoveryReceiver = null
            }
            return adapter.cancelDiscovery()
        } catch (e: Exception) {
            Log.e(TAG, "stopDiscovery error: ${e.message}")
            return false
        }
    }

    /**
     * Returns currently discovered devices list.
     */
    fun getDiscoveredDevices(): List<Map<String, Any?>> {
        return discoveredDevices.values.toList()
    }

    /**
     * Send input report with Report ID.
     */
    fun sendReport(reportId: Byte, data: ByteArray): Boolean {
        val proxy = hidProxy ?: return false
        val device = connectedDevice ?: return false
        if (connectionState != BluetoothProfile.STATE_CONNECTED) return false

        return try {
            proxy.sendReport(device, reportId.toInt(), data)
        } catch (e: Exception) {
            Log.e(TAG, "sendReport error: ${e.message}")
            false
        }
    }

    private val mouseReportBuffer = ByteArray(4)

    /**
     * Send relative mouse movement and optional button/wheel.
     */
    fun sendMouseMovement(buttons: Byte, dx: Int, dy: Int, wheel: Int = 0): Boolean {
        synchronized(mouseReportBuffer) {
            mouseReportBuffer[0] = buttons
            mouseReportBuffer[1] = HidReportEncoder.clampToByte(dx)
            mouseReportBuffer[2] = HidReportEncoder.clampToByte(dy)
            mouseReportBuffer[3] = HidReportEncoder.clampToByte(wheel)
            return sendReport(HidReportDescriptor.REPORT_ID_MOUSE, mouseReportBuffer)
        }
    }

    /**
     * Performs a single mouse click (press and release).
     */
    fun sendMouseClick(buttonMask: Byte, isDouble: Boolean = false): Boolean {
        executor.execute {
            try {
                sendMouseMovement(buttonMask, 0, 0, 0)
                Thread.sleep(40)
                sendMouseMovement(0, 0, 0, 0)

                if (isDouble) {
                    Thread.sleep(80)
                    sendMouseMovement(buttonMask, 0, 0, 0)
                    Thread.sleep(40)
                    sendMouseMovement(0, 0, 0, 0)
                }
            } catch (e: Exception) {
                Log.e(TAG, "sendMouseClick error: ${e.message}")
            }
        }
        return true
    }

    /**
     * Sends a single key press (press and release) with modifier.
     */
    fun sendKey(keyCode: Byte, modifier: Byte = HidReportEncoder.MODIFIER_NONE): Boolean {
        executor.execute {
            try {
                val keyDown = HidReportEncoder.encodeKeyboard(modifier, byteArrayOf(keyCode))
                sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, keyDown)
                Thread.sleep(30)
                val keyUp = HidReportEncoder.emptyKeyboard()
                sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, keyUp)
            } catch (e: Exception) {
                Log.e(TAG, "sendKey error: ${e.message}")
            }
        }
        return true
    }

    /**
     * Types a full string live to host by encoding each character into HID keystrokes.
     */
    fun sendText(text: String): Boolean {
        if (text.isEmpty()) return true
        executor.execute {
            try {
                for (ch in text) {
                    val stroke = HidReportEncoder.charToHid(ch)
                    if (stroke != null) {
                        val keyDown = HidReportEncoder.encodeKeyboard(stroke.modifier, byteArrayOf(stroke.keyCode))
                        sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, keyDown)
                        Thread.sleep(20)
                        sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, HidReportEncoder.emptyKeyboard())
                        Thread.sleep(15)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "sendText error: ${e.message}")
            }
        }
        return true
    }

    /**
     * Release all active mouse buttons and keyboard keys.
     */
    fun releaseAllInputs(): Boolean {
        var success = true
        try {
            sendReport(HidReportDescriptor.REPORT_ID_MOUSE, HidReportEncoder.emptyMouse())
            sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, HidReportEncoder.emptyKeyboard())
        } catch (_: Exception) {
            success = false
        }
        return success
    }

    /**
     * Check if required permissions are granted.
     */
    fun hasRequiredPermissions(): Boolean {
        return getMissingPermissions().isEmpty()
    }

    /**
     * List missing permissions based on running SDK.
     */
    fun getMissingPermissions(): List<String> {
        val missing = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // API 31+
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT)
                != PackageManager.PERMISSION_GRANTED) {
                missing.add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN)
                != PackageManager.PERMISSION_GRANTED) {
                missing.add(Manifest.permission.BLUETOOTH_SCAN)
            }
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADVERTISE)
                != PackageManager.PERMISSION_GRANTED) {
                missing.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            }
        }
        return missing
    }

    fun getCapabilities(): Map<String, Any?> {
        val adapter = bluetoothAdapter
        val isBtEnabled = adapter?.isEnabled ?: false
        return mapOf(
            "isBluetoothSupported" to (adapter != null),
            "isBluetoothEnabled" to isBtEnabled,
            "isHidSupported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P),
            "isProfileAvailable" to isProfileAvailable,
            "isRegistered" to isRegistered,
            "isRegistering" to isRegistering,
            "isDiscovering" to isDiscovering,
            "connectionState" to connectionStateToString(connectionState),
            "connectedDeviceAddress" to connectedDevice?.address,
            "connectedDeviceName" to safeGetDeviceName(connectedDevice),
            "hasPermissions" to hasRequiredPermissions(),
            "missingPermissions" to getMissingPermissions(),
            "lastError" to lastError
        )
    }

    private fun checkConnectedDevicesInternal() {
        val proxy = hidProxy ?: return
        try {
            val devices = proxy.connectedDevices
            if (!devices.isNullOrEmpty()) {
                connectedDevice = devices[0]
                connectionState = BluetoothProfile.STATE_CONNECTED
            }
        } catch (_: Exception) {}
    }

    private fun checkDeviceConnectionState(device: BluetoothDevice) {
        val proxy = hidProxy ?: return
        try {
            val state = proxy.getConnectionState(device)
            connectionState = state
            if (state == BluetoothProfile.STATE_CONNECTED) {
                connectedDevice = device
            }
        } catch (_: Exception) {}
    }

    private fun safeGetDeviceName(device: BluetoothDevice?): String? {
        if (device == null) return null
        return try {
            device.name ?: device.address
        } catch (_: Exception) {
            device.address
        }
    }

    private fun connectionStateToString(state: Int): String {
        return when (state) {
            BluetoothProfile.STATE_CONNECTED -> "CONNECTED"
            BluetoothProfile.STATE_CONNECTING -> "CONNECTING"
            BluetoothProfile.STATE_DISCONNECTING -> "DISCONNECTING"
            BluetoothProfile.STATE_DISCONNECTED -> "DISCONNECTED"
            else -> "UNKNOWN"
        }
    }

    private fun notifyEvent(type: String, message: String) {
        mainHandler.post {
            val payload = mutableMapOf<String, Any?>(
                "type" to type,
                "message" to message,
                "timestamp" to System.currentTimeMillis()
            )
            payload.putAll(getCapabilities())
            onEventCallback?.invoke(payload)
        }
    }

    fun cleanup() {
        try {
            stopDiscovery()
            releaseAllInputs()
            unregisterHid()
            if (hidProxy != null) {
                bluetoothAdapter?.closeProfileProxy(BluetoothProfile.HID_DEVICE, hidProxy)
                hidProxy = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "cleanup error: ${e.message}")
        }
    }
}
