package com.example.haade_panel_s504

import android.Manifest
import android.app.Activity
import android.app.LocaleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.LocaleList
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView
import android.widget.Toast
import java.util.Locale

/** Settings and live status. Needed only for setup — the service runs without this screen. */
class SettingsActivity : Activity() {

    private object C {
        const val BG = 0xFF0E1216.toInt()
        const val CARD = 0xFF172029.toInt()
        const val CARD_STROKE = 0xFF212C37.toInt()
        const val FIELD = 0xFF0F151B.toInt()
        const val FIELD_STROKE = 0xFF2A3642.toInt()
        const val TEXT = 0xFFECEFF1.toInt()
        const val DIM = 0xFF8FA3B0.toInt()
        const val HINT = 0xFF5B6E7C.toInt()
        const val ACCENT = 0xFF4FC3F7.toInt()
        const val ON_ACCENT = 0xFF05202B.toInt()
        const val GREEN = 0xFF66BB6A.toInt()
        const val ORANGE = 0xFFFFA726.toInt()
        const val RED = 0xFFEF5350.toInt()
        const val GREY = 0xFF78909C.toInt()
    }

    private lateinit var prefs: Prefs
    private lateinit var host: EditText
    private lateinit var port: EditText
    private lateinit var user: EditText
    private lateinit var pass: EditText
    private lateinit var tls: Switch
    private lateinit var nodeId: EditText
    private lateinit var deviceName: EditText
    private lateinit var ths: Switch
    private lateinit var inputs: Switch
    private lateinit var inputRelay: Switch
    private lateinit var lux: Switch
    private lateinit var autostart: Switch
    private lateinit var watchdog: Switch

    // live views
    private lateinit var pillDot: View
    private lateinit var pillText: TextView
    private lateinit var tileMqtt: TextView
    private lateinit var tileTemp: TextView
    private lateinit var tileHum: TextView
    private lateinit var tileLed: TextView
    private lateinit var ledSwatch: View
    private lateinit var tileRelays: TextView
    private lateinit var tileService: TextView
    private lateinit var details: TextView
    private lateinit var batteryText: TextView
    private lateinit var batteryButton: Button
    private var hibernationText: TextView? = null
    private var hibernationButton: Button? = null

