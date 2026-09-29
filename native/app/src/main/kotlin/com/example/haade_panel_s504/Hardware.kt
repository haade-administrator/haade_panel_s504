package com.example.haade_panel_s504

import android.util.Log
import com.example.elcapi.jnielc
import com.sys.gpio.gpioJni

/**
 * Panel hardware through the vendor JNI libraries (same calls as the original app).
 * Only PanelService's single worker thread calls this, so the driver never sees concurrent requests.
 */
object Hardware {
    private const val TAG = "PanelHw"

    @Volatile var ledError: String? = null
        private set
    @Volatile var gpioError: String? = null
        private set

    private var ledBroken = false
    private var gpioBroken = false

    /** r, g, b in 0..255; the driver takes 16 steps per channel. */
    fun setLed(r: Int, g: Int, b: Int): Boolean {
        if (ledBroken) return false
        var lr = level(r)
        var lg = level(g)
        var lb = level(b)
        if (lr == 0 && lg == 0 && lb == 0 && (r > 0 || g > 0 || b > 0)) {
            // Very dim but switched on: light the strongest channel at the lowest step instead of going dark.
            when (maxOf(r, g, b)) {
                r -> lr = 1
                g -> lg = 1
                else -> lb = 1
            }
        }
        return try {
            jnielc.seekstart()
            jnielc.ledseek(0xa1, lr)
            jnielc.ledseek(0xa2, lg)
            jnielc.ledseek(0xa3, lb)
            jnielc.seekstop()
            ledError = null
            true
        } catch (t: Throwable) {
            ledError = describe(t)
            if (t is LinkageError) ledBroken = true
            Log.e(TAG, "LED", t)
            false
        }
    }

    /** Relay 1 is GPIO 3, relay 2 is GPIO 2. */
    fun setRelay(relay: Int, on: Boolean): Boolean =
        gpio { gpioJni.ioctl_gpio(if (relay == 1) 3 else 2, 0, if (on) 1 else 0) } != null

    /** IO1 is GPIO index 0, IO2 is index 1; null when the GPIO driver is unavailable. */
    fun readInput(input: Int): Boolean? = gpio { gpioJni.ioctl_gpio(input - 1, 1, 1) == 1 }

    private inline fun <T> gpio(block: () -> T): T? {
        if (gpioBroken) return null
        return try {
            block().also { gpioError = null }
        } catch (t: Throwable) {
            gpioError = describe(t)
            if (t is LinkageError) gpioBroken = true
            Log.e(TAG, "GPIO", t)
            null
        }
    }

    // Same rounding as the original app: round(v / 17), 0..15.
    private fun level(v: Int) = ((v.coerceIn(0, 255) + 8) / 17).coerceIn(0, 15)

    private fun describe(t: Throwable) = t.javaClass.simpleName + (t.message?.let { ": $it" } ?: "")
}
