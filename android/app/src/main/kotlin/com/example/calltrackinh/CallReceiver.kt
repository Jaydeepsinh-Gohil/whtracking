package com.example.calltrackinh_admin

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Context.MODE_PRIVATE
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.CallLog
import android.provider.ContactsContract
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import com.google.firebase.firestore.FirebaseFirestore

class CallReceiver : BroadcastReceiver() {
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

            if (state == TelephonyManager.EXTRA_STATE_RINGING) {
                // Incoming call is ringing
                if (incomingNumber != null) {
                    // If incoming number is null, it's an incoming call
                    logToFirebase("Incoming call from: $incomingNumber")
                    val contactName = getContactName(context, incomingNumber) ?: incomingNumber // Get name or fallback to number
                    insertCallToFirebase(context, "Incoming call", incomingNumber,contactName.toString())
                }

            } else if (state == TelephonyManager.EXTRA_STATE_OFFHOOK) {
                if(incomingNumber != null) {
                    logToFirebase("Call answered: $incomingNumber")
                    val contactName = getContactName(context, incomingNumber) ?: incomingNumber // Get name or fallback to number
                    insertCallToFirebase(context, "Outgoing call", incomingNumber,contactName.toString())
                }
            } else if (state == TelephonyManager.EXTRA_STATE_IDLE) {
                // Call ended
                logToFirebase("Call ended")
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

    private fun insertCallToFirebase(context: Context, callType: String, phoneNumber: String?,contactName: String?) {
        val userData = getUserDataFromNative(context)
        val db = FirebaseFirestore.getInstance()
        val timestampMillis = System.currentTimeMillis()
        val callData = mapOf(
            "id" to timestampMillis,
            "userId" to (userData?.get("userId") ?: ""),
            "username" to (userData?.get("username") ?: ""),
            "callType" to callType,
            "phoneNumber" to (phoneNumber ?: "Unknown"),
            "contactName" to (contactName ?: ""),
            "timestamp" to timestampMillis
        )

        db.collection("calls")
            .document(timestampMillis.toString())
            .set(callData)
            .addOnSuccessListener {
                println("Call data inserted successfully: $callType, $phoneNumber")
            }
            .addOnFailureListener { e ->
                println("Error inserting call data: ${e.message}")
            }
    }


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

    @SuppressLint("Range")
    private fun getOutgoingNumber(context: Context): String? {
        var outgoingNumber: String? = null
            // Query to get the most recent outgoing call
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.TYPE),
                "${CallLog.Calls.TYPE} = ?",
                arrayOf(CallLog.Calls.OUTGOING_TYPE.toString()),  // Use OUTGOING_TYPE here
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    outgoingNumber = it.getString(it.getColumnIndex(CallLog.Calls.NUMBER))
                }
            }

        return outgoingNumber
    }


    private fun trackOutgoingCall(context: Context) {
        // Create and register a PhoneStateListener to listen for outgoing calls
        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        phoneStateListener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)
                if (state == TelephonyManager.CALL_STATE_OFFHOOK) {
                    // Call is active, capture the outgoing number
                    if (phoneNumber != null) {
                        logToFirebase("Outgoing call to: $phoneNumber")
                    }
                }
            }
        }

        // Check for permission and listen to phone state
//        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
//        } else {
//            // Request permission if not granted
//            Log.e("CallReceiver", "Permission not granted for PHONE_STATE")
//        }
    }


    private fun logToFirebase(message: String) {
        println("Tracking Call receiver message: $message")
    }

}
