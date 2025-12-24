package com.example.haade_panel_s504

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class LightSensorService(
    private val context: Context,
    private val methodChannel: MethodChannel
) : SensorEventListener {

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

        // Envoie vers Flutter via MethodChannel
        methodChannel.invokeMethod("onLightChanged", value)

        if (value > threshold) {
            Log.d("LightSensorService", "Light level above threshold ($threshold lx)")
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}

