package com.example.haade_panel_s504

import android.content.Context
import android.util.Log
import com.sys.gpio.gpioJni

object SwitchRelay {
    private const val PREF_NAME = "relayPrefs"

    fun turnOn(context: Context, relayNumber: Int) {
        try {
            gpioJni.ioctl_gpio(getGpioNumber(relayNumber), 0, 1)
            saveState(context, relayNumber, true)
            Log.d("SwitchRelay", "Relais $relayNumber ON")
        } catch (e: Exception) {
            Log.e("SwitchRelay", "Erreur en allumant relais $relayNumber", e)
        }
    }

    fun turnOff(context: Context, relayNumber: Int) {
        try {
            gpioJni.ioctl_gpio(getGpioNumber(relayNumber), 0, 0)
            saveState(context, relayNumber, false)
            Log.d("SwitchRelay", "Relais $relayNumber OFF")
        } catch (e: Exception) {
            Log.e("SwitchRelay", "Erreur en éteignant relais $relayNumber", e)
        }
    }

    fun getRelayState(context: Context, relayNumber: Int): Boolean {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean("relay_$relayNumber", false)
    }

    private fun saveState(context: Context, relayNumber: Int, state: Boolean) {
        val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
        prefs.edit().putBoolean("relay_$relayNumber", state).apply()
    }

    private fun getGpioNumber(relayNumber: Int): Int {
        return when (relayNumber) {
            1 -> 3 // Relay 1 = GPIO 3
            2 -> 2 // Relay 2 = GPIO 2
            else -> throw IllegalArgumentException("Relais $relayNumber non valide")
        }
    }
}
