// lib/services/sensor_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  static const _platform = MethodChannel('com.example.elcapi/sensor');
  final temperature = ValueNotifier<double>(0);
  final humidity = ValueNotifier<double>(0);

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onTemperature":
          final double temp = (call.arguments as num).toDouble();
          temperature.value = temp;
          MQTTService.instance.publish('elc_s504007700001/sensor/temperature', temp.toStringAsFixed(1), retain: true);
          break;
        case "onHumidity":
          final double hum = (call.arguments as num).toDouble();
          humidity.value = hum;
          MQTTService.instance.publish('elc_s504007700001/sensor/humidity', hum.toStringAsFixed(1), retain: true);
          break;
        case "onSensorError":
          debugPrint("Erreur capteur : ${call.arguments}");
          break;
        default:
          debugPrint("Méthode non reconnue : ${call.method}");
          break;
      }
    });

    _publishDiscoveryConfigs();

    // Capteur disponible
    MQTTService.instance.publish('elc_s504007700001/sensor/availability', 'online', retain: true);
  }

  Future<void> readSensors() async {
    try {
      final result = await _platform.invokeMethod<Map>('readSensors');

      if (result != null) {
        final t = (result['temperature'] as num).toDouble();
        final h = (result['humidity'] as num).toDouble();
        temperature.value = t;
        humidity.value = h;

        MQTTService.instance.publish('elc_s504007700001/sensor/temperature', t.toStringAsFixed(1), retain: true);
        MQTTService.instance.publish('elc_s504007700001/sensor/humidity', h.toStringAsFixed(1), retain: true);
      }
    } catch (e) {
      debugPrint("Erreur lecture capteurs : $e");
    }
  }

  void _publishDiscoveryConfigs() {
    const tempConfig = '''...'''; // même contenu JSON que toi
    const humConfig = '''...''';

    MQTTService.instance.publish('homeassistant/sensor/elc_s504007700001_temp/config', tempConfig, retain: true);
    MQTTService.instance.publish('homeassistant/sensor/elc_s504007700001_humidity/config', humConfig, retain: true);
  }
}
