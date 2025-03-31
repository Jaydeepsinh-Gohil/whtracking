package com.example.calltrackinh

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.example.calltrackinh.SilentService

class ServiceRestarterReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == "com.example.calltrackinh.RESTART_SERVICE") {
//            try {
//                val serviceIntent = Intent(context, SilentService::class.java)
//                context.stopService(serviceIntent)
//            } catch (e: Exception) {}
//
//
//
//            try {
//                val serviceIntent = Intent(context, SilentService::class.java)
//                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                    context.startForegroundService(serviceIntent)
//                } else {
//                    context.startService(serviceIntent)
//                }
//            } catch (e: Exception) {}
        }
    }
}
