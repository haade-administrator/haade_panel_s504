package com.example.mqtt_hatab

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.PowerManager
import android.util.Log

class LightSensorService(private val context: Context) : SensorEventListener {

    private var sensorManager: SensorManager? = null
    private var lightSensor: Sensor? = null
    private var threshold: Float = 30.0f
    private var lastValue: Float = 0f

    fun startListening() {
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)

        lightSensor?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            Log.d("LightSensorService", "Light sensor listening started.")
        } ?: run {
            Log.e("LightSensorService", "Light sensor not available.")
        }
    }

    fun stopListening() {
        sensorManager?.unregisterListener(this)
        Log.d("LightSensorService", "Light sensor listening stopped.")
    }

    fun setThreshold(threshold: Float) {
        this.threshold = threshold
        Log.d("LightSensorService", "Threshold set to $threshold")
    }

    override fun onSensorChanged(event: SensorEvent?) {
        val value = event?.values?.firstOrNull() ?: return
        lastValue = value
        Log.d("LightSensorService", "Current light level: $value lx")

        (context as? MainActivity)?.sendLightToFlutter(value)

        if (value > threshold) {
            Log.d("LightSensorService", "Light level above threshold ($threshold lx), waking tablet.")
            wakeTablet()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Optionnel : rien à faire ici
    }

    private fun wakeTablet() {
        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.SCREEN_DIM_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "mqtt_hatab::LightSensorWakeLock"
            )
            wakeLock.acquire(3000) // Réveille l'écran pendant 3 secondes max
            Log.d("LightSensorService", "WakeLock acquired for 3 seconds.")
        } catch (e: SecurityException) {
            Log.e("LightSensorService", "WakeLock permission missing: ${e.message}")
        }
    }
}