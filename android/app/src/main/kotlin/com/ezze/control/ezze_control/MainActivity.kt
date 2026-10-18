package com.ezze.control.ezze_control

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognizerIntent
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity(), HidPlatformChannel.ActivityCallbacks {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
        private const val SPEECH_REQUEST_CODE = 1002
        private const val DISCOVERABLE_REQUEST_CODE = 1003
    }

    private var hidManager: BluetoothHidManager? = null
    private var platformChannel: HidPlatformChannel? = null

    private var pendingPermissionCallback: ((Boolean) -> Unit)? = null
    private var pendingSpeechCallback: ((String?) -> Unit)? = null
    private var pendingDiscoverableCallback: ((Boolean) -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Keep screen awake while Ezze Control is active so Bluetooth HID profile isn't suspended
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val manager = BluetoothHidManager(this)
        this.hidManager = manager

        val channel = HidPlatformChannel(this, manager, this)
        this.platformChannel = channel

        channel.register(flutterEngine.dartExecutor.binaryMessenger)

        // Pre-initialize profile on launch
        manager.initProfile()
    }

    override fun onResume() {
        super.onResume()
        // Ensure HID registration stays alive if system revoked it while asleep
        hidManager?.let { mgr ->
            if (!mgr.isRegistered) {
                mgr.registerHid()
            }
        }
    }

    override fun requestPermissions(callback: (Boolean) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissions = arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.RECORD_AUDIO
            )
            pendingPermissionCallback = callback
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
        } else {
            val permissions = arrayOf(
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.RECORD_AUDIO
            )
            pendingPermissionCallback = callback
            ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
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
            hidManager?.initProfile()
        }
    }

    override fun startSpeechRecognition(callback: (String?) -> Unit) {
        pendingSpeechCallback = callback
        try {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak now")
            }
            startActivityForResult(intent, SPEECH_REQUEST_CODE)
        } catch (e: Exception) {
            pendingSpeechCallback?.invoke(null)
            pendingSpeechCallback = null
        }
    }

    override fun makeDiscoverable(durationSeconds: Int, callback: (Boolean) -> Unit) {
        pendingDiscoverableCallback = callback
        try {
            val intent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE).apply {
                putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, durationSeconds)
            }
            startActivityForResult(intent, DISCOVERABLE_REQUEST_CODE)
        } catch (e: Exception) {
            pendingDiscoverableCallback?.invoke(false)
            pendingDiscoverableCallback = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == SPEECH_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val results = data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
                val recognizedText = results?.firstOrNull()
                pendingSpeechCallback?.invoke(recognizedText)
            } else {
                pendingSpeechCallback?.invoke(null)
            }
            pendingSpeechCallback = null
        } else if (requestCode == DISCOVERABLE_REQUEST_CODE) {
            val success = resultCode != Activity.RESULT_CANCELED
            pendingDiscoverableCallback?.invoke(success)
            pendingDiscoverableCallback = null
        }
    }

    override fun onDestroy() {
        platformChannel?.unregister()
        hidManager?.cleanup()
        super.onDestroy()
    }
}
