package com.example.haade_panel_s504

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class BootService : Service() {

    companion object {
        private const val CHANNEL_ID = "mqtt_service_channel"
        private const val NOTIFICATION_ID = 1
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("BootService", "Service démarré")

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Service MQTT actif")
            .setContentText("Le service MQTT tourne en arrière-plan")
            .setSmallIcon(R.mipmap.ic_launcher) // remplace par ton icône
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        // Démarre le service en mode foreground avec la notification
        startForeground(NOTIFICATION_ID, notification)

        // TODO: place ici ton code de service (ex: connexion MQTT...)

        // Si tu ne veux pas que le service soit relancé automatiquement après kill
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Service MQTT",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}

