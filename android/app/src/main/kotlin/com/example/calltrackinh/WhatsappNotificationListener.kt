package com.example.calltrackinh

import android.app.Notification
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class WhatsappNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            val packageName = sbn.packageName

            // Only process WhatsApp notifications
            if (packageName != "com.whatsapp") return

            val notification: Notification = sbn.notification
            val extras: Bundle = notification.extras

            val title = extras.getString(Notification.EXTRA_TITLE) ?: "Unknown"
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: "No message"

            Log.d("WhatsAppListener", "Sender: $title | Message: $text")

            insertWhatsappToLocal(
                context = applicationContext,
                sender = title,
                message = text
            )

        } catch (e: Exception) {
            Log.e("WhatsAppListener", "Error reading notification: ${e.message}")
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        // Optional: handle removed notifications
    }


    private fun insertWhatsappToFirebase(
        context: Context,
        sender: String?,
        message: String?
    ) {
        val db = FirebaseFirestore.getInstance()
        val timestampMillis = System.currentTimeMillis()

        val data = mapOf(
            "id" to timestampMillis,
            "sender" to (sender ?: ""),
            "message" to (message ?: ""),
            "type" to "whatsapp",
            "timestamp" to timestampMillis
        )

        db.collection("whatsapp_notifications")
            .document(timestampMillis.toString())
            .set(data)
            .addOnSuccessListener {
                Log.d("WhatsAppListener", "Data inserted")
            }
            .addOnFailureListener {
                Log.e("WhatsAppListener", "Error: ${it.message}")
            }
    }


    data class WhatsappMessage(
        val id: Long,
        val sender: String,
        val message: String,
        val type: String,
        val timestamp: Long
    )

//    private fun insertWhatsappToLocal(
//        context: Context,
//        sender: String?,
//        message: String?
//    ) {
//        val sharedPreferences: SharedPreferences =
//            context.getSharedPreferences("WhatsappLocalDB", Context.MODE_PRIVATE)
//
//        val gson = Gson()
//
//        // Get existing data
//        val json = sharedPreferences.getString("messages", null)
//
//        val type = object : TypeToken<MutableList<WhatsappMessage>>() {}.type
//        val messageList: MutableList<WhatsappMessage> =
//            if (json != null) gson.fromJson(json, type) else mutableListOf()
//
//        // Create new message
//        val timestampMillis = System.currentTimeMillis()
//        val newMessage = WhatsappMessage(
//            id = timestampMillis,
//            sender = sender ?: "",
//            message = message ?: "",
//            type = "whatsapp",
//            timestamp = timestampMillis
//        )
//
//        // Add new message
//        messageList.add(0, newMessage) // latest on top
//
//        // Save back
//        val updatedJson = gson.toJson(messageList)
//        sharedPreferences.edit().putString("messages", updatedJson).apply()
//
//        Log.d("LocalStorage", "Message saved locally")
//    }

    private fun insertWhatsappToLocal(
        context: Context,
        sender: String?,
        message: String?
    ) {
        val sharedPreferences: SharedPreferences =
            context.getSharedPreferences("WhatsappLocalDB", Context.MODE_PRIVATE)

        val gson = Gson()

        // Get existing data
        val json = sharedPreferences.getString("messages", null)

        // ✅ SAFE parsing (no TypeToken)
        val messageList: MutableList<WhatsappMessage> =
            if (!json.isNullOrEmpty()) {
                try {
                    gson.fromJson(json, Array<WhatsappMessage>::class.java).toMutableList()
                } catch (e: Exception) {
                    e.printStackTrace()
                    mutableListOf()
                }
            } else {
                mutableListOf()
            }

        // Create new message
        val timestampMillis = System.currentTimeMillis()
        val newMessage = WhatsappMessage(
            id = timestampMillis,
            sender = sender ?: "",
            message = message ?: "",
            type = "whatsapp",
            timestamp = timestampMillis
        )

        // Add new message (latest on top)
        messageList.add(0, newMessage)

        // Save back
        val updatedJson = gson.toJson(messageList)

        // 👉 Use commit() for background service reliability
        sharedPreferences.edit().putString("messages", updatedJson).commit()

        Log.d("LocalStorage", "Message saved locally: $updatedJson")
    }

}