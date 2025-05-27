package com.example.mqtt_hatab

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Boot completed detected")

            // Par exemple, démarrer un service au boot
            val serviceIntent = Intent(context, BootService::class.java)
            context.startForegroundService(serviceIntent)
        }
    }
}
