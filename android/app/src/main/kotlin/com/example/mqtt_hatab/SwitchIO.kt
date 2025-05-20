package com.example.mqtt_hatab

import android.content.Context
import android.util.Log
import com.sys.gpio.gpioJni

object SwitchIO {
    private const val PREF_NAME = "ioPrefs"

    fun setHigh(context: Context, ioNumber: Int) {
        try {
            gpioJni.ioctl_gpio(ioNumber, 0, 1)  // Set High Level
            saveState(context, ioNumber, true)
            Log.d("SwitchIO", "IO $ioNumber HIGH")
        } catch (e: Exception) {
            Log.e("SwitchIO", "Erreur en mettant IO $ioNumber HIGH", e)
        }
    }

    fun setLow(context: Context, ioNumber: Int) {
        try {
            gpioJni.ioctl_gpio(ioNumber, 0, 0)  // Set Low Level
            saveState(context, ioNumber, false)
            Log.d("SwitchIO", "IO $ioNumber LOW")
        } catch (e: Exception) {
            Log.e("SwitchIO", "Erreur en mettant IO $ioNumber LOW", e)
        }
    }

    fun getIOState(context: Context, ioNumber: Int): Boolean {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean("io_$ioNumber", false)
    }

    private fun saveState(context: Context, ioNumber: Int, state: Boolean) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("io_$ioNumber", state).apply()
    }
}
