package com.example.haade_panel_s504

/**
 * MQTT topics of one panel. The base ("node id") is configurable so several panels can share a broker
 * (upstream issue #3). The default keeps the original app's topics, so existing Home Assistant entities
 * stay exactly as they are.
 */
class Topics(val base: String) {
    val avail = "$base/availability"
    val ledState = "$base/led/state"
    val ledSet = "$base/led/set"
    val temperature = "$base/sensor/temperature"
    val humidity = "$base/sensor/humidity"
    val lux = "$base/sensor/lux"

    fun relayState(n: Int) = "$base/switch/relay$n/state"
    fun relaySet(n: Int) = "$base/switch/relay$n/set"
    fun inputState(n: Int) = "$base/binary_sensor/io$n/state"

    /** Everything this panel keeps retained on the broker (cleared when the node id changes). */
    val retainedStates: List<String>
        get() = listOf(avail, ledState, relayState(1), relayState(2), inputState(1), inputState(2), temperature, humidity, lux)

    companion object {
        const val DEFAULT_BASE = "haade_panel_s504"
        const val HA_STATUS = "homeassistant/status"

        /** Lower-case letters, digits, "_" and "-": safe for topics and Home Assistant object ids. */
        fun sanitize(raw: String): String =
            raw.trim().lowercase().replace(Regex("[^a-z0-9_-]+"), "_").trim('_', '-').take(48)
    }
}
