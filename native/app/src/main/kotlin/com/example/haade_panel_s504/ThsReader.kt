package com.example.haade_panel_s504

import android.os.Process
import android.util.Log
import java.io.Closeable
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.TimeUnit

/**
 * Temperature and humidity of the SMT panels come from two input devices ("sun-ths", "sun-hum")
 * that report EV_ABS values in hundredths.
 *
 * The original app kept `getevent -l` running for *every* input device and string-parsed each line,
 * including all touchscreen events, and started one more such process each time its screen was
 * recreated. Here each sensor node is read directly with a blocking read: the threads sleep until
 * the sensor reports. If the node cannot be opened directly, `getevent` is used for that node only.
 */
class ThsReader(private val onValue: (Kind, Double) -> Unit) {

    /** [code] is the EV_ABS axis each device reports on — the same ones the original app parsed. */
    enum class Kind(val code: Int) { TEMPERATURE(0x06), HUMIDITY(0x1d) }

    @Volatile private var running = false
    private val closers = CopyOnWriteArrayList<Closeable>()
    private val state = java.util.concurrent.ConcurrentHashMap<Kind, String>()

    fun start() {
        running = true
        val nodes = findNodes()
        for ((kind, path) in nodes) note(kind, path)
        for ((kind, path) in nodes) {
            Thread({ loop(kind, path) }, "ths-" + kind.name.lowercase()).apply {
                isDaemon = true
                start()
            }
        }
    }

    fun stop() {
        running = false
        for (c in closers) {
            try {
                c.close()
            } catch (_: Exception) {
            }
        }
        closers.clear()
    }

    private fun loop(kind: Kind, path: String) {
        readCurrent(kind, path)
        var viaGetevent = false
        var pauseSec = 15L
        while (running) {
            val started = System.nanoTime()
            note(kind, if (viaGetevent) "$path (getevent)" else path)
            try {
                if (viaGetevent) readViaGetevent(kind, path) else readEvents(kind, path)
            } catch (e: FileNotFoundException) {
                if (!viaGetevent) {
                    Log.i(TAG, "$path is not directly readable (${e.message}), using getevent")
                    viaGetevent = true
                    continue
                }
                note(kind, "$path — ${e.message}")
            } catch (e: Exception) {
                if (running) note(kind, "$path — ${e.message}")
            }
            if (!running) break
            // A reader that ran for a while was healthy: start the pauses from the beginning again.
            if (System.nanoTime() - started > TimeUnit.MINUTES.toNanos(5)) pauseSec = 15
            try {
                TimeUnit.SECONDS.sleep(pauseSec)
            } catch (_: InterruptedException) {
                return
            }
            pauseSec = (pauseSec * 2).coerceAtMost(300)
        }
    }

    private fun note(kind: Kind, text: String) {
        state[kind] = text
        PanelStatus.sensorSource = Kind.values().mapNotNull { k -> state[k]?.let { "${k.name.lowercase()}: $it" } }.joinToString("\n")
    }

    /** Blocking read of raw `struct input_event` records. */
    private fun readEvents(kind: Kind, path: String) {
        // struct input_event = timeval + u16 type + u16 code + s32 value (timeval is 16 bytes for 64-bit processes).
        val size = if (Process.is64Bit()) 24 else 16
        FileInputStream(path).use { input ->
            closers += input
            try {
                val buf = ByteArray(size * 32)
                val bb = ByteBuffer.wrap(buf).order(ByteOrder.LITTLE_ENDIAN)
                while (running) {
                    val n = input.read(buf)
                    if (n <= 0) break
                    var off = 0
                    while (off + size <= n) {
                        val type = bb.getShort(off + size - 8).toInt() and 0xffff
                        val code = bb.getShort(off + size - 6).toInt() and 0xffff
                        if (type == EV_ABS && code == kind.code) onValue(kind, bb.getInt(off + size - 4) / 100.0)
                        off += size
                    }
                }
            } finally {
                closers -= input
            }
        }
    }

    /** Fallback: `getevent <node>` prints "0003 0006 00000bb8" (type, code, value in hex). */
    private fun readViaGetevent(kind: Kind, path: String) {
        if (!File(path).exists()) throw FileNotFoundException("$path does not exist")
        val proc = ProcessBuilder("getevent", path).redirectErrorStream(true).start()
        val closer = Closeable { proc.destroy() }
        closers += closer
        try {
            proc.inputStream.bufferedReader().use { reader ->
                while (running) {
                    val line = reader.readLine() ?: break
                    val t = line.trim().split(WHITESPACE)
                    if (t.size >= 3 && t[t.size - 3] == "0003" && t[t.size - 2].toIntOrNull(16) == kind.code) {
                        val raw = t[t.size - 1].toLongOrNull(16) ?: continue
                        onValue(kind, raw.toInt() / 100.0)
                    }
                }
            }
        } finally {
            closers -= closer
            proc.destroy()
        }
    }

    /** Current value right away (a device only reports on its next measurement): `getevent -p` prints and exits. */
    private fun readCurrent(kind: Kind, path: String) {
        try {
            val proc = ProcessBuilder("getevent", "-p", path).redirectErrorStream(true).start()
            if (!proc.waitFor(3, TimeUnit.SECONDS)) {
                proc.destroy()
                return
            }
            val text = proc.inputStream.bufferedReader().use { it.readText() }
            // "    ABS (0003): 0006  : value 2987, min …" — take the line of this sensor's axis.
            val axis = Regex("%04x".format(kind.code) + "\\s*:\\s*value\\s+(-?\\d+)")
            val value = axis.find(text)?.groupValues?.get(1)?.toIntOrNull() ?: return
            if (value != 0) onValue(kind, value / 100.0)
        } catch (e: Exception) {
            Log.w(TAG, "getevent -p $path: ${e.message}")
        }
    }

    private fun findNodes(): Map<Kind, String> {
        val nodes = mutableMapOf<Kind, String>()
        File("/sys/class/input").listFiles()?.forEach { dir ->
            if (!dir.name.startsWith("event")) return@forEach
            val name = try {
                File(dir, "device/name").readText().trim()
            } catch (_: Exception) {
                return@forEach
            }
            when (name) {
                "sun-ths" -> nodes[Kind.TEMPERATURE] = "/dev/input/${dir.name}"
                "sun-hum" -> nodes[Kind.HUMIDITY] = "/dev/input/${dir.name}"
            }
        }
        // Fallback: the vendor properties the original app used (event7 / event8 by default).
        if (Kind.TEMPERATURE !in nodes) nodes[Kind.TEMPERATURE] = "/dev/input/event" + systemProperty("com.gulukai.ths", "7")
        if (Kind.HUMIDITY !in nodes) nodes[Kind.HUMIDITY] = "/dev/input/event" + systemProperty("com.gulukai.hum", "8")
        return nodes
    }

    private fun systemProperty(key: String, default: String): String = try {
        val get = Class.forName("android.os.SystemProperties").getMethod("get", String::class.java, String::class.java)
        (get.invoke(null, key, default) as String).ifBlank { default }
    } catch (_: Exception) {
        default
    }

    private companion object {
        const val TAG = "PanelThs"
        const val EV_ABS = 3
        val WHITESPACE = Regex("\\s+")
    }
}
