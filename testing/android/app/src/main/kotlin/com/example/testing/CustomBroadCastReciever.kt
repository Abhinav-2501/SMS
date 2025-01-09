package com.example.testing

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class CustomBroadCastReciever : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action.equals("android.provider.Telephony.SMS_RECEIVED")) {
            Toast.makeText(context, "New SMS received!", Toast.LENGTH_SHORT).show()
        }

    }
}