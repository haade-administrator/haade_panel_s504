package com.example.haade_panel_s504

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.Network
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.util.Log
import org.json.JSONException
import org.json.JSONObject
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * The whole app: a foreground service that owns the MQTT connection and the panel hardware.
 * It does not depend on any screen being open, starts on boot, and is restarted by Android
 * (START_STICKY) or by [WatchdogJob] if it ever dies.
 *
 * All state lives on one worker thread, so hardware calls and MQTT handling never race.
 */
class PanelService : Service() {

    companion object {
        private const val TAG = "PanelService"
        const val ACTION_RELOAD = "com.example.haade_panel_s504.action.RELOAD"
        const val ACTION_TEST_LED = "com.example.haade_panel_s504.action.TEST_LED"
        private const val CHANNEL_ID = "panel_service"
        private const val NOTIFICATION_ID = 1
        private const val LUX_MIN_INTERVAL_MS = 5_000L

        @Volatile var running = false
            private set

        fun start(context: Context, action: String? = null) {
            val intent = Intent(context, PanelService::class.java).setAction(action)
            try {
                context.startForegroundService(intent)
            } catch (e: Exception) {
                Log.w(TAG, "cannot start service: $e")
            }
        }
    }

    private lateinit var prefs: Prefs
    private val worker: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { r -> Thread(r, "panel-worker") }

    private var topics = Topics(Topics.DEFAULT_BASE)
    private var deviceName = ""
    private var mqtt: MqttLink? = null
    private var ths: ThsReader? = null
    private var light: LightMonitor? = null
    private var inputTask: ScheduledFuture<*>? = null
    private var republishTask: ScheduledFuture<*>? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var notificationText = ""
    private var inputTriggersRelay = false

    // LED as Home Assistant sees it: unscaled colour plus brightness.
    private var ledOn = false
    private var ledR = 255
    private var ledG = 255
    private var ledB = 255
    private var ledBrightness = 255

