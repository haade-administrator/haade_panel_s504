package com.example.mqtt_hatab

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine // ← ⚠️ c’est ce qui manquait
import io.flutter.plugin.common.MethodChannel
import com.example.elcapi.jnielc



class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.elcapi/led"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "setLed") {
                val r = call.argument<Int>("r") ?: 0
                val g = call.argument<Int>("g") ?: 0
                val b = call.argument<Int>("b") ?: 0
                jnielc.seekstart()
                jnielc.ledseek(0xa1, r)
                jnielc.ledseek(0xa2, g)
                jnielc.ledseek(0xa3, b)
                jnielc.seekstop()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}

