package com.example.haade_panel_s504

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Home Assistant MQTT discovery. With the default node id the config topics and unique_ids are the
 * same as in the original app, so Home Assistant keeps the same entities and entity_ids; only the
 * shown names change (device name is configurable, entity names are localised).
 */
object Discovery {

    fun configs(context: Context, topics: Topics, deviceName: String): List<Pair<String, String>> {
        val id = topics.base
        val device = JSONObject()
            .put("identifiers", JSONArray().put(id))
            .put("name", deviceName)
            .put("model", "SMT101")
            .put("manufacturer", "PanelLink")
            .put("sw_version", BuildConfig.VERSION_NAME)
        val origin = JSONObject()
            .put("name", context.getString(R.string.app_name))
            .put("sw_version", BuildConfig.VERSION_NAME)
            .put("support_url", "https://github.com/haade-administrator/haade_panel_s504")

        fun entity(name: String, uniqueId: String) = JSONObject()
            .put("name", name)
            .put("unique_id", uniqueId)
            .put("availability_topic", topics.avail)
            .put("qos", 1)
            .put("device", device)
            .put("origin", origin)

        val list = mutableListOf<Pair<String, JSONObject>>()
        list += configTopic("light", "${id}_led") to entity(context.getString(R.string.entity_led), "${id}_led")
            .put("schema", "json")
            .put("state_topic", topics.ledState)
            .put("command_topic", topics.ledSet)
            .put("brightness", true)
            .put("brightness_scale", 255)
            .put("supported_color_modes", JSONArray().put("rgb"))
            // The driver has neither flash nor fades: do not let Home Assistant offer them.
            .put("flash", false)
            .put("transition", false)
        for (n in 1..2) {
            list += configTopic("switch", "${id}_relay$n") to entity(context.getString(R.string.entity_relay, n), "${id}_relay_$n")
                .put("state_topic", topics.relayState(n))
                .put("command_topic", topics.relaySet(n))
                .put("payload_on", "ON")
                .put("payload_off", "OFF")
        }
        for (n in 1..2) {
            list += configTopic("binary_sensor", "${id}_io$n") to entity(context.getString(R.string.entity_input, n), "${id}_io$n")
                .put("state_topic", topics.inputState(n))
                .put("payload_on", "ON")
                .put("payload_off", "OFF")
                .put("device_class", "occupancy")
                .put("enabled_by_default", false)
        }
        list += configTopic("sensor", "${id}_temperature") to entity(context.getString(R.string.entity_temperature), "${id}_temperature")
            .put("state_topic", topics.temperature)
            .put("value_template", "{{ value_json.temperature }}")
            .put("device_class", "temperature")
            .put("state_class", "measurement")
            .put("unit_of_measurement", "°C")
        list += configTopic("sensor", "${id}_humidity") to entity(context.getString(R.string.entity_humidity), "${id}_humidity")
            .put("state_topic", topics.humidity)
            .put("value_template", "{{ value_json.humidity }}")
            .put("device_class", "humidity")
            .put("state_class", "measurement")
            .put("unit_of_measurement", "%")
        list += configTopic("sensor", "${id}_lux") to entity(context.getString(R.string.entity_lux), "${id}_lux")
            .put("state_topic", topics.lux)
            .put("value_template", "{{ value_json.lux }}")
            .put("device_class", "illuminance")
            .put("state_class", "measurement")
            .put("unit_of_measurement", "lx")
            .put("enabled_by_default", false)
        return list.map { (topic, json) -> topic to json.toString() }
    }

    /** Config topics of a node id — used to remove a panel's old entities after its id was changed. */
    fun configTopics(id: String): List<String> = listOf(
        configTopic("light", "${id}_led"),
        configTopic("switch", "${id}_relay1"),
        configTopic("switch", "${id}_relay2"),
        configTopic("binary_sensor", "${id}_io1"),
        configTopic("binary_sensor", "${id}_io2"),
        configTopic("sensor", "${id}_temperature"),
        configTopic("sensor", "${id}_humidity"),
        configTopic("sensor", "${id}_lux"),
    )

    private fun configTopic(component: String, objectId: String) = "homeassistant/$component/$objectId/config"
}
