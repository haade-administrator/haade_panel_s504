# Vendor JNI libraries bind to these exact class and method names.
-keep class com.example.elcapi.jnielc { *; }
-keep class com.sys.gpio.gpioJni { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}

# Paho loads its network modules and logger through ServiceLoader / reflection.
-keep class org.eclipse.paho.client.mqttv3.** { *; }
-dontwarn org.eclipse.paho.client.mqttv3.**
