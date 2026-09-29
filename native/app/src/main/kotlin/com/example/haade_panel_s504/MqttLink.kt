package com.example.haade_panel_s504

import android.util.Log
import org.eclipse.paho.client.mqttv3.IMqttActionListener
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken
import org.eclipse.paho.client.mqttv3.IMqttToken
import org.eclipse.paho.client.mqttv3.MqttAsyncClient
import org.eclipse.paho.client.mqttv3.MqttCallbackExtended
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.eclipse.paho.client.mqttv3.MqttException
import org.eclipse.paho.client.mqttv3.MqttMessage
import org.eclipse.paho.client.mqttv3.ScheduledExecutorPingSender
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLSocketFactory
import kotlin.random.Random

/**
 * One MQTT connection that never gives up.
 *
 * The original app's client never dropped a connection whose keep-alive pings went unanswered, so
 * after a network or broker hiccup it could stay "connected" to nothing. Here:
 * - keep-alive (30 s) drops a dead link within about a minute;
 * - every failure path schedules the next attempt (1, 2, 4 … 30 s plus jitter);
 * - connect and subscribe have deadlines (Paho's connectionTimeout covers only the TCP handshake,
 *   a broker that accepts the socket but never sends CONNACK would otherwise hang it forever);
 * - a supervisor re-checks every minute and a network callback triggers an immediate retry;
 * - after *every* connect the command topics are subscribed again before the panel reports "online";
 * - retained messages on command topics are ignored, so a stale retained "ON" can never switch
 *   a relay on each reconnect.
 *
 * All connection bookkeeping runs on one control thread; [publish] may be called from any thread.
 */
class MqttLink(private val cfg: Config, private val listener: Listener) {

    data class Config(
        val host: String,
        val port: Int,
        val user: String,
        val pass: String,
        val tls: Boolean,
        val clientId: String,
        val topics: Topics,
    ) {
        val uri: String get() = (if (tls) "ssl://" else "tcp://") + host.trim() + ":" + port
    }

    enum class State { CONNECTING, CONNECTED, RETRY }

    /** Why the last attempt failed; the service turns it into a localised text. */
    enum class Reason { AUTH, UNREACHABLE, NO_ANSWER, REJECTED, LOST, OTHER }

    data class Problem(val reason: Reason, val detail: String = "")

    interface Listener {
        /** Connected and subscribed: publish discovery, availability and current states now. */
        fun onReady()
        fun onMessage(topic: String, payload: String)
        fun onState(state: State, problem: Problem?)
    }

