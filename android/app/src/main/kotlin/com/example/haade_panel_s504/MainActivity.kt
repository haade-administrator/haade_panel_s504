package com.example.haade_panel_s504

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.sys.gpio.gpioJni

class MainActivity : FlutterActivity() {

    private val CHANNEL_LED = "com.example.elcapi/led"
    private val CHANNEL_SENSOR = "com.example.elcapi/sensor"
    private val CHANNEL_RELAY = "com.example.relaycontrol/relay"
    private val CHANNEL_IO = "com.example.iocontrol/io"
    private val CHANNEL_LIGHT = "com.example.haade_panel_s504/light"

    private lateinit var sensorChannel: MethodChannel
    private lateinit var lightSensorService: LightSensorService

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Démarre le service en foreground
        val intent = Intent(this, AppForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Initialisation du capteur de luminosité
        val lightChannel = MethodChannel(messenger, CHANNEL_LIGHT)
        lightSensorService = LightSensorService(this, lightChannel)

        lightChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startListening" -> {
                    lightSensorService.startListening()
                    result.success(null)
                }
                "stopListening" -> {
                    lightSensorService.stopListening()
                    result.success(null)
                }
                "setThreshold" -> {
                    val threshold = call.argument<Double>("threshold")?.toFloat() ?: 30f
                    lightSensorService.setThreshold(threshold)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // LED
        MethodChannel(messenger, CHANNEL_LED).setMethodCallHandler { call, result ->
            if (call.method == "setLed") {
                val r = call.argument<Int>("r") ?: 0
                val g = call.argument<Int>("g") ?: 0
                val b = call.argument<Int>("b") ?: 0

                val success = LedLight.setColor(r, g, b)
                if (success) result.success(null) else result.error("LED_ERROR", "Erreur LED", null)
            } else {
                result.notImplemented()
            }
        }

        // Capteurs température / humidité
        sensorChannel = MethodChannel(messenger, CHANNEL_SENSOR)
        val handler = Handler(Looper.getMainLooper())
        SensorTH.start(object : SensorTH.SensorCallback {
            override fun onTemperatureChanged(tempCelsius: Double) {
                handler.post { sensorChannel.invokeMethod("onTemperature", tempCelsius) }
            }
            override fun onHumidityChanged(humidityPercent: Double) {
                handler.post { sensorChannel.invokeMethod("onHumidity", humidityPercent) }
            }
            override fun onError(e: Exception) {
                handler.post { sensorChannel.invokeMethod("onSensorError", e.message) }
            }
        })

        // Relais
        MethodChannel(messenger, CHANNEL_RELAY).setMethodCallHandler { call, result ->
            val relay = call.argument<Int>("relay") ?: 1
            val state = call.argument<Boolean>("state") ?: false
            try {
                if (call.method == "setRelayState") {
                    if (state) SwitchRelay.turnOn(this, relay) else SwitchRelay.turnOff(this, relay)
                    result.success(null)
                } else result.notImplemented()
            } catch (e: Exception) {
                result.error("RELAY_ERROR", e.message, null)
            }
        }

        // IO
        MethodChannel(messenger, CHANNEL_IO).setMethodCallHandler { call, result ->
            val ioNumber = call.argument<Int>("io") ?: -1
            if (ioNumber < 0) {
                result.error("INVALID_IO", "Numéro IO invalide", null)
                return@setMethodCallHandler
            }
            try {
                when (call.method) {
                    "setHigh" -> { CallIO.setHigh(this, ioNumber); result.success(null) }
                    "setLow" -> { CallIO.setLow(this, ioNumber); result.success(null) }
                    "getState" -> { result.success(CallIO.getIOState(this, ioNumber)) }
                    "readState" -> { result.success(CallIO.readIOState(ioNumber)) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("IO_ERROR", e.message, null)
            }
        }

        // Background (minimize app)
        MethodChannel(messenger, "com.example.haade_panel_s504/background")
            .setMethodCallHandler { call, result ->
                if (call.method == "minimizeApp") {
                    moveTaskToBack(true)
                    result.success(null)
                } else result.notImplemented()
            }
    }
}