    private val handler = Handler(Looper.getMainLooper())
    private val ticker = object : Runnable {
        override fun run() {
            render()
            handler.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = Prefs(this)
        window.statusBarColor = C.BG
        window.navigationBarColor = C.BG

        val content = vertical().apply { setPadding(dp(24), dp(20), dp(24), dp(28)) }
        content.addView(header())

        val wide = resources.configuration.screenWidthDp >= 840
        val left = vertical()
        val right = vertical()
        left.addView(statusCard())
        right.addView(mqttCard())
        right.addView(deviceCard())
        right.addView(featuresCard())
        left.addView(startupCard())
        if (Build.VERSION.SDK_INT >= 33) left.addView(languageCard())

        if (wide) {
            val columns = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            columns.addView(left, LinearLayout.LayoutParams(0, WRAP, 1f).apply { marginEnd = dp(10) })
            columns.addView(right, LinearLayout.LayoutParams(0, WRAP, 1f).apply { marginStart = dp(10) })
            content.addView(columns)
        } else {
            content.addView(left)
            content.addView(right)
        }
        content.addView(actions())

        setContentView(ScrollView(this).apply {
            setBackgroundColor(C.BG)
            isFillViewport = true
            addView(content)
        })

        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1)
        }
    }

    override fun onResume() {
        super.onResume()
        PanelService.start(this)
        handler.post(ticker)
    }

    override fun onPause() {
        handler.removeCallbacks(ticker)
        super.onPause()
    }

    // ---------------------------------------------------------------- sections

    private fun header(): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(4), 0, dp(4), dp(18))
        }
        row.addView(ImageView(this).apply { setImageResource(R.mipmap.ic_launcher) }, LinearLayout.LayoutParams(dp(52), dp(52)))
        val titles = vertical().apply { setPadding(dp(14), 0, 0, 0) }
        titles.addView(label(getString(R.string.app_name), 26f, C.TEXT, bold = true))
        titles.addView(label(getString(R.string.app_tagline) + " · v" + BuildConfig.VERSION_NAME, 13f, C.DIM))
        row.addView(titles, LinearLayout.LayoutParams(0, WRAP, 1f))

        val pill = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = rounded(C.CARD, dp(20), C.CARD_STROKE)
            setPadding(dp(14), dp(8), dp(16), dp(8))
        }
        pillDot = View(this).apply { background = oval(C.GREY) }
        pill.addView(pillDot, LinearLayout.LayoutParams(dp(10), dp(10)).apply { marginEnd = dp(10) })
        pillText = label("", 14f, C.TEXT, bold = true)
        pill.addView(pillText)
        row.addView(pill)
        return row
    }

    private fun statusCard(): View {
        val card = card(R.string.section_status)
        val row1 = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        tileMqtt = tile(row1, R.string.tile_mqtt)
        tileService = tile(row1, R.string.tile_service)
        card.addView(row1)
        val row2 = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        tileTemp = tile(row2, R.string.tile_temperature)
        tileHum = tile(row2, R.string.tile_humidity)
        card.addView(row2)
        val row3 = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        tileLed = tile(row3, R.string.tile_led, withSwatch = true)
        tileRelays = tile(row3, R.string.tile_relays)
        card.addView(row3)
        details = label("", 12.5f, C.DIM).apply {
            setPadding(dp(4), dp(10), dp(4), 0)
            setTextIsSelectable(true)
        }
        card.addView(details)
        return wrap(card)
    }

    private fun mqttCard(): View {
        val card = card(R.string.section_mqtt)
        val row = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
        val hostBox = vertical()
        host = field(hostBox, R.string.label_host, prefs.host, InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_URI, "192.168.1.10")
        row.addView(hostBox, LinearLayout.LayoutParams(0, WRAP, 2.2f).apply { marginEnd = dp(10) })
        val portBox = vertical()
        port = field(portBox, R.string.label_port, prefs.port.toString(), InputType.TYPE_CLASS_NUMBER, "1883")
        row.addView(portBox, LinearLayout.LayoutParams(0, WRAP, 1f))
        card.addView(row)
        user = field(card, R.string.label_user, prefs.user, InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS)
        pass = field(card, R.string.label_pass, prefs.pass, InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD)
        tls = switchRow(card, R.string.tls, R.string.tls_desc, prefs.tls)
        return wrap(card)
    }

    private fun deviceCard(): View {
        val card = card(R.string.section_device)
        deviceName = field(
            card, R.string.label_device_name, prefs.deviceNameRaw,
            InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES, getString(R.string.device_name_default),
        )
        card.addView(note(R.string.device_name_desc))
        nodeId = field(card, R.string.label_node_id, prefs.nodeId, InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS, Topics.DEFAULT_BASE)
        card.addView(note(R.string.node_id_desc))
        return wrap(card)
    }

    private fun featuresCard(): View {
        val card = card(R.string.section_features)
        ths = switchRow(card, R.string.feature_ths, R.string.feature_ths_desc, prefs.thsEnabled)
        inputs = switchRow(card, R.string.feature_io, R.string.feature_io_desc, prefs.ioEnabled)
        inputRelay = switchRow(card, R.string.feature_io_relay, R.string.feature_io_relay_desc, prefs.ioTriggersRelay)
        lux = switchRow(card, R.string.feature_lux, R.string.feature_lux_desc, prefs.luxEnabled)
        inputRelay.isEnabled = inputs.isChecked
        inputs.setOnCheckedChangeListener { _, checked -> inputRelay.isEnabled = checked }
        return wrap(card)
    }

    private fun startupCard(): View {
        val card = card(R.string.section_startup)
        autostart = switchRow(card, R.string.startup_autostart, R.string.startup_autostart_desc, prefs.autostart)
        watchdog = switchRow(card, R.string.startup_watchdog, R.string.startup_watchdog_desc, prefs.watchdog)
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(10), 0, dp(4))
        }
        val texts = vertical()
        texts.addView(label(getString(R.string.startup_battery), 16f, C.TEXT))
        batteryText = label("", 12.5f, C.DIM)
        texts.addView(batteryText)
        row.addView(texts, LinearLayout.LayoutParams(0, WRAP, 1f))
        batteryButton = secondaryButton(R.string.btn_battery) { requestBatteryExemption() }
        row.addView(batteryButton)
        card.addView(row)

        // Android 11+ may "hibernate" apps that are not opened for months; that would also stop the boot start.
        if (Build.VERSION.SDK_INT >= 30) {
            val hib = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding(0, dp(12), 0, dp(4))
            }
            val hibTexts = vertical()
            hibTexts.addView(label(getString(R.string.startup_hibernation), 16f, C.TEXT))
            hibernationText = label("", 12.5f, C.DIM).also { hibTexts.addView(it) }
            hib.addView(hibTexts, LinearLayout.LayoutParams(0, WRAP, 1f).apply { marginEnd = dp(12) })
            hibernationButton = secondaryButton(R.string.btn_open) { openHibernationSettings() }.also { hib.addView(it) }
            card.addView(hib)
        }
        return wrap(card)
    }

    private fun openHibernationSettings() {
        val pkg = Uri.parse("package:$packageName")
        try {
            startActivity(Intent(Intent.ACTION_AUTO_REVOKE_PERMISSIONS, pkg))
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg))
            } catch (_: Exception) {
            }
        }
    }

    private fun isHibernationExempt(): Boolean =
        Build.VERSION.SDK_INT < 30 || packageManager.isAutoRevokeWhitelisted

    private fun languageCard(): View {
        val card = card(R.string.section_language)
        val lm = getSystemService(LocaleManager::class.java)
        val current = lm?.applicationLocales?.toLanguageTags().orEmpty()
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(6), 0, dp(2))
        }
        val options = listOf("" to getString(R.string.language_system), "ru" to "Русский", "en" to "English", "fr" to "Français")
        for ((tag, name) in options) {
            val selected = if (tag.isEmpty()) current.isEmpty() else current.startsWith(tag)
            val chip = label(name, 14f, if (selected) C.ON_ACCENT else C.TEXT, bold = selected).apply {
                gravity = Gravity.CENTER
                background = pressable(rounded(if (selected) C.ACCENT else C.FIELD, dp(12), if (selected) null else C.FIELD_STROKE))
                setPadding(dp(8), dp(12), dp(8), dp(12))
                setOnClickListener {
                    if (!selected && lm != null) {
                        lm.applicationLocales = if (tag.isEmpty()) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(tag)
                        // Entity names in Home Assistant follow the language: publish them again.
                        PanelService.start(this@SettingsActivity, PanelService.ACTION_RELOAD)
                    }
                }
            }
            row.addView(chip, LinearLayout.LayoutParams(0, WRAP, 1f).apply { marginEnd = dp(8) })
        }
        card.addView(row)
        return wrap(card)
    }

    private fun actions(): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(18), 0, 0)
        }
        row.addView(primaryButton(R.string.btn_save) { save() }, LinearLayout.LayoutParams(0, WRAP, 1.4f).apply { marginEnd = dp(10) })
        row.addView(secondaryButton(R.string.btn_test_led) { PanelService.start(this, PanelService.ACTION_TEST_LED) },
            LinearLayout.LayoutParams(0, WRAP, 1f).apply { marginEnd = dp(10) })
        row.addView(secondaryButton(R.string.btn_close) { finish() }, LinearLayout.LayoutParams(0, WRAP, 0.8f))
        return row
    }

    // ---------------------------------------------------------------- behaviour

    private fun save() {
        var hostText = host.text.toString().trim()
        val scheme = hostText.substringBefore("://", "").lowercase(Locale.ROOT)
        if (scheme == "ssl" || scheme == "mqtts") tls.isChecked = true
        hostText = hostText.substringAfter("://").trimEnd('/')
        if (hostText.count { it == ':' } == 1) {
            val embeddedPort = hostText.substringAfter(':').toIntOrNull()
            if (embeddedPort != null) {
                port.setText(embeddedPort.toString())
                hostText = hostText.substringBefore(':')
            }
        }
        if (hostText.any { it.isWhitespace() || it == '/' || it == '@' }) {
            toast(R.string.bad_host)
            return
        }
        host.setText(hostText)
        val portNumber = port.text.toString().trim().toIntOrNull()
        if (portNumber == null || portNumber !in 1..65535) {
            toast(R.string.bad_port)
            return
        }
        prefs.host = hostText
        prefs.port = portNumber
        prefs.user = user.text.toString().trim()
        prefs.pass = pass.text.toString()
        prefs.tls = tls.isChecked

        val newId = Topics.sanitize(nodeId.text.toString()).ifEmpty { Topics.DEFAULT_BASE }
        val oldId = prefs.nodeId
        if (newId != oldId) {
            if (prefs.pendingCleanupNodeId.isEmpty()) prefs.pendingCleanupNodeId = oldId
            prefs.nodeId = newId
        }
        nodeId.setText(newId)
        prefs.deviceNameRaw = deviceName.text.toString()

        prefs.thsEnabled = ths.isChecked
        prefs.ioEnabled = inputs.isChecked
        prefs.ioTriggersRelay = inputRelay.isChecked
        prefs.luxEnabled = lux.isChecked
        prefs.autostart = autostart.isChecked
        prefs.watchdog = watchdog.isChecked
        WatchdogJob.sync(this, watchdog.isChecked)

        PanelService.start(this, PanelService.ACTION_RELOAD)
        toast(R.string.saved)
    }

    private fun requestBatteryExemption() {
        if (isBatteryExempt()) {
            toast(R.string.battery_ok)
            return
        }
        try {
            startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:$packageName")))
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Exception) {
            }
        }
    }

    private fun isBatteryExempt(): Boolean =
        getSystemService(PowerManager::class.java)?.isIgnoringBatteryOptimizations(packageName) == true

    private fun render() {
        val link = PanelStatus.link
        val (color, pill) = when (link) {
            PanelStatus.Link.CONNECTED -> C.GREEN to R.string.pill_connected
            PanelStatus.Link.CONNECTING -> C.ORANGE to R.string.pill_connecting
            PanelStatus.Link.RETRY -> C.RED to R.string.pill_retry
            PanelStatus.Link.NOT_CONFIGURED -> C.GREY to R.string.pill_not_configured
        }
        (pillDot.background as GradientDrawable).setColor(color)
        pillText.setText(pill)
        tileMqtt.setText(pill)
        tileMqtt.setTextColor(color)

        tileService.setText(if (PanelService.running) R.string.value_running else R.string.value_stopped)
        tileService.setTextColor(if (PanelService.running) C.TEXT else C.RED)
        tileTemp.text = PanelStatus.temperature?.let { String.format(Locale.getDefault(), "%.1f °C", it) } ?: "—"
        tileHum.text = PanelStatus.humidity?.let { "$it %" } ?: "—"

        val on = PanelStatus.ledOn
        tileLed.setText(if (on) R.string.value_on else R.string.value_off)
        (ledSwatch.background as GradientDrawable).setColor(if (on) (0xFF000000.toInt() or PanelStatus.ledColor) else 0xFF2A3642.toInt())

        val onText = getString(R.string.value_on)
        val offText = getString(R.string.value_off)
        tileRelays.text = "1: ${if (PanelStatus.relay1) onText else offText} · 2: ${if (PanelStatus.relay2) onText else offText}"

        val lines = mutableListOf<String>()
        if (PanelStatus.linkText.isNotEmpty()) lines += PanelStatus.linkText
        PanelStatus.hardwareError?.let { lines += "⚠ $it" }
        if (PanelStatus.sensorSource.isNotEmpty()) lines += PanelStatus.sensorSource
        if (PanelStatus.inputs.isNotEmpty()) lines += PanelStatus.inputs
        if (PanelStatus.lux.isNotEmpty()) lines += "lux: " + PanelStatus.lux
        lines += prefs.clientId + " → " + prefs.nodeId + "/…"
        details.text = lines.joinToString("\n")

        val exempt = isBatteryExempt()
        batteryText.setText(if (exempt) R.string.startup_battery_off else R.string.startup_battery_on)
        batteryButton.visibility = if (exempt) View.GONE else View.VISIBLE

        val hibernationOff = isHibernationExempt()
        hibernationText?.setText(if (hibernationOff) R.string.startup_hibernation_off else R.string.startup_hibernation_on)
        hibernationButton?.visibility = if (hibernationOff) View.GONE else View.VISIBLE
    }

    // ---------------------------------------------------------------- view helpers

    private fun card(title: Int): LinearLayout = vertical().apply {
        background = rounded(C.CARD, dp(20), C.CARD_STROKE)
        setPadding(dp(18), dp(16), dp(18), dp(16))
        addView(label(getString(title), 17f, C.TEXT, bold = true).apply { setPadding(0, 0, 0, dp(6)) })
    }

    private fun wrap(card: View): View = card.also {
        it.layoutParams = LinearLayout.LayoutParams(MATCH, WRAP).apply { bottomMargin = dp(16) }
    }

    private fun tile(parent: LinearLayout, title: Int, withSwatch: Boolean = false): TextView {
        val box = vertical().apply {
            background = rounded(C.FIELD, dp(14), C.FIELD_STROKE)
            setPadding(dp(14), dp(12), dp(14), dp(12))
        }
        box.addView(label(getString(title), 12.5f, C.DIM))
        val value = label("—", 19f, C.TEXT, bold = true)
        if (withSwatch) {
            val row = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
            }
            ledSwatch = View(this).apply { background = oval(0xFF2A3642.toInt()) }
            row.addView(ledSwatch, LinearLayout.LayoutParams(dp(16), dp(16)).apply { marginEnd = dp(8) })
            row.addView(value)
            box.addView(row)
        } else {
            box.addView(value)
        }
        val lp = LinearLayout.LayoutParams(0, WRAP, 1f).apply {
            topMargin = dp(8)
            if (parent.childCount == 0) marginEnd = dp(8) else marginStart = dp(0)
        }
        parent.addView(box, lp)
        return value
    }

    private fun field(parent: LinearLayout, title: Int, value: String, type: Int, hint: String? = null): EditText {
        parent.addView(label(getString(title), 12.5f, C.DIM).apply { setPadding(dp(2), dp(10), 0, dp(6)) })
        val edit = EditText(this).apply {
            setText(value)
            inputType = type
            isSingleLine = true
            setTextColor(C.TEXT)
            setHintTextColor(C.HINT)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            background = rounded(C.FIELD, dp(12), C.FIELD_STROKE)
            setPadding(dp(14), dp(12), dp(14), dp(12))
            if (hint != null) this.hint = hint
        }
        parent.addView(edit, LinearLayout.LayoutParams(MATCH, WRAP))
        return edit
    }

    private fun note(text: Int) = label(getString(text), 12f, C.DIM).apply { setPadding(dp(2), dp(6), 0, 0) }

    private fun switchRow(parent: LinearLayout, title: Int, desc: Int, value: Boolean): Switch {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, dp(10), 0, dp(10))
        }
        val texts = vertical()
        texts.addView(label(getString(title), 16f, C.TEXT))
        texts.addView(label(getString(desc), 12.5f, C.DIM))
        row.addView(texts, LinearLayout.LayoutParams(0, WRAP, 1f).apply { marginEnd = dp(12) })
        val sw = Switch(this).apply {
            isChecked = value
            thumbTintList = ColorStateList(
                arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf()),
                intArrayOf(C.ACCENT, 0xFFB0BEC5.toInt()),
            )
            trackTintList = ColorStateList(
                arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf()),
                intArrayOf(0x804FC3F7.toInt(), 0x33FFFFFF),
            )
        }
        row.addView(sw)
        row.setOnClickListener { if (sw.isEnabled) sw.toggle() }
        parent.addView(row)
        return sw
    }

    private fun primaryButton(text: Int, onClick: () -> Unit) = Button(this).apply {
        setText(text)
        isAllCaps = false
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        setTypeface(typeface, Typeface.BOLD)
        setTextColor(C.ON_ACCENT)
        background = pressable(rounded(C.ACCENT, dp(14)))
        stateListAnimator = null
        setPadding(dp(16), dp(14), dp(16), dp(14))
        setOnClickListener { onClick() }
    }

    private fun secondaryButton(text: Int, onClick: () -> Unit) = Button(this).apply {
        setText(text)
        isAllCaps = false
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
        setTextColor(C.ACCENT)
        background = pressable(rounded(0x00000000, dp(14), C.ACCENT))
        stateListAnimator = null
        setPadding(dp(16), dp(12), dp(16), dp(12))
        setOnClickListener { onClick() }
    }

    private fun label(text: String, sizeSp: Float, color: Int, bold: Boolean = false) = TextView(this).apply {
        this.text = text
        setTextColor(color)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
        if (bold) setTypeface(typeface, Typeface.BOLD)
    }

    private fun vertical() = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }

    private fun rounded(fill: Int, radius: Int, stroke: Int? = null) = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = radius.toFloat()
        setColor(fill)
        if (stroke != null) setStroke(dp(1), stroke)
    }

    private fun oval(fill: Int) = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(fill)
    }

    private fun pressable(content: Drawable) = RippleDrawable(ColorStateList.valueOf(0x33FFFFFF), content, null)

    private fun toast(text: Int) = Toast.makeText(this, text, Toast.LENGTH_SHORT).show()

    private fun dp(v: Int) = (v * resources.displayMetrics.density + 0.5f).toInt()

    private companion object {
        const val MATCH = ViewGroup.LayoutParams.MATCH_PARENT
        const val WRAP = ViewGroup.LayoutParams.WRAP_CONTENT
    }
}
