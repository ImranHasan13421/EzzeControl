package com.ezze.control.ezze_control

import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    private var hidManager: BluetoothHidManager? = null
    private var platformChannel: HidPlatformChannel? = null
    private var pendingPermissionCallback: ((Boolean) -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val manager = hidManager ?: BluetoothHidManager(this).also { hidManager = it }
        val channel = platformChannel ?: HidPlatformChannel(this, manager).also { platformChannel = it }

        channel.register(flutterEngine.dartExecutor.binaryMessenger)
        channel.onRequestPermissionsHandler = { onResult ->
            val missing = manager.getMissingPermissions()
            if (missing.isEmpty()) {
                onResult(true)
            } else {
                pendingPermissionCallback = onResult
                ActivityCompat.requestPermissions(
                    this,
                    missing.toTypedArray(),
                    PERMISSION_REQUEST_CODE
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingPermissionCallback?.invoke(allGranted)
            pendingPermissionCallback = null
        }
    }

    override fun onDestroy() {
        platformChannel?.unregister()
        hidManager?.cleanup()
        super.onDestroy()
    }
}
