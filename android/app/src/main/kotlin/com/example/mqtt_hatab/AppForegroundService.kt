package com.example.mqtt_hatab

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class AppForegroundService : Service() {

    override fun onCreate() {
        super.onCreate()
        Log.d("AppForegroundService", "Service créé")

        // Ici tu peux démarrer tes services / logiques spécifiques
        // Exemple:
        // LightSensorService.start(this)
        // RelayService.start(this)
        // etc.

        startForeground(1, createNotification())
    }

    private fun createNotification(): Notification {
        val channelId = "app_foreground_service_channel"
        val channelName = "Service principal"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_LOW)
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(chan)
        }

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Application Active")
            .setContentText("Les services sont en fonctionnement")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Optionnel : lancer ou vérifier les services ici
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("AppForegroundService", "Service détruit")
        // Stop services si besoin
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
