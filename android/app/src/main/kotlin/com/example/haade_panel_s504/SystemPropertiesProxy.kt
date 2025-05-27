package com.example.haade_panel_s504

import android.os.Build
import java.lang.reflect.Method

object SystemPropertiesProxy {
    @Throws(IllegalArgumentException::class)
    fun getString(key: String, defaultValue: String): String {
        return try {
            val systemProperties = Class.forName("android.os.SystemProperties")
            val get: Method = systemProperties.getMethod("get", String::class.java, String::class.java)
            get.invoke(null, key, defaultValue) as String
        } catch (e: Exception) {
            defaultValue
        }
    }
}
