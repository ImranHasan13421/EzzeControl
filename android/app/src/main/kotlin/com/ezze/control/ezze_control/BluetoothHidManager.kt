package com.ezze.control.ezze_control

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHidDevice
import android.bluetooth.BluetoothHidDeviceAppQosSettings
import android.bluetooth.BluetoothHidDeviceAppSdpSettings
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import java.util.concurrent.Executors

/**
 * Native manager for Android Bluetooth HID Device profile (API 28+).
 * Handles profile acquisition, SDP registration, connection callbacks, report sending, and input cleanup.
 */
class BluetoothHidManager(private val context: Context) {

    companion object {
        private const val TAG = "BluetoothHidManager"
        const val SUBCLASS_COMBO: Byte = 0xC0.toByte() // 0x80 Mouse | 0x40 Keyboard
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    private val bluetoothManager: BluetoothManager? =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter? =
        bluetoothManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()

    private var hidProxy: BluetoothHidDevice? = null
    private var connectedDevice: BluetoothDevice? = null

    // State tracking
    private var isProfileRequestPending = false
    private var isProfileAvailable = false
    private var isRegistered = false
    private var isRegistering = false
    private var connectionState = BluetoothProfile.STATE_DISCONNECTED
    private var lastError: String? = null

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

                // Check if any devices are already connected to this profile
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
            Log.i(TAG, "onConnectionStateChanged: device=${device?.address}, state=$state")
            connectionState = state

            when (state) {
                BluetoothProfile.STATE_CONNECTED -> {
                    connectedDevice = device
                    val devName = safeGetDeviceName(device)
                    notifyEvent(
                        "connected",
                        "Connected to host device: $devName (${device?.address})"
                    )
                }
                BluetoothProfile.STATE_CONNECTING -> {
                    notifyEvent(
                        "connecting",
                        "Connecting to host device: ${device?.address}"
                    )
                }
                BluetoothProfile.STATE_DISCONNECTING -> {
                    notifyEvent(
                        "disconnecting",
                        "Disconnecting from host device: ${device?.address}"
                    )
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    val prevAddress = connectedDevice?.address ?: device?.address
                    connectedDevice = null
                    releaseAllInputs()
                    notifyEvent(
                        "disconnected",
                        "Disconnected from host device: $prevAddress"
                    )
                }
            }
        }

        override fun onGetReport(device: BluetoothDevice?, type: Byte, id: Byte, bufferSize: Int) {
            super.onGetReport(device, type, id, bufferSize)
            Log.d(TAG, "onGetReport: type=$type, id=$id, bufferSize=$bufferSize")
            try {
                hidProxy?.reportError(device, BluetoothHidDevice.ERROR_RSP_UNSUPPORTED_REQ)
            } catch (e: Exception) {
                Log.w(TAG, "Error responding to onGetReport: ${e.message}")
            }
        }

        override fun onSetReport(device: BluetoothDevice?, type: Byte, id: Byte, data: ByteArray?) {
            super.onSetReport(device, type, id, data)
            Log.d(TAG, "onSetReport: type=$type, id=$id, size=${data?.size}")
            try {
                hidProxy?.reportError(device, BluetoothHidDevice.ERROR_RSP_SUCCESS)
            } catch (e: Exception) {
                Log.w(TAG, "Error responding to onSetReport: ${e.message}")
            }
        }

        override fun onSetProtocol(device: BluetoothDevice?, protocol: Byte) {
            super.onSetProtocol(device, protocol)
            Log.d(TAG, "onSetProtocol: protocol=$protocol")
        }

        override fun onInterruptData(device: BluetoothDevice?, reportId: Byte, data: ByteArray?) {
            super.onInterruptData(device, reportId, data)
            Log.d(TAG, "onInterruptData: reportId=$reportId, size=${data?.size}")
        }

