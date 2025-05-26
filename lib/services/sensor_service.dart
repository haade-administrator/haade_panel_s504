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
  bool _discoveryPublished = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onTemperature":
          final double rawTemp = (call.arguments as num).toDouble();
          final double roundedTemp = (rawTemp * 2).roundToDouble() / 2.0; // pas de 0.5
          temperature.value = roundedTemp;
          MQTTService.instance.publish(
            'elc_s504007700001/sensor/temperature',
            roundedTemp.toStringAsFixed(1),
            retain: true,
          );
          break;
        case "onHumidity":
          final double rawHum = (call.arguments as num).toDouble();
          final int roundedHum = rawHum.round(); // pas de décimale
          humidity.value = roundedHum.toDouble();
          MQTTService.instance.publish(
            'elc_s504007700001/sensor/humidity',
            roundedHum.toString(),
            retain: true,
          );
          break;
        case "onSensorError":
          debugPrint("Erreur capteur : ${call.arguments}");
          break;
        default:
          debugPrint("Méthode non reconnue : ${call.method}");
          break;
      }
    });

    // Publication de availability et configs MQTT quand connecté
    void onConnected() {
      if (MQTTService.instance.isConnected.value && !_discoveryPublished) {
        publishAvailability();
        _publishDiscoveryConfigs();
        readSensors();
      }
    }

    if (MQTTService.instance.isConnected.value) {
      onConnected();
    } else {
      MQTTService.instance.isConnected.addListener(onConnected);
    }
  }

  void publishAvailability() {
    MQTTService.instance.publish(
      'elc_s504007700001/sensor/availability',
      'online',
      retain: true,
    );
  }

  Future<void> readSensors() async {
    try {
      final result = await _platform.invokeMethod<Map>('readSensors');

      if (result != null) {
        final t = (result['temperature'] as num).toDouble();
        final h = (result['humidity'] as num).toDouble();

        final roundedTemp = (t * 2).roundToDouble() / 2.0;
        final roundedHum = h.round();

        temperature.value = roundedTemp;
        humidity.value = roundedHum.toDouble();

        MQTTService.instance.publish(
          'elc_s504007700001/sensor/temperature',
          roundedTemp.toStringAsFixed(1),
          retain: true,
        );
        MQTTService.instance.publish(
          'elc_s504007700001/sensor/humidity',
          roundedHum.toString(),
          retain: true,
        );
      }
    } catch (e) {
      debugPrint("Erreur lecture capteurs : $e");
    }
  }

  void _publishDiscoveryConfigs() {
    if (_discoveryPublished) return;
    _discoveryPublished = true;

    const tempConfig = '''
{
  "name": "Temperature SMT101",
  "friendly_name": "Temperature",
  "object_id": "elc_s504007700001_temperature",
  "unique_id": "elc_s504007700001_temperature",
  "state_topic": "elc_s504007700001/sensor/temperature",
  "availability": 
    {
      "topic": "elc_s504007700001/sensor/availability",
      "payload_available": "online",
      "payload_not_available": "offline"
    },
  "device_class": "temperature",
  "unit_of_measurement": "C",
  "device": {
    "identifiers": ["elc_s504007700001"],
    "name": "Tablette SMT",
    "model": "SMT101",
    "sw_version": "1.0.2"
  }
}
''';

    const humConfig = '''
{
  "name": "Humidity SMT101",
  "friendly_name": "Humidity",
  "object_id": "elc_s504007700001_humidity",
  "unique_id": "elc_s504007700001_humidity",
  "state_topic": "elc_s504007700001/sensor/humidity",
  "availability": 
    {
      "topic": "elc_s504007700001/sensor/availability",
      "payload_available": "online",
      "payload_not_available": "offline"
    },
  "device_class": "humidity",
  "unit_of_measurement": "%",
  "device": {
    "identifiers": ["elc_s504007700001"],
    "name": "Tablette SMT",
    "model": "SMT101",
    "sw_version": "1.0.2"
  }
}
''';

    MQTTService.instance.publish(
      'homeassistant/sensor/elc_s504007700001_temperature/config',
      tempConfig,
      retain: true,
    );

    MQTTService.instance.publish(
      'homeassistant/sensor/elc_s504007700001_humidity/config',
      humConfig,
      retain: true,
    );

    // Republier les dernières valeurs si disponibles (différent de 0)
    if (temperature.value != 0) {
      final temp = (temperature.value * 2).roundToDouble() / 2.0;
      MQTTService.instance.publish(
        'elc_s504007700001/sensor/temperature',
        temp.toStringAsFixed(1),
        retain: true,
      );
    }

    if (humidity.value != 0) {
      final hum = humidity.value.round();
      MQTTService.instance.publish(
        'elc_s504007700001/sensor/humidity',
        hum.toString(),
        retain: true,
      );
    }
  }
}



