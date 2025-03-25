package com.example.calltrackinh
import android.R
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat


class CallAndSmsForegroundService : Service() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(1, createMinimalNotification())
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        // Add any background task handling (call/SMS tracking) here
        return START_STICKY // Service will restart if killed
    }

    override fun onBind(intent: Intent): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Call and SMS Tracker",
                NotificationManager.IMPORTANCE_MIN
            )
            channel.setShowBadge(false)
            val notificationManager = getSystemService(
                NotificationManager::class.java
            )
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createMinimalNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_overlay) // You can set a small or invisible icon
            .setContentTitle("")
            .setContentText("")
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "CallAndSmsServiceChannel"
    }
}
