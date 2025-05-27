package com.example.haade_panel_s504

import android.util.Log
import com.example.elcapi.jnielc

object LedLight {
    private const val TAG = "LedLight"

    fun setColor(r: Int, g: Int, b: Int): Boolean {
        return try {
            jnielc.seekstart()
            jnielc.ledseek(0xa1, r)
            jnielc.ledseek(0xa2, g)
            jnielc.ledseek(0xa3, b)
            jnielc.seekstop()
            true
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du contrôle des LEDs", e)
            false
        }
    }
}