import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';

class LedService implements MqttReconnectAware {
  static final LedService _instance = LedService._internal();
  factory LedService() => _instance;
  LedService._internal() {
    MQTTService.instance.registerReconnectAware(this);
  }

  static const _platform = MethodChannel('com.example.elcapi/led');

  final ValueNotifier<Color> selectedColor = ValueNotifier(const Color.fromARGB(255, 7, 39, 223));
  final ValueNotifier<double> brightness = ValueNotifier(1.0);
  final ValueNotifier<bool> isOn = ValueNotifier(false);

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _publishDiscoveryConfig();

    MQTTService.instance.subscribe('haade_panel_s504/led/set', _handleMQTTMessage);

    publishAvailability();
    publishLedState();

    selectedColor.addListener(_onStateChanged);
    brightness.addListener(_onStateChanged);
    isOn.addListener(_onStateChanged);
  }

  void dispose() {
    selectedColor.removeListener(_onStateChanged);
    brightness.removeListener(_onStateChanged);
    isOn.removeListener(_onStateChanged);
  }

  void _onStateChanged() {
    _setLedHardware();
    publishLedState();
  }

  void publishAvailability() {
    MQTTService.instance.publish('haade_panel_s504/led/availability', 'online', retain: true);
  }

  void _publishDiscoveryConfig() {
    const configPayload = '''{ ... }'''; // ton JSON complet
    MQTTService.instance.publish('homeassistant/light/haade_panel_s504_led/config', configPayload, retain: true);
  }

  Color _applyBrightness(Color color, double brightness) {
    return Color.fromARGB(
      255,
      (color.red * brightness).round().clamp(0, 255),
      (color.green * brightness).round().clamp(0, 255),
      (color.blue * brightness).round().clamp(0, 255),
    );
  }

  Future<void> _setLedHardware() async {
    try {
      if (!isOn.value) {
        await _platform.invokeMethod('setLed', {"r": 0, "g": 0, "b": 0});
      } else {
        final scaledColor = _applyBrightness(selectedColor.value, brightness.value);
        final r = (scaledColor.red / 17).round().clamp(0, 15);
        final g = (scaledColor.green / 17).round().clamp(0, 15);
        final b = (scaledColor.blue / 17).round().clamp(0, 15);
        await _platform.invokeMethod('setLed', {"r": r, "g": g, "b": b});
      }
    } on PlatformException catch (e) {
      debugPrint("Erreur JNI: ${e.message}");
    }
  }

  void publishLedState() {
    final scaled = _applyBrightness(selectedColor.value, brightness.value);
    final payload = jsonEncode({
      "state": isOn.value ? "ON" : "OFF",
      "brightness": (brightness.value * 255).round(),
      "color": {"r": scaled.red, "g": scaled.green, "b": scaled.blue}
    });

    MQTTService.instance.publish('haade_panel_s504/led/state', payload, retain: true);
  }

  void _handleMQTTMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final state = data['state'];
      final r = data['color']?['r'] ?? selectedColor.value.red;
      final g = data['color']?['g'] ?? selectedColor.value.green;
      final b = data['color']?['b'] ?? selectedColor.value.blue;
      final brightnessVal = (data['brightness'] ?? (brightness.value * 255)) / 255.0;

      selectedColor.value = Color.fromARGB(255, r, g, b);
      brightness.value = brightnessVal.clamp(0.0, 1.0);
      isOn.value = state == null || state.toString().toUpperCase() != "OFF";

      _setLedHardware();
    } catch (e) {
      debugPrint("Erreur parsing MQTT: $e");
    }
  }

  @override
  void onMqttReconnected() {
    // 1️⃣ Resubscribe d’abord
    MQTTService.instance.subscribe('haade_panel_s504/led/set', _handleMQTTMessage);

    // 2️⃣ Republier état et availability
    publishAvailability();
    publishLedState();

    // 3️⃣ Forcer hardware après un petit délai
    Future.delayed(const Duration(milliseconds: 500), () {
      _setLedHardware();
    });
  }
}



