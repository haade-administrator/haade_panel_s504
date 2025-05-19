package com.example.mqtt_hatab

import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import android.util.Log
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.math.BigDecimal
import java.math.RoundingMode
import kotlin.concurrent.thread

object SensorTH {

    private const val TAG = "SensorTH"

    private var sensorCallback: SensorCallback? = null
    private var running = false
    private val handler = Handler(Looper.getMainLooper())

    // Change ici si tu souhaites paramétrer ces valeurs (comme dans le code original)
    private val humProp = SystemPropertiesProxy.getString("com.gulukai.hum", "8")
    private val thsProp = SystemPropertiesProxy.getString("com.gulukai.ths", "7")

    interface SensorCallback {
        fun onTemperatureChanged(tempCelsius: Double)
        fun onHumidityChanged(humidityPercent: Double)
        fun onError(e: Exception)
    }

    fun start(callback: SensorCallback) {
        sensorCallback = callback
        running = true

        thread {
            try {
                // Exécution de la commande 'getevent -l' (comme dans ton code Java)
                val process = Runtime.getRuntime().exec("getevent -l")
                val reader = BufferedReader(InputStreamReader(process.inputStream))

                while (running) {
                    val line = reader.readLine() ?: break
                    Log.i(TAG, "lineData: $line")

                    if (!TextUtils.isEmpty(line)) {
                        // Humidité : on cherche "event{hum}" + "EV_ABS" dans la ligne
                        if (line.contains("event$humProp") && line.contains("EV_ABS")) {
                            try {
                                // Exemple découpage équivalent à split("001d") dans Java
                                val parts = line.split("001d")
                                if (parts.size > 1) {
                                    val hexStr = parts[1].trim()
                                    val value = hexToDecimal(hexStr)
                                    val humidity = divideAndRound(value)
                                    handler.post {
                                        sensorCallback?.onHumidityChanged(humidity)
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Erreur parse humidité", e)
                            }
                        }

                        // Température : on cherche "event{ths}" + "EV_ABS"
                        if (line.contains("event$thsProp") && line.contains("EV_ABS")) {
                            try {
                                val parts = line.split("ABS_THROTTLE")
                                if (parts.size > 1) {
                                    val hexStr = parts[1].trim()
                                    val value = hexToDecimal(hexStr)
                                    val temperature = divideAndRound(value)
                                    handler.post {
                                        sensorCallback?.onTemperatureChanged(temperature)
                                    }
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Erreur parse température", e)
                            }
                        }
                    }
                }

                reader.close()
                process.destroy()
            } catch (e: IOException) {
                handler.post {
                    sensorCallback?.onError(e)
                }
            }
        }
    }

    fun stop() {
        running = false
    }

    private fun hexToDecimal(hex: String): Int {
        return hex.toInt(16)
    }

    private fun divideAndRound(number: Int): Double {
        return BigDecimal(number).divide(BigDecimal(100), 2, RoundingMode.HALF_UP).toDouble()
    }
}




