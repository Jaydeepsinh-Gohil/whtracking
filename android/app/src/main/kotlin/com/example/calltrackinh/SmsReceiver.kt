package com.example.calltrackinh

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.telephony.SmsMessage

class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.provider.Telephony.SMS_RECEIVED") {
            val bundle: Bundle? = intent.extras
            if (bundle != null) {
                val pdus = bundle["pdus"] as Array<*>
                val messages = pdus.map { SmsMessage.createFromPdu(it as ByteArray) }

                for (message in messages) {
                    val sender = message.originatingAddress
                    val content = message.messageBody
                    logToFirebase("SMS from $sender: $content")
                }
            }
        }
    }

    private fun logToFirebase(message: String) {
        println("Tracking sms reciver message: $message")
    }
}
