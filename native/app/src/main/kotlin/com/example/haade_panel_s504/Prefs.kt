package com.example.haade_panel_s504

import android.content.Context
import android.content.SharedPreferences
import java.security.SecureRandom

/** Settings and the last hardware state (restored after a reboot). */
class Prefs(context: Context) {
    private val appContext = context.applicationContext
    private val sp: SharedPreferences = appContext.getSharedPreferences("panel", Context.MODE_PRIVATE)

    // ---- MQTT broker
    var host: String
        get() = sp.getString("host", BuildConfig.DEFAULT_HOST).orEmpty()
        set(v) { sp.edit().putString("host", v).apply() }

    var port: Int
        get() = sp.getInt("port", 1883)
        set(v) { sp.edit().putInt("port", v).apply() }

    var user: String
        get() = sp.getString("user", BuildConfig.DEFAULT_USER).orEmpty()
        set(v) { sp.edit().putString("user", v).apply() }

    var pass: String
        get() = sp.getString("pass", "").orEmpty()
        set(v) { sp.edit().putString("pass", v).apply() }

    var tls: Boolean
        get() = sp.getBoolean("tls", false)
        set(v) { sp.edit().putBoolean("tls", v).apply() }

    // ---- Home Assistant identity
    /** Topic prefix and unique_id base. The default keeps the original app's entities. */
    var nodeId: String
        get() = Topics.sanitize(sp.getString("node_id", Topics.DEFAULT_BASE).orEmpty()).ifEmpty { Topics.DEFAULT_BASE }
        set(v) { sp.edit().putString("node_id", v).apply() }

    /** Old node id whose discovery configs still have to be removed from the broker. */
    var pendingCleanupNodeId: String
        get() = sp.getString("cleanup_node_id", "").orEmpty()
        set(v) { sp.edit().putString("cleanup_node_id", v).apply() }

    /** Empty = the localised default ("Wall Panel" / "Настенная панель" / "Panneau mural"). */
    var deviceNameRaw: String
        get() = sp.getString("device_name", "").orEmpty()
        set(v) { sp.edit().putString("device_name", v.trim()).apply() }

    val deviceName: String
        get() = deviceNameRaw.ifBlank { appContext.getString(R.string.device_name_default) }

    // ---- features
    var thsEnabled: Boolean
        get() = sp.getBoolean("ths", true)
        set(v) { sp.edit().putBoolean("ths", v).apply() }

    var ioEnabled: Boolean
        get() = sp.getBoolean("io", false)
        set(v) { sp.edit().putBoolean("io", v).apply() }

    var ioTriggersRelay: Boolean
        get() = sp.getBoolean("io_relay", false)
        set(v) { sp.edit().putBoolean("io_relay", v).apply() }

    var luxEnabled: Boolean
        get() = sp.getBoolean("lux", false)
        set(v) { sp.edit().putBoolean("lux", v).apply() }

    // ---- startup
    var autostart: Boolean
        get() = sp.getBoolean("autostart", true)
        set(v) { sp.edit().putBoolean("autostart", v).apply() }

    var watchdog: Boolean
        get() = sp.getBoolean("watchdog", true)
        set(v) { sp.edit().putBoolean("watchdog", v).apply() }

    /** Stable client id: a reconnect replaces a half-open old session instead of adding a second one. */
    val clientId: String
        get() = sp.getString("client_id", null) ?: run {
            val bytes = ByteArray(4).also { SecureRandom().nextBytes(it) }
            val id = "panellink_" + bytes.joinToString("") { "%02x".format(it) }
            sp.edit().putString("client_id", id).apply()
            id
        }

    val isConfigured: Boolean
        get() = host.isNotBlank()

    // ---- last hardware state
    val ledOn: Boolean get() = sp.getBoolean("led_on", false)
    val ledR: Int get() = sp.getInt("led_r", 255)
    val ledG: Int get() = sp.getInt("led_g", 255)
    val ledB: Int get() = sp.getInt("led_b", 255)
    val ledBrightness: Int get() = sp.getInt("led_brightness", 255)

    fun saveLed(on: Boolean, r: Int, g: Int, b: Int, brightness: Int) {
        sp.edit()
            .putBoolean("led_on", on)
            .putInt("led_r", r)
            .putInt("led_g", g)
            .putInt("led_b", b)
            .putInt("led_brightness", brightness)
            .apply()
    }

}
