package com.example.haade_panel_s504

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Starts the service after a reboot and after an app update (setting "Start after reboot"). */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON" -> if (Prefs(context).autostart) PanelService.start(context)
        }
    }
}