    private val ctl: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "mqtt-ctl").apply { isDaemon = true }
    }

    // Keep-alive pings on a monotonic scheduler (java.util.Timer would stall if the wall clock jumps back).
    private val pinger: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "mqtt-ping").apply { isDaemon = true }
    }

    private val subscriptions = arrayOf(cfg.topics.ledSet, cfg.topics.relaySet(1), cfg.topics.relaySet(2), Topics.HA_STATUS)

    @Volatile private var client: MqttAsyncClient? = null
    @Volatile private var stopped = false
    private var connecting = false
    private var ready = false
    private var retry: ScheduledFuture<*>? = null
    private var deadline: ScheduledFuture<*>? = null
    private var backoffSec = 1L

    fun start() {
        post { connectNow() }
        // Safety net: if nothing is connected, connecting or scheduled, try again.
        ctl.scheduleWithFixedDelay({
            try {
                if (!stopped && !connecting && retry == null && !isConnected()) connectNow()
            } catch (t: Throwable) {
                Log.e(TAG, "supervisor", t)
            }
        }, 60, 60, TimeUnit.SECONDS)
    }

    /** The network came back: retry now instead of waiting out the backoff. */
    fun kick() = post {
        if (!stopped && !connecting && !isConnected()) {
            retry?.cancel(false)
            retry = null
            backoffSec = 1
            connectNow()
        }
    }

    fun isConnected(): Boolean = client?.isConnected == true

    fun publish(topic: String, payload: String, retain: Boolean) {
        val c = client ?: return
        try {
            if (c.isConnected) c.publish(topic, payload.toByteArray(Charsets.UTF_8), 1, retain)
        } catch (e: Exception) {
            Log.w(TAG, "publish $topic: ${e.message}")
        }
    }

    /** Blocks up to a few seconds: optionally announces "offline", then closes the connection. */
    fun stop(publishOffline: Boolean) {
        stopped = true
        val done = try {
            ctl.submit(Runnable {
                retry?.cancel(false)
                retry = null
                deadline?.cancel(false)
                deadline = null
                client?.let { c ->
                    client = null
                    shutdown(c, publishOffline)
                }
            })
        } catch (e: RejectedExecutionException) {
            null
        }
        try {
            done?.get(6, TimeUnit.SECONDS)
        } catch (_: Exception) {
        }
        ctl.shutdownNow()
        pinger.shutdownNow()
    }

    private fun connectNow() {
        if (stopped || connecting || isConnected()) return
        retry = null
        val c = client ?: try {
            MqttAsyncClient(cfg.uri, cfg.clientId, MemoryPersistence(), ScheduledExecutorPingSender(pinger)).also { created ->
                created.setCallback(callbackFor(created))
                client = created
            }
        } catch (e: Exception) {
            scheduleRetry(describe(e))
            return
        }
        val options = MqttConnectOptions().apply {
            isCleanSession = true
            keepAliveInterval = KEEP_ALIVE_SEC
            connectionTimeout = 10
            isAutomaticReconnect = false
            maxInflight = 64
            // MQTT 3.1.1 allows a password only together with a user name.
            if (cfg.user.isNotEmpty()) {
                userName = cfg.user
                if (cfg.pass.isNotEmpty()) password = cfg.pass.toCharArray()
            }
            setWill(cfg.topics.avail, OFFLINE, 1, true)
            if (cfg.tls) socketFactory = SSLSocketFactory.getDefault()
        }
        connecting = true
        ready = false
        listener.onState(State.CONNECTING, null)
        try {
            c.connect(options, null, object : IMqttActionListener {
                override fun onSuccess(token: IMqttToken?) = post {
                    if (client !== c || !connecting) return@post
                    connecting = false
                    subscribeAll(c)
                }

                override fun onFailure(token: IMqttToken?, e: Throwable?) = post {
                    if (client !== c) return@post
                    connecting = false
                    restart(c, describe(e))
                }
            })
            armDeadline(c, CONNECT_DEADLINE_SEC, Problem(Reason.NO_ANSWER, "CONNACK")) { connecting }
        } catch (e: Exception) {
            connecting = false
            restart(c, describe(e))
        }
    }

    private fun subscribeAll(c: MqttAsyncClient) {
        if (stopped) return
        try {
            c.subscribe(subscriptions, IntArray(subscriptions.size) { 1 }, null, object : IMqttActionListener {
                override fun onSuccess(token: IMqttToken?) = post {
                    if (stopped || client !== c || ready) return@post
                    // 0x80 = refused by the broker ACL. Fatal only for the command topics;
                    // homeassistant/status is a nice-to-have.
                    val granted = token?.grantedQos
                    if (granted != null && granted.take(COMMAND_TOPICS).any { it == 0x80 }) {
                        restart(c, Problem(Reason.REJECTED))
                        return@post
                    }
                    if (granted != null && granted.drop(COMMAND_TOPICS).any { it == 0x80 }) {
                        Log.w(TAG, "broker refused ${Topics.HA_STATUS}; Home Assistant restarts will not trigger a re-announce")
                    }
                    ready = true
                    deadline?.cancel(false)
                    deadline = null
                    backoffSec = 1
                    listener.onState(State.CONNECTED, null)
                    listener.onReady()
                }

                override fun onFailure(token: IMqttToken?, e: Throwable?) = post {
                    if (client === c) restart(c, describe(e))
                }
            })
            armDeadline(c, SUBSCRIBE_DEADLINE_SEC, Problem(Reason.NO_ANSWER, "SUBACK")) { !ready }
        } catch (e: Exception) {
            restart(c, describe(e))
        }
    }

    /** If [stillWaiting] is true after [seconds], this attempt is dead: drop the client and retry. */
    private fun armDeadline(c: MqttAsyncClient, seconds: Long, reason: Problem, stillWaiting: () -> Boolean) {
        deadline?.cancel(false)
        deadline = try {
            ctl.schedule(Runnable {
                if (!stopped && client === c && stillWaiting()) restart(c, reason)
            }, seconds, TimeUnit.SECONDS)
        } catch (e: RejectedExecutionException) {
            null
        }
    }

    private fun callbackFor(c: MqttAsyncClient) = object : MqttCallbackExtended {
        override fun connectComplete(reconnect: Boolean, serverURI: String?) {}

        override fun connectionLost(cause: Throwable?) = post {
            if (client === c) restart(c, describe(cause))
        }

        override fun messageArrived(topic: String, message: MqttMessage) {
            // A retained command is old news (and would re-fire on every reconnect).
            if (message.isRetained && topic != Topics.HA_STATUS) return
            listener.onMessage(topic, String(message.payload, Charsets.UTF_8))
        }

        override fun deliveryComplete(token: IMqttDeliveryToken?) {}
    }

    /** Drops the client completely (fresh threads and state next time) and schedules a retry. */
    private fun restart(c: MqttAsyncClient, reason: Problem) {
        if (client === c) client = null
        connecting = false
        ready = false
        deadline?.cancel(false)
        deadline = null
        shutdown(c, publishOffline = false)
        scheduleRetry(reason)
    }

    private fun scheduleRetry(reason: Problem) {
        if (stopped) return
        Log.i(TAG, "retry in ~${backoffSec}s: ${reason.reason} ${reason.detail}")
        listener.onState(State.RETRY, reason)
        retry?.cancel(false)
        // Up to +25 % jitter so several panels do not hammer a restarting broker in lockstep.
        val delayMs = backoffSec * 1000 + Random.nextLong(backoffSec * 250 + 1)
        backoffSec = (backoffSec * 2).coerceAtMost(MAX_BACKOFF_SEC)
        retry = try {
            ctl.schedule(Runnable {
                retry = null
                try {
                    connectNow()
                } catch (t: Throwable) {
                    Log.e(TAG, "connect", t)
                }
            }, delayMs, TimeUnit.MILLISECONDS)
        } catch (e: RejectedExecutionException) {
            null
        }
    }

    private fun shutdown(c: MqttAsyncClient, publishOffline: Boolean) {
        try {
            if (publishOffline && c.isConnected) c.publish(cfg.topics.avail, OFFLINE, 1, true).waitForCompletion(2000)
        } catch (_: Exception) {
        }
        try {
            if (c.isConnected) c.disconnect(0).waitForCompletion(2000)
        } catch (_: Exception) {
        }
        try {
            c.disconnectForcibly(0, 500)
        } catch (_: Exception) {
        }
        try {
            c.close()
        } catch (_: Exception) {
        }
    }

    private fun post(block: () -> Unit) {
        try {
            ctl.execute {
                try {
                    block()
                } catch (t: Throwable) {
                    Log.e(TAG, "mqtt-ctl", t)
                }
            }
        } catch (_: RejectedExecutionException) {
        }
    }

    companion object {
        private const val TAG = "PanelMqtt"
        private const val KEEP_ALIVE_SEC = 30
        private const val CONNECT_DEADLINE_SEC = 25L
        private const val SUBSCRIBE_DEADLINE_SEC = 20L
        private const val MAX_BACKOFF_SEC = 30L
        private const val COMMAND_TOPICS = 3
        private val OFFLINE = "offline".toByteArray()

        fun describe(e: Throwable?): Problem = when (e) {
            null -> Problem(Reason.LOST)
            is MqttException -> when (e.reasonCode) {
                MqttException.REASON_CODE_FAILED_AUTHENTICATION.toInt(),
                MqttException.REASON_CODE_NOT_AUTHORIZED.toInt() -> Problem(Reason.AUTH)
                MqttException.REASON_CODE_SERVER_CONNECT_ERROR.toInt() -> Problem(Reason.UNREACHABLE, e.cause?.message.orEmpty())
                MqttException.REASON_CODE_CLIENT_TIMEOUT.toInt() -> Problem(Reason.NO_ANSWER)
                MqttException.REASON_CODE_CONNECTION_LOST.toInt() -> Problem(Reason.LOST, e.cause?.message.orEmpty())
                else -> Problem(Reason.OTHER, e.cause?.message ?: e.message ?: "MQTT ${e.reasonCode}")
            }
            else -> Problem(Reason.OTHER, e.message ?: e.javaClass.simpleName)
        }
    }
}