    private val relayOn = BooleanArray(3)
    private val inputOn = arrayOfNulls<Boolean>(3)
    private var temperature: Double? = null
    private var humidity: Int? = null
    private var lux: Double? = null
    private var luxSentAt = 0L
    private var luxPending: Double? = null
    private var luxTask: ScheduledFuture<*>? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        running = true
        prefs = Prefs(this)
        createChannel()
        if (!startInForeground(getString(R.string.status_starting))) {
            running = false
            stopSelf()
            return
        }
        exec {
            restoreHardware()
            startFeatures()
        }
        registerNetworkCallback()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_RELOAD -> exec {
                stopFeatures(publishOffline = true)
                startFeatures()
            }
            ACTION_TEST_LED -> exec { testLed() }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        running = false
        unregisterNetworkCallback()
        exec { stopFeatures(publishOffline = true) }
        worker.shutdown()
        try {
            worker.awaitTermination(8, TimeUnit.SECONDS)
        } catch (_: InterruptedException) {
        }
        super.onDestroy()
    }

    // ---------------------------------------------------------------- features

    private fun startFeatures() {
        PanelStatus.resetConnection()
        WatchdogJob.sync(this, prefs.watchdog)
        topics = Topics(prefs.nodeId)
        deviceName = prefs.deviceName
        inputTriggersRelay = prefs.ioTriggersRelay
        if (prefs.isConfigured) {
            val cfg = MqttLink.Config(prefs.host, prefs.port, prefs.user, prefs.pass, prefs.tls, prefs.clientId, topics)
            mqtt = MqttLink(cfg, linkListener(cfg.host)).also { it.start() }
        } else {
            setStatus(PanelStatus.Link.NOT_CONFIGURED, getString(R.string.status_not_configured))
        }
        if (prefs.thsEnabled) {
            ths = ThsReader { kind, value -> exec { onClimate(kind, value) } }.also { it.start() }
        } else {
            temperature = null
            humidity = null
            PanelStatus.temperature = null
            PanelStatus.humidity = null
        }
        if (prefs.ioEnabled) {
            inputTask = worker.scheduleWithFixedDelay(Runnable { safely { pollInputs() } }, 0, 1, TimeUnit.SECONDS)
        }
        if (prefs.luxEnabled) {
            val monitor = LightMonitor(this) { value -> exec { onLux(value) } }
            if (monitor.start()) light = monitor else PanelStatus.lux = "—"
        } else {
            lux = null
        }
    }

    private fun stopFeatures(publishOffline: Boolean) {
        inputTask?.cancel(false)
        inputTask = null
        republishTask?.cancel(false)
        republishTask = null
        luxTask?.cancel(false)
        luxTask = null
        luxPending = null
        ths?.stop()
        ths = null
        light?.stop()
        light = null
        mqtt?.stop(publishOffline)
        mqtt = null
        inputOn.fill(null)
    }

    private fun linkListener(host: String) = object : MqttLink.Listener {
        override fun onReady() = exec { publishEverything() }

        override fun onMessage(topic: String, payload: String) = exec { handleMessage(topic, payload) }

        override fun onState(state: MqttLink.State, problem: MqttLink.Problem?) = when (state) {
            MqttLink.State.CONNECTING -> setStatus(PanelStatus.Link.CONNECTING, getString(R.string.status_connecting, host))
            MqttLink.State.CONNECTED -> setStatus(PanelStatus.Link.CONNECTED, getString(R.string.status_connected, host))
            MqttLink.State.RETRY -> setStatus(PanelStatus.Link.RETRY, getString(R.string.status_retry, describe(problem)))
        }
    }

    // ---------------------------------------------------------------- MQTT

    /** Discovery, then availability, then every current state (after each connect and after an HA restart). */
    private fun publishEverything() {
        val link = mqtt ?: return
        removeOldNodeId(link)
        for ((topic, payload) in Discovery.configs(this, topics, deviceName)) link.publish(topic, payload, retain = true)
        link.publish(topics.avail, "online", retain = true)
        publishLed()
        for (n in 1..2) link.publish(topics.relayState(n), onOff(relayOn[n]), retain = true)
        for (n in 1..2) inputOn[n]?.let { link.publish(topics.inputState(n), onOff(it), retain = true) }
        temperature?.let { publishTemperature(it) }
        humidity?.let { publishHumidity(it) }
        lux?.let { publishLux(it) }
    }

    /** After the node id was changed: empty retained configs make Home Assistant drop the old entities. */
    private fun removeOldNodeId(link: MqttLink) {
        val old = prefs.pendingCleanupNodeId
        // Only once the service really runs with the new id, and only while the broker is reachable.
        if (old.isEmpty() || topics.base != prefs.nodeId || !link.isConnected()) return
        if (old != topics.base) {
            for (topic in Discovery.configTopics(old)) link.publish(topic, "", retain = true)
            for (topic in Topics(old).retainedStates) link.publish(topic, "", retain = true)
        }
        prefs.pendingCleanupNodeId = ""
    }

    private fun handleMessage(topic: String, payload: String) {
        when (topic) {
            topics.ledSet -> handleLedCommand(payload)
            topics.relaySet(1) -> parseOnOff(payload)?.let { setRelay(1, it) }
            topics.relaySet(2) -> parseOnOff(payload)?.let { setRelay(2, it) }
            Topics.HA_STATUS -> if (payload.trim().equals("online", ignoreCase = true)) {
                // Home Assistant restarted: announce everything again after a short random pause.
                republishTask?.cancel(false)
                republishTask = worker.schedule(Runnable { safely { publishEverything() } }, (2L..6L).random(), TimeUnit.SECONDS)
            }
        }
    }

    // ---------------------------------------------------------------- LED

    private fun handleLedCommand(payload: String) {
        val before = intArrayOf(if (ledOn) 1 else 0, ledR, ledG, ledB, ledBrightness)
        val text = payload.trim()
        if (text.equals("ON", ignoreCase = true) || text.equals("OFF", ignoreCase = true)) {
            ledOn = text.equals("ON", ignoreCase = true)
        } else {
            val json = try {
                JSONObject(text)
            } catch (e: JSONException) {
                Log.w(TAG, "bad LED command: $text")
                return
            }
            val state = json.optString("state", "")
            ledOn = state.isEmpty() || !state.equals("OFF", ignoreCase = true)
            if (json.has("brightness")) ledBrightness = json.optInt("brightness", ledBrightness).coerceIn(0, 255)
            json.optJSONObject("color")?.let { c ->
                ledR = c.optInt("r", ledR).coerceIn(0, 255)
                ledG = c.optInt("g", ledG).coerceIn(0, 255)
                ledB = c.optInt("b", ledB).coerceIn(0, 255)
            }
            if (ledOn && ledBrightness == 0) ledBrightness = 255
        }
        if (!applyLed()) {
            // The driver refused: keep and report the previous state, so Home Assistant does not show a lie.
            ledOn = before[0] == 1
            ledR = before[1]
            ledG = before[2]
            ledB = before[3]
            ledBrightness = before[4]
            updateLedStatus()
            publishLed()
            return
        }
        prefs.saveLed(ledOn, ledR, ledG, ledB, ledBrightness)
        publishLed()
    }

    private fun applyLed(): Boolean {
        val ok = if (ledOn) {
            Hardware.setLed(ledR * ledBrightness / 255, ledG * ledBrightness / 255, ledB * ledBrightness / 255)
        } else {
            Hardware.setLed(0, 0, 0)
        }
        updateLedStatus()
        return ok
    }

    private fun updateLedStatus() {
        PanelStatus.ledOn = ledOn
        PanelStatus.ledColor = (ledR shl 16) or (ledG shl 8) or ledB
        PanelStatus.hardwareError = Hardware.ledError ?: Hardware.gpioError
    }

    /** State echo with color_mode and the unscaled colour, so Home Assistant shows the real colour and brightness. */
    private fun publishLed() {
        val json = JSONObject()
            .put("state", onOff(ledOn))
            .put("brightness", ledBrightness)
            .put("color_mode", "rgb")
            .put("color", JSONObject().put("r", ledR).put("g", ledG).put("b", ledB))
        mqtt?.publish(topics.ledState, json.toString(), retain = true)
    }

    private fun testLed() {
        for (c in listOf(intArrayOf(255, 0, 0), intArrayOf(0, 255, 0), intArrayOf(0, 0, 255), intArrayOf(255, 255, 255))) {
            Hardware.setLed(c[0], c[1], c[2])
            try {
                Thread.sleep(600)
            } catch (_: InterruptedException) {
                break
            }
        }
        applyLed()
    }

    // ---------------------------------------------------------------- relays and inputs

    private fun setRelay(n: Int, on: Boolean) {
        // If the GPIO driver fails the relay keeps its state, and that (unchanged) state is echoed back.
        if (Hardware.setRelay(n, on)) relayOn[n] = on
        publishRelayStatus()
        mqtt?.publish(topics.relayState(n), onOff(relayOn[n]), retain = true)
    }

    private fun publishRelayStatus() {
        PanelStatus.relay1 = relayOn[1]
        PanelStatus.relay2 = relayOn[2]
        PanelStatus.hardwareError = Hardware.ledError ?: Hardware.gpioError
    }

    private fun pollInputs() {
        var changed = false
        for (n in 1..2) {
            val value = Hardware.readInput(n) ?: continue
            val previous = inputOn[n]
            if (previous == value) continue
            inputOn[n] = value
            changed = true
            mqtt?.publish(topics.inputState(n), onOff(value), retain = true)
            // Original behaviour, now optional: a press on an input switches its relay on.
            if (value && previous != null && inputTriggersRelay) setRelay(n, true)
        }
        if (changed) {
            PanelStatus.inputs = "IO1: ${inputOn[1]?.let { onOff(it) } ?: "?"}, IO2: ${inputOn[2]?.let { onOff(it) } ?: "?"}"
        }
    }

    private fun restoreHardware() {
        ledOn = prefs.ledOn
        ledR = prefs.ledR
        ledG = prefs.ledG
        ledB = prefs.ledB
        ledBrightness = prefs.ledBrightness
        applyLed()
        // Relays always start switched off (as in the original app): a pulse load must never come back on by itself.
        for (n in 1..2) {
            Hardware.setRelay(n, false)
            relayOn[n] = false
        }
        publishRelayStatus()
    }

    // ---------------------------------------------------------------- sensors

    private fun onClimate(kind: ThsReader.Kind, raw: Double) {
        when (kind) {
            ThsReader.Kind.TEMPERATURE -> {
                if (raw < -40 || raw > 100) return
                val value = Math.round(raw * 2) / 2.0 // 0.5 °C steps, as before
                if (value != temperature) {
                    temperature = value
                    PanelStatus.temperature = value
                    publishTemperature(value)
                }
            }
            ThsReader.Kind.HUMIDITY -> {
                if (raw < 0 || raw > 100) return
                val value = raw.roundToInt()
                if (value != humidity) {
                    humidity = value
                    PanelStatus.humidity = value
                    publishHumidity(value)
                }
            }
        }
    }

    private fun publishTemperature(value: Double) {
        mqtt?.publish(topics.temperature, "{\"temperature\": " + String.format(Locale.US, "%.1f", value) + "}", retain = true)
    }

    private fun publishHumidity(value: Int) {
        mqtt?.publish(topics.humidity, "{\"humidity\": $value}", retain = true)
    }

    private fun onLux(value: Double) {
        val last = lux
        val significant = last == null || abs(value - last) >= max(5.0, last * 0.1)
        if (!significant) {
            luxPending = null
            return
        }
        val wait = luxSentAt + LUX_MIN_INTERVAL_MS - SystemClock.elapsedRealtime()
        if (wait <= 0) {
            sendLux(value)
            return
        }
        // Too soon: remember the newest value and send it when the interval is over.
        luxPending = value
        if (luxTask == null) {
            luxTask = worker.schedule(Runnable {
                safely {
                    luxTask = null
                    luxPending?.let { sendLux(it) }
                }
            }, wait, TimeUnit.MILLISECONDS)
        }
    }

    private fun sendLux(value: Double) {
        luxPending = null
        lux = value
        luxSentAt = SystemClock.elapsedRealtime()
        publishLux(value)
        PanelStatus.lux = String.format(Locale.US, "%.0f lx", value)
    }

    private fun publishLux(value: Double) {
        mqtt?.publish(topics.lux, "{\"lux\": " + String.format(Locale.US, "%.1f", value) + "}", retain = true)
    }

    // ---------------------------------------------------------------- notification and status

    @Synchronized
    private fun setStatus(link: PanelStatus.Link, text: String) {
        PanelStatus.link = link
        PanelStatus.linkText = text
        if (text == notificationText) return
        notificationText = text
        getSystemService(NotificationManager::class.java)?.notify(NOTIFICATION_ID, buildNotification(text))
    }

    /** false if Android refused (then the service stops instead of crash-looping). */
    private fun startInForeground(text: String): Boolean {
        notificationText = text
        val notification = buildNotification(text)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE)
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "startForeground refused", e)
            false
        }
    }

    private fun buildNotification(text: String): Notification {
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, SettingsActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_stat_panel)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .build()
    }

    private fun createChannel() {
        val channel = NotificationChannel(CHANNEL_ID, getString(R.string.channel_name), NotificationManager.IMPORTANCE_LOW)
        channel.setShowBadge(false)
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    // ---------------------------------------------------------------- network

    private fun registerNetworkCallback() {
        val cm = getSystemService(ConnectivityManager::class.java) ?: return
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                exec { mqtt?.kick() }
            }
        }
        try {
            cm.registerDefaultNetworkCallback(callback)
            networkCallback = callback
        } catch (e: Exception) {
            Log.w(TAG, "network callback: $e")
        }
    }

    private fun unregisterNetworkCallback() {
        val callback = networkCallback ?: return
        networkCallback = null
        try {
            getSystemService(ConnectivityManager::class.java)?.unregisterNetworkCallback(callback)
        } catch (_: Exception) {
        }
    }

    // ---------------------------------------------------------------- helpers

    private fun exec(block: () -> Unit) {
        try {
            worker.execute { safely(block) }
        } catch (_: RejectedExecutionException) {
        }
    }

    private inline fun safely(block: () -> Unit) {
        try {
            block()
        } catch (t: Throwable) {
            Log.e(TAG, "worker", t)
        }
    }

    private fun describe(problem: MqttLink.Problem?): String {
        if (problem == null) return getString(R.string.reason_lost)
        val text = when (problem.reason) {
            MqttLink.Reason.AUTH -> getString(R.string.reason_auth)
            MqttLink.Reason.UNREACHABLE -> getString(R.string.reason_unreachable)
            MqttLink.Reason.NO_ANSWER -> getString(R.string.reason_no_answer)
            MqttLink.Reason.REJECTED -> getString(R.string.reason_rejected)
            MqttLink.Reason.LOST -> getString(R.string.reason_lost)
            MqttLink.Reason.OTHER -> return problem.detail.ifEmpty { getString(R.string.reason_lost) }
        }
        return if (problem.detail.isNotEmpty() && problem.reason == MqttLink.Reason.UNREACHABLE) "$text (${problem.detail})" else text
    }

    private fun onOff(on: Boolean) = if (on) "ON" else "OFF"

    /** Only an explicit ON/OFF switches a relay; anything else (empty, garbage) is ignored. */
    private fun parseOnOff(payload: String): Boolean? = when (payload.trim().uppercase(Locale.ROOT)) {
        "ON", "1", "TRUE" -> true
        "OFF", "0", "FALSE" -> false
        else -> null
    }
}
