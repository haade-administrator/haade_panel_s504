package com.example.haade_panel_s504

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.util.Log
import java.util.concurrent.TimeUnit

/**
 * Every 15 minutes: restart the service if something killed it (setting "Restart if stopped").
 * Android lets a background app start a foreground service only when it is exempt from battery
 * optimisation — the settings screen has a button for that.
 */
class WatchdogJob : JobService() {

    override fun onStartJob(params: JobParameters?): Boolean {
        if (!PanelService.running && Prefs(this).watchdog) PanelService.start(this)
        return false
    }

    override fun onStopJob(params: JobParameters?): Boolean = false

    companion object {
        private const val JOB_ID = 504

        fun sync(context: Context, enabled: Boolean) {
            val scheduler = context.getSystemService(JobScheduler::class.java) ?: return
            if (!enabled) {
                scheduler.cancel(JOB_ID)
                return
            }
            if (scheduler.getPendingJob(JOB_ID) != null) return
            val job = JobInfo.Builder(JOB_ID, ComponentName(context, WatchdogJob::class.java))
                .setPeriodic(TimeUnit.MINUTES.toMillis(15))
                .setPersisted(true)
                .build()
            try {
                scheduler.schedule(job)
            } catch (e: Exception) {
                Log.w("PanelWatchdog", "schedule failed: $e")
            }
        }
    }
}