        override fun onVirtualCableUnplug(device: BluetoothDevice?) {
            super.onVirtualCableUnplug(device)
            Log.i(TAG, "onVirtualCableUnplug from device: ${device?.address}")
            connectedDevice = null
            connectionState = BluetoothProfile.STATE_DISCONNECTED
            releaseAllInputs()
            notifyEvent(
                "virtual_cable_unplug",
                "Host sent virtual cable unplug command."
            )
        }
    }

    private fun checkDeviceConnectionState(device: BluetoothDevice) {
        val proxy = hidProxy ?: return
        try {
            val state = proxy.getConnectionState(device)
            if (state == BluetoothProfile.STATE_CONNECTED) {
                connectedDevice = device
                connectionState = BluetoothProfile.STATE_CONNECTED
            }
        } catch (e: Exception) {
            Log.w(TAG, "checkDeviceConnectionState error: ${e.message}")
        }
    }

    private fun checkConnectedDevicesInternal() {
        val proxy = hidProxy ?: return
        try {
            val connectedList = proxy.connectedDevices
            if (!connectedList.isNullOrEmpty()) {
                connectedDevice = connectedList.first()
                connectionState = BluetoothProfile.STATE_CONNECTED
                Log.i(TAG, "Discovered already connected device: ${connectedDevice?.address}")
            }
        } catch (e: Exception) {
            Log.w(TAG, "checkConnectedDevicesInternal error: ${e.message}")
        }
    }

    /**
     * Check device and environment capabilities.
     */
    fun getCapabilities(): Map<String, Any?> {
        val sdkInt = Build.VERSION.SDK_INT
        val supportedApi = sdkInt >= Build.VERSION_CODES.P // API 28
        val btSupported = bluetoothAdapter != null
        val btEnabled = bluetoothAdapter?.isEnabled == true
        val missingPerms = getMissingPermissions()
        val hasPerms = missingPerms.isEmpty()

        // Double check active connected devices if proxy available
        if (hidProxy != null && connectionState != BluetoothProfile.STATE_CONNECTED) {
            checkConnectedDevicesInternal()
        }

        return mapOf(
            "supportedApi" to supportedApi,
            "sdkInt" to sdkInt,
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "androidVersion" to Build.VERSION.RELEASE,
            "bluetoothSupported" to btSupported,
            "bluetoothEnabled" to btEnabled,
            "permissionsGranted" to hasPerms,
            "missingPermissions" to missingPerms,
            "profileAvailable" to isProfileAvailable,
            "profilePending" to isProfileRequestPending,
            "isRegistered" to isRegistered,
            "isRegistering" to isRegistering,
            "connectionState" to connectionStateToString(connectionState),
            "connectedDeviceName" to safeGetDeviceName(connectedDevice),
            "connectedDeviceAddress" to connectedDevice?.address,
            "lastError" to lastError
        )
    }

    /**
     * Return list of paired/bonded Bluetooth devices.
     */
    fun getBondedDevices(): List<Map<String, String>> {
        val list = mutableListOf<Map<String, String>>()
        if (!hasRequiredPermissions()) return list

        try {
            val bonded = bluetoothAdapter?.bondedDevices ?: emptySet()
            for (device in bonded) {
                val name = safeGetDeviceName(device) ?: "Unknown Device"
                list.add(mapOf("name" to name, "address" to device.address))
            }
        } catch (e: Exception) {
            Log.e(TAG, "getBondedDevices error: ${e.message}")
        }
        return list
    }

    /**
     * Connect to a specific paired host device.
     */
    fun connectHost(address: String): Boolean {
        val proxy = hidProxy ?: run {
            lastError = "HID proxy not acquired."
            notifyEvent("error", lastError!!)
            return false
        }
        if (!isRegistered) {
            lastError = "HID app must be registered before connecting."
            notifyEvent("error", lastError!!)
            return false
        }

        try {
            val device = bluetoothAdapter?.getRemoteDevice(address) ?: run {
                lastError = "Could not find Bluetooth device for address: $address"
                notifyEvent("error", lastError!!)
                return false
            }
            val devName = safeGetDeviceName(device) ?: address
            notifyEvent("connecting", "Connecting to host: $devName ($address)...")
            val success = proxy.connect(device)
            if (!success) {
                lastError = "proxy.connect() returned false. Ensure host is in range and Bluetooth is on."
                notifyEvent("error", lastError!!)
            }
            return success
        } catch (se: SecurityException) {
            lastError = "SecurityException connecting to host: ${se.message}"
            notifyEvent("error", lastError!!)
            return false
        } catch (e: Exception) {
            lastError = "Exception connecting to host: ${e.message}"
            notifyEvent("error", lastError!!)
            return false
        }
    }

    /**
     * Remove pairing bond for a specific host device.
     */
    fun unpairHost(address: String): Boolean {
        try {
            val device = bluetoothAdapter?.getRemoteDevice(address) ?: return false
            val method = device.javaClass.getMethod("removeBond")
            val result = method.invoke(device) as? Boolean ?: false
            notifyEvent("unpaired", "Unpair requested for ${safeGetDeviceName(device)} ($address).")
            return result
        } catch (e: Exception) {
            Log.w(TAG, "removeBond reflection failed: ${e.message}")
            openBluetoothSettings()
            return false
        }
    }

    /**
     * Request system discoverable mode so Windows PC can detect the phone.
     */
    fun makeDiscoverable() {
        try {
            val intent = android.content.Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
                putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            notifyEvent("info", "Discoverable mode requested for 300 seconds.")
        } catch (e: Exception) {
            Log.e(TAG, "makeDiscoverable error: ${e.message}")
        }
    }

    /**
     * Open system Bluetooth settings.
     */
    fun openBluetoothSettings() {
        try {
            val intent = android.content.Intent(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS).apply {
                flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "openBluetoothSettings error: ${e.message}")
        }
    }

    /**
     * Request BluetoothHidDevice profile proxy from Android.
     */
    fun requestHidProfile(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            lastError = "Android API level ${Build.VERSION.SDK_INT} does not support BluetoothHidDevice (API 28+ required)."
            notifyEvent("error", lastError!!)
            return false
        }

        if (bluetoothAdapter == null) {
            lastError = "Bluetooth adapter not found on this device."
            notifyEvent("error", lastError!!)
            return false
        }

        if (!bluetoothAdapter.isEnabled) {
            lastError = "Bluetooth is currently turned off. Please enable Bluetooth."
            notifyEvent("error", lastError!!)
            return false
        }

        val missing = getMissingPermissions()
        if (missing.isNotEmpty()) {
            lastError = "Missing required Bluetooth permissions: ${missing.joinToString()}"
            notifyEvent("error", lastError!!)
            return false
        }

        if (hidProxy != null) {
            isProfileAvailable = true
            isProfileRequestPending = false
            return true
        }

        try {
            isProfileRequestPending = true
            val requested = bluetoothAdapter.getProfileProxy(
                context,
                profileServiceListener,
                BluetoothProfile.HID_DEVICE
            )
            if (!requested) {
                isProfileRequestPending = false
                lastError = "getProfileProxy returned false: Device firmware does not expose Bluetooth HID Device profile."
                notifyEvent("error", lastError!!)
                return false
            }
            notifyEvent(
                "profile_request_sent",
                "Profile proxy request submitted to Android Bluetooth stack."
            )
            return true
        } catch (se: SecurityException) {
            isProfileRequestPending = false
            lastError = "SecurityException while requesting HID profile: ${se.message}"
            notifyEvent("error", lastError!!)
            return false
        } catch (e: Exception) {
            isProfileRequestPending = false
            lastError = "Exception while requesting HID profile: ${e.message}"
            notifyEvent("error", lastError!!)
            return false
        }
    }

    /**
     * Register HID application with Android Bluetooth stack.
     */
    fun requestHidRegistration(): Boolean {
        if (!hasRequiredPermissions()) {
            lastError = "Cannot register HID application: Bluetooth permissions not granted."
            notifyEvent("error", lastError!!)
            return false
        }

        if (isRegistered) {
            notifyEvent("info", "HID application is already registered.")
            return true
        }

        isRegistering = true

        if (hidProxy == null) {
            Log.i(TAG, "Requesting profile proxy before registering HID app...")
            val requested = requestHidProfile()
            if (!requested) {
                isRegistering = false
                return false
            }
            return true
        }

        return executeRegistration()
    }

    private fun executeRegistration(): Boolean {
        val proxy = hidProxy
        if (proxy == null) {
            lastError = "HID proxy is null. Profile must be acquired first."
            isRegistering = false
            notifyEvent("error", lastError!!)
            return false
        }

        try {
            val sdpSettings = BluetoothHidDeviceAppSdpSettings(
                "Ezze Control",
                "Ezze Control Mouse & Keyboard",
                "Ezze",
                SUBCLASS_COMBO,
                HidReportDescriptor.DESCRIPTOR
            )

            val inQos: BluetoothHidDeviceAppQosSettings? = null
            val outQos: BluetoothHidDeviceAppQosSettings? = null

            val result = proxy.registerApp(
                sdpSettings,
                inQos,
                outQos,
                executor,
                hidCallback
            )

            if (!result) {
                isRegistering = false
                lastError = "registerApp() returned false. Firmware may prohibit third-party HID device registration."
                notifyEvent("registration_failed", lastError!!)
                return false
            }

            notifyEvent(
                "registration_requested",
                "registerApp() accepted by Bluetooth stack; awaiting OS callback..."
            )
            return true
        } catch (se: SecurityException) {
            isRegistering = false
            lastError = "SecurityException during registerApp: ${se.message}"
            notifyEvent("error", lastError!!)
            return false
        } catch (e: Exception) {
            isRegistering = false
            lastError = "Exception during registerApp: ${e.message}"
            notifyEvent("error", lastError!!)
            return false
        }
    }

    /**
     * Unregister the HID application.
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

    /**
     * Send relative mouse movement and optional button/wheel.
     */
    fun sendMouseMovement(buttons: Byte, dx: Int, dy: Int, wheel: Int = 0): Boolean {
        val report = HidReportEncoder.encodeMouse(buttons, dx, dy, wheel)
        return sendReport(HidReportDescriptor.REPORT_ID_MOUSE, report)
    }

    /**
     * Send test mouse movement (moves right 40px, pauses, moves back left 40px).
     */
    fun sendTestMouseMovement(): Boolean {
        if (connectedDevice == null || connectionState != BluetoothProfile.STATE_CONNECTED) {
            lastError = "Cannot send test movement: Host is not connected."
            notifyEvent("error", lastError!!)
            return false
        }

        executor.execute {
            try {
                notifyEvent("input_test", "Sending test mouse movement: Move Right +40px")
                sendMouseMovement(0, 40, 0, 0)
                Thread.sleep(70)
                sendMouseMovement(0, 0, 0, 0) // Stop
                Thread.sleep(120)
                notifyEvent("input_test", "Sending test mouse movement: Move Left -40px")
                sendMouseMovement(0, -40, 0, 0)
                Thread.sleep(70)
                sendMouseMovement(0, 0, 0, 0) // Stop
                notifyEvent("input_test", "Test mouse movement complete.")
            } catch (e: Exception) {
                Log.e(TAG, "sendTestMouseMovement error: ${e.message}")
            }
        }
        return true
    }

    /**
     * Send test key press (presses and releases Space key).
     */
    fun sendTestKey(): Boolean {
        if (connectedDevice == null || connectionState != BluetoothProfile.STATE_CONNECTED) {
            lastError = "Cannot send test key: Host is not connected."
            notifyEvent("error", lastError!!)
            return false
        }

        executor.execute {
            try {
                notifyEvent("input_test", "Sending test key report: Space key DOWN")
                val keyDown = HidReportEncoder.encodeKeyboard(
                    HidReportEncoder.MODIFIER_NONE,
                    byteArrayOf(HidReportEncoder.KEY_SPACE)
                )
                sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, keyDown)

                Thread.sleep(60)

                notifyEvent("input_test", "Sending test key report: Space key UP (Release)")
                val keyUp = HidReportEncoder.emptyKeyboard()
                sendReport(HidReportDescriptor.REPORT_ID_KEYBOARD, keyUp)
                notifyEvent("input_test", "Test key event completed.")
            } catch (e: Exception) {
                Log.e(TAG, "sendTestKey error: ${e.message}")
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
        } catch (e: Exception) {
            success = false
        }
        return success
    }

    /**
     * Disconnect from current host.
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
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_ADVERTISE)
                != PackageManager.PERMISSION_GRANTED) {
                missing.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            }
        }
        return missing
    }

    private fun safeGetDeviceName(device: BluetoothDevice?): String? {
        if (device == null) return null
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT)
                    == PackageManager.PERMISSION_GRANTED) {
                    device.name ?: device.address
                } else {
                    device.address
                }
            } else {
                device.name ?: device.address
            }
        } catch (e: Exception) {
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

    /**
     * Clean up resources on activity destroy.
     */
    fun cleanup() {
        try {
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
