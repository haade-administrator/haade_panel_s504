package com.example.haade_panel_s504

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Handler
import android.os.HandlerThread

/** Optional ambient light sensor; callbacks arrive on a background thread, never the main one. */
class LightMonitor(context: Context, private val onLux: (Double) -> Unit) : SensorEventListener {

    private val sensorManager: SensorManager? = context.getSystemService(SensorManager::class.java)
    private var thread: HandlerThread? = null

    /** false when the panel has no light sensor. */
    fun start(): Boolean {
        val manager = sensorManager ?: return false
        val sensor = manager.getDefaultSensor(Sensor.TYPE_LIGHT) ?: return false
        val t = HandlerThread("panel-lux").also { it.start() }
        thread = t
        return manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_NORMAL, Handler(t.looper))
    }

    fun stop() {
        sensorManager?.unregisterListener(this)
        thread?.quitSafely()
        thread = null
    }

    override fun onSensorChanged(event: SensorEvent) {
        onLux(event.values[0].toDouble())
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
