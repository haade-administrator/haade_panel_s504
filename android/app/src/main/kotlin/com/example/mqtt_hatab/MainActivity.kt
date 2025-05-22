package com.example.mqtt_hatab

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.sys.gpio.gpioJni  // Assure-toi que cette classe existe bien

class MainActivity : FlutterActivity() {
    private val CHANNEL_LED = "com.example.elcapi/led"
    private val CHANNEL_SENSOR = "com.example.elcapi/sensor"
    private val CHANNEL_RELAY = "com.example.relaycontrol/relay"
    private val CHANNEL_IO = "com.example.iocontrol/io"


    private lateinit var sensorChannel: MethodChannel

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Test GPIO RELAY 2 supprimé
    }

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

        // RELAY Channel - nouveau handler
        MethodChannel(messenger, CHANNEL_RELAY).setMethodCallHandler { call, result ->
            if (call.method == "setRelayState") {
                val relay = call.argument<Int>("relay") ?: 1
                val state = call.argument<Boolean>("state") ?: false
                Log.d("MainActivity", "setRelayState: relay=$relay state=$state")

                try {
                    if (state) {
                        SwitchRelay.turnOn(this, relay)
                    } else {
                        SwitchRelay.turnOff(this, relay)
                    }
                    result.success(null)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Erreur contrôle relais", e)
                    result.error("RELAY_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
        // IO Channel - handler pour setHigh, setLow, getState, readState
MethodChannel(messenger, CHANNEL_IO).setMethodCallHandler { call, result ->
    val ioNumber = call.argument<Int>("io") ?: -1
    if (ioNumber < 0) {
        result.error("INVALID_IO", "Numéro IO invalide", null)
        return@setMethodCallHandler
    }

    try {
        when (call.method) {
            "setHigh" -> {
                CallIO.setHigh(this, ioNumber)
                result.success(null)
            }
            "setLow" -> {
                CallIO.setLow(this, ioNumber)
                result.success(null)
            }
            "getState" -> {
                val state = CallIO.getIOState(this, ioNumber)
                result.success(state)
            }
            "readState" -> {
                val state = CallIO.readIOState(ioNumber)
                result.success(state)
            }
            else -> result.notImplemented()
        }
    } catch (e: Exception) {
        Log.e("MainActivity", "Erreur IO $ioNumber", e)
        result.error("IO_ERROR", e.message, null)
    }
}

    }
}







