import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class IoService {
  static final IoService instance = IoService._internal();
  factory IoService() => instance;

  IoService._internal();

  // ↪️ Canal de communication avec la couche native (Android -> Kotlin)
  static const _platform = MethodChannel('com.example.iocontrol/io');

  // 🔌 MQTT topics des capteurs d’entrées IO1 et IO2
  final String _io1TopicState = 'haade_panel_s504/binary_sensor/io1/state';
  final String _io2TopicState = 'haade_panel_s504/binary_sensor/io2/state';
  final String _availabilityTopic = 'haade_panel_s504/binary_sensor/availability';

  // 📡 Notifiers pour refléter l’état en UI ou logique Flutter
  final ValueNotifier<bool> io1StateNotifier = ValueNotifier(false);
  final ValueNotifier<bool> io2StateNotifier = ValueNotifier(false);

  bool _discoveryPublished = false;
  Timer? _pollingTimer;

  /// 🔧 Initialise les IO :
  /// - publie config MQTT discovery (Home Assistant)
  /// - publie "online"
  /// - lit les états initiaux des IO
  /// - démarre le polling régulier
  Future<void> initialize() async {
    _publishDiscoveryConfigs();
    MQTTService.instance.publish(_availabilityTopic, 'online', retain: true);

    await _checkAndUpdateState(1, forcePublish: true);
    await _checkAndUpdateState(2, forcePublish: true);

    _startPolling();
  }

  /// 🔁 Démarre un polling tous les 500ms pour lire les entrées physiques
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      await _checkAndUpdateState(1);
      await _checkAndUpdateState(2);
    });
  }

  /// 🧠 Lit l’état de l’IO via JNI et publie son état MQTT si changement
  /// Si un bouton physique est pressé (niveau haut), on déclenche aussi un relais MQTT
  Future<void> _checkAndUpdateState(int ioNumber, {bool forcePublish = false}) async {
    try {
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

        // 💡 Optionnel : déclenche un relais si appui bouton détecté
        if (isPressed) {
          final String relayTopic = (ioNumber == 1)
              ? 'haade_panel_s504/switch/relay1/set'
              : 'haade_panel_s504/switch/relay2/set';

          print('MQTT → $relayTopic = ON (triggered by IO$ioNumber)');
          MQTTService.instance.publish(relayTopic, 'ON', retain: false);
        }
      }
    } on PlatformException catch (e) {
      print('Erreur readState($ioNumber): $e');
    }
  }

  /// ⚙️ Utilise `CallIO.setHigh()` en natif → met une sortie à HIGH (3.3V)
  Future<void> setIoHigh(int ioNumber) async {
    try {
      await _platform.invokeMethod('setHigh', {'io': ioNumber});
    } on PlatformException catch (e) {
      print('Erreur setHigh($ioNumber): $e');
    }
  }

  /// ⚙️ Utilise `CallIO.setLow()` en natif → met une sortie à LOW (0V)
  Future<void> setIoLow(int ioNumber) async {
    try {
      await _platform.invokeMethod('setLow', {'io': ioNumber});
    } on PlatformException catch (e) {
      print('Erreur setLow($ioNumber): $e');
    }
  }

  /// 🏠 Publie les topics `config` pour Home Assistant Discovery (1 par IO)
  void _publishDiscoveryConfigs() {
    if (_discoveryPublished) return;
    _discoveryPublished = true;

    const io1Config = '''{
      "name": "IO1 (Bouton 1)",
      "state_topic": "haade_panel_s504/binary_sensor/io1/state",
      "object_id": "haade_panel_s504_io1",
      "unique_id": "haade_panel_s504_io1",
      "device_class": "occupancy",
      "payload_on": "ON",
      "payload_off": "OFF",
      "availability": {
        "topic": "haade_panel_s504/binary_sensor/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      },
      "device": {
        "identifiers": ["haade_panel_s504"],
        "name": "Tablette SMT",
        "model": "SMT101",
        "manufacturer": "ELC",
        "sw_version": "1.0.3"
      }
    }''';

    const io2Config = '''{
      "name": "IO2 (Bouton 2)",
      "state_topic": "haade_panel_s504/binary_sensor/io2/state",
      "object_id": "haade_panel_s504_io2",
      "unique_id": "haade_panel_s504_io2",
      "device_class": "occupancy",
      "payload_on": "ON",
      "payload_off": "OFF",
      "availability": {
        "topic": "haade_panel_s504/binary_sensor/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      },
      "device": {
        "identifiers": ["haade_panel_s504"],
        "name": "Tablette SMT",
        "model": "SMT101",
        "manufacturer": "ELC",
        "sw_version": "1.0.3"
      }
    }''';

    MQTTService.instance.publish('homeassistant/binary_sensor/haade_panel_s504_io1/config', io1Config, retain: true);
    MQTTService.instance.publish('homeassistant/binary_sensor/haade_panel_s504_io2/config', io2Config, retain: true);
  }

  /// ↩️ Met à jour l’état "online/offline" dans MQTT (ex: à l’extinction de l’app)
  Future<void> setAvailability(bool online) async {
    MQTTService.instance.publish(_availabilityTopic, online ? 'online' : 'offline', retain: true);
  }

  /// 🧹 Arrête le polling et publie "offline"
  void dispose() {
    _pollingTimer?.cancel();
    MQTTService.instance.publish(_availabilityTopic, 'offline', retain: true);
  }
}










