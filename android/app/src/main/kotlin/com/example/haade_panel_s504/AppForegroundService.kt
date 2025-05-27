package com.example.haade_panel_s504

import android.app.*
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

        startForeground(1, createNotification())
    }

    private fun createNotification(): Notification {
        val channelId = "app_foreground_service_channel"
        val channelName = "Service principal"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(chan)
        }

        // 👉 Intent pour rouvrir l'application quand on clique la notification
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Application Active")
            .setContentText("Les services fonctionnent en arrière-plan")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setContentIntent(pendingIntent) // 🔁 Clique = relance l'app
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("AppForegroundService", "Service démarré")
        // Tu peux démarrer ici les autres services
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("AppForegroundService", "Service détruit")
    }

    override fun onBind(intent: Intent?): IBinder? = null
}

