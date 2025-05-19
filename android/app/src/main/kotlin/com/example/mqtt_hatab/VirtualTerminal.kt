package com.example.mqtt_hatab

class VirtualTerminal(id: String, command: String, path: String) {

    interface Listener {
        fun onCommandLineResult(result: VTCommandLineResult)
    }

    data class VTCommandLineResult(val lineData: String)

    fun setListener(listener: Listener) {
        // Simule un retour périodique
        Thread {
            while (true) {
                Thread.sleep(1000)
                val fakeOutput = "event7: EV_ABS ABS_THROTTLE 001d 01f4"
                listener.onCommandLineResult(VTCommandLineResult(fakeOutput))
            }
        }.start()
    }
}