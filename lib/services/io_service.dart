import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class IoService {
  static final IoService instance = IoService._internal();
  factory IoService() => instance;

  IoService._internal();

  // IMPORTANT : correspond au channel défini en Kotlin MainActivity
  static const _platform = MethodChannel('com.example.iocontrol/io');

  final String _io1TopicState = 'elc_s504007700001/binary_sensor/io1/state';
  final String _io2TopicState = 'elc_s504007700001/binary_sensor/io2/state';
  final String _availabilityTopic = 'elc_s504007700001/binary_sensor/availability';

  final ValueNotifier<bool> io1StateNotifier = ValueNotifier(false);
  final ValueNotifier<bool> io2StateNotifier = ValueNotifier(false);

  bool _discoveryPublished = false;
  Timer? _pollingTimer;

  Future<void> initialize() async {
    _publishDiscoveryConfigs();

    // Disponibilité MQTT
    MQTTService.instance.publish(_availabilityTopic, 'online', retain: true);

    // Publier initialement les états réels des IO (forcePublish=true)
    await _checkAndUpdateState(1, forcePublish: true);
    await _checkAndUpdateState(2, forcePublish: true);

    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      await _checkAndUpdateState(1);
      await _checkAndUpdateState(2);
    });
  }

  Future<void> _checkAndUpdateState(int ioNumber, {bool forcePublish = false}) async {
  try {
    // 🔁 Utilise bien la lecture réelle de l’état GPIO
    final bool isPressed = await _platform.invokeMethod('readState', {
      'io': ioNumber,
    });

    final ValueNotifier<bool> notifier = (ioNumber == 1) ? io1StateNotifier : io2StateNotifier;
    final String topic = (ioNumber == 1) ? _io1TopicState : _io2TopicState;

    if (notifier.value != isPressed || forcePublish) {
      notifier.value = isPressed;
      final payload = isPressed ? 'ON' : 'OFF';

      print('MQTT → $topic = $payload (retain: true)');
      MQTTService.instance.publish(topic, payload, retain: true);
    }
  } on PlatformException catch (e) {
    print('Erreur readState($ioNumber): $e');
  }
}


  Future<void> setIoHigh(int ioNumber) async {
    try {
      await _platform.invokeMethod('setHigh', {'io': ioNumber});
    } on PlatformException catch (e) {
      print('Erreur setHigh($ioNumber): $e');
    }
  }

  Future<void> setIoLow(int ioNumber) async {
    try {
      await _platform.invokeMethod('setLow', {'io': ioNumber});
    } on PlatformException catch (e) {
      print('Erreur setLow($ioNumber): $e');
    }
  }

  void _publishDiscoveryConfigs() {
    if (_discoveryPublished) return;
    _discoveryPublished = true;

    const io1Config = '''{
      "name": "IO1 (Bouton 1)",
      "state_topic": "elc_s504007700001/binary_sensor/io1/state",
      "object_id": "elc_s504007700001_io1",
      "unique_id": "elc_s504007700001_io1",
      "device_class": "occupancy",
      "payload_on": "ON",
      "payload_off": "OFF",
      "availability": {
        "topic": "elc_s504007700001/binary_sensor/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      },
      "device": {
        "identifiers": ["elc_s504007700001"],
        "name": "Tablette SMT",
        "model": "SMT101",
        "manufacturer": "ELC",
        "sw_version": "1.0"
      }
    }''';

    const io2Config = '''{
      "name": "IO2 (Bouton 2)",
      "state_topic": "elc_s504007700001/binary_sensor/io2/state",
      "object_id": "elc_s504007700001_io2",
      "unique_id": "elc_s504007700001_io2",
      "device_class": "occupancy",
      "payload_on": "ON",
      "payload_off": "OFF",
      "availability": {
        "topic": "elc_s504007700001/binary_sensor/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      },
      "device": {
        "identifiers": ["elc_s504007700001"],
        "name": "Tablette SMT",
        "model": "SMT101",
        "manufacturer": "ELC",
        "sw_version": "1.0"
      }
    }''';

    MQTTService.instance.publish('homeassistant/binary_sensor/elc_s504007700001_io1/config', io1Config, retain: true);
    MQTTService.instance.publish('homeassistant/binary_sensor/elc_s504007700001_io2/config', io2Config, retain: true);
  }

  Future<void> setAvailability(bool online) async {
    MQTTService.instance.publish(_availabilityTopic, online ? 'online' : 'offline', retain: true);
  }

  void dispose() {
    _pollingTimer?.cancel();
    MQTTService.instance.publish(_availabilityTopic, 'offline', retain: true);
  }
}








