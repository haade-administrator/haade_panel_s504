package com.example.mqtt_hatab

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_LED = "com.example.elcapi/led"
    private val CHANNEL_SENSOR = "com.example.elcapi/sensor"

    private lateinit var sensorChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // LED Channel
        MethodChannel(messenger, CHANNEL_LED).setMethodCallHandler { call, result ->
            if (call.method == "setLed") {
                val r = call.argument<Int>("r") ?: 0
                val g = call.argument<Int>("g") ?: 0
                val b = call.argument<Int>("b") ?: 0

                val success = LedLight.setColor(r, g, b)
                if (success) {
                    result.success(null)
                } else {
                    result.error("LED_ERROR", "Erreur lors du contrôle LED", null)
                }
            } else {
                result.notImplemented()
            }
        }

        // Capteurs : Température & Humidité
        sensorChannel = MethodChannel(messenger, CHANNEL_SENSOR)
        val handler = Handler(Looper.getMainLooper())

        SensorTH.start(object : SensorTH.SensorCallback {
            override fun onTemperatureChanged(tempCelsius: Double) {
                Log.d("MainActivity", "Température : $tempCelsius °C")
                handler.post {
                    sensorChannel.invokeMethod("onTemperature", tempCelsius)
                }
            }

            override fun onHumidityChanged(humidityPercent: Double) {
                Log.d("MainActivity", "Humidité : $humidityPercent %")
                handler.post {
                    sensorChannel.invokeMethod("onHumidity", humidityPercent)
                }
            }

            override fun onError(e: Exception) {
                Log.e("MainActivity", "Erreur capteur", e)
                handler.post {
                    sensorChannel.invokeMethod("onSensorError", e.message)
                }
            }
        })
    }
}




