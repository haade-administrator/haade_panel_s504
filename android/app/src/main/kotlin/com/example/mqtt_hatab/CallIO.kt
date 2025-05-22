package com.example.mqtt_hatab

import android.content.Context
import android.util.Log
import com.sys.gpio.gpioJni

object CallIO {
    private const val PREF_NAME = "ioPrefs"

    fun setHigh(context: Context, ioNumber: Int) {
        try {
            // Décommente si IO est en mode sortie
            gpioJni.ioctl_gpio(getIndex(ioNumber), 0, 1)  // Set HIGH
            saveState(context, ioNumber, true)
            Log.d("CallIO", "IO $ioNumber HIGH")
        } catch (e: Exception) {
            Log.e("CallIO", "Erreur en mettant IO $ioNumber HIGH", e)
        }
    }

    fun setLow(context: Context, ioNumber: Int) {
        try {
            // Décommente si IO est en mode sortie
            gpioJni.ioctl_gpio(getIndex(ioNumber), 0, 0)  // Set LOW
            saveState(context, ioNumber, false)
            Log.d("CallIO", "IO $ioNumber LOW")
        } catch (e: Exception) {
            Log.e("CallIO", "Erreur en mettant IO $ioNumber LOW", e)
        }
    }

    fun readIOState(ioNumber: Int): Boolean {
        return try {
            val index = getIndex(ioNumber)
            // Décommente si IO est en mode entrée
            val value = gpioJni.ioctl_gpio(index, 1, 1)  // Read level
            Log.d("CallIO", "Lecture IO$ioNumber (index $index) = ${value == 1}")
            value == 1
        } catch (e: Exception) {
            Log.e("CallIO", "Erreur lecture IO$ioNumber", e)
            false
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

    private fun getIndex(ioNumber: Int): Int {
        return when (ioNumber) {
            1 -> 0  // IO1 correspond à index 0
            2 -> 1  // IO2 correspond à index 1
            else -> throw IllegalArgumentException("Numéro IO invalide: $ioNumber")
        }
    }

    // Facultatif : pour fixer le mode par nom dans les logs (pas strictement nécessaire)
    fun logMode(ioNumber: Int, isInput: Boolean) {
        Log.i("CallIO", "IO$ioNumber configuré en ${if (isInput) "Entrée" else "Sortie"} (manuel via code)")
    }
}


