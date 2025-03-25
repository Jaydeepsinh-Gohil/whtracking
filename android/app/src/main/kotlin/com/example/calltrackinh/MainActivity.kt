package com.example.calltrackinh

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity(){
    private val CHANNEL = "com.example.app/service"
    private val REQUEST_CODE_PERMISSIONS = 1001

    // List of permissions to check
    private val permissions = arrayOf(
        Manifest.permission.READ_PHONE_STATE,
        Manifest.permission.READ_CALL_LOG,
        Manifest.permission.RECEIVE_SMS,
        Manifest.permission.READ_CALL_LOG
    )


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermissions" -> {
                    // Check if all permissions are granted
                    if (arePermissionsGranted()) {
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "startSilentService" -> {
                    val serviceIntent = Intent(this, SilentService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun arePermissionsGranted(): Boolean {
        // Check if all permissions are granted
        for (permission in permissions) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                return false
            }
        }
        return true
    }

    private fun requestPermissions() {
        // Show a dialog to ask for permissions
        val builder = android.app.AlertDialog.Builder(this)
        builder.setTitle("Permissions Required")
            .setMessage("To use this app, we need the following permissions: Phone State, Call Log, and SMS.")
            .setCancelable(false)
            .setPositiveButton("Allow") { dialog, id ->
                // Request the permissions
                ActivityCompat.requestPermissions(this, permissions, REQUEST_CODE_PERMISSIONS)
            }
            .setNegativeButton("Disallow") { dialog, id ->
                // Show a message if the user denies the permissions
                Toast.makeText(this, "Permissions are required to start the service.", Toast.LENGTH_SHORT).show()
                dialog.dismiss()
            }

        val dialog = builder.create()
        dialog.show()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            var allPermissionsGranted = true
            for (result in grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allPermissionsGranted = false
                    break
                }
            }

            if (allPermissionsGranted) {
                // Permissions granted, start the service
                val serviceIntent = Intent(this, SilentService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
            } else {
                // If any permission is denied, show a toast message
                Toast.makeText(this, "Permissions are not granted. Service cannot start.", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // If permissions are not granted, show the permission request dialog
        if (!arePermissionsGranted()) {
            requestPermissions()
        }
    }
}
