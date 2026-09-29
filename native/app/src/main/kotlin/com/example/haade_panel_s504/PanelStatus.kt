package com.example.haade_panel_s504

/** Live status for the settings screen (written by the service, read by the activity). */
object PanelStatus {
    enum class Link { NOT_CONFIGURED, CONNECTING, CONNECTED, RETRY }

    @Volatile var link = Link.NOT_CONFIGURED
    @Volatile var linkText = ""
    @Volatile var ledOn = false
    @Volatile var ledColor = 0xFFFFFF
    @Volatile var relay1 = false
    @Volatile var relay2 = false
    @Volatile var temperature: Double? = null
    @Volatile var humidity: Int? = null
    @Volatile var lux: String = ""
    @Volatile var inputs: String = ""
    @Volatile var sensorSource: String = ""
    @Volatile var hardwareError: String? = null

    fun resetConnection() {
        link = Link.NOT_CONFIGURED
        linkText = ""
        lux = ""
        inputs = ""
        sensorSource = ""
    }
}
