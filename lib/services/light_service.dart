import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class LightService {
  static final LightService instance = LightService._internal();
  LightService._internal();

  static const _eventChannel = EventChannel('com.example.mqtt_hatab/LightSensorService');

  final ValueNotifier<double> luxNotifier = ValueNotifier(0.0);
  double _threshold = 50.0;
  StreamSubscription? _sensorSubscription;

  void setThreshold(double value) {
    _threshold = value;
  }

  void startSensor() {
    _sensorSubscription = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is double) {
        handleLuxUpdate(event);
      } else if (event is int) {
        handleLuxUpdate(event.toDouble());
      }
    });
  }

  void stopSensor() {
    _sensorSubscription?.cancel();
    _sensorSubscription = null;
  }

  void handleLuxUpdate(double lux) {
    luxNotifier.value = lux;

    MQTTService.instance.publish(
      'haade_panel_s504/sensor/lux',
      lux.toStringAsFixed(1),
      retain: true,
    );

    if (lux > _threshold) {
      wakeUpTablet();
    }
  }

  void wakeUpTablet() {
    print('💡 Réveil tablette car luminosité > seuil ($_threshold lx)');
    // TODO: appel à un MethodChannel pour réveiller physiquement la tablette
  }

  void publishDiscoveryConfig() {
    const topic = 'homeassistant/sensor/haade_panel_s504_lux/config';
    const payload = '''
{
  "name": "Lux SMT101",
  "friendly_name": "Luminosity",
  "state_topic": "haade_panel_s504/sensor/lux",
  "unit_of_measurement": "lx",
  "device_class": "illuminance",
  "unique_id": "haade_panel_s504_lux",
  "object_id": "haade_panel_s504_lux",
  "availability": {
    "topic": "haade_panel_s504/sensor/availability",
    "payload_available": "online",
    "payload_not_available": "offline"
  },
  "device": {
    "identifiers": ["haade_panel_s504"],
    "name": "Tablette SMT",
    "model": "SMT101",
    "sw_version": "1.0.3"
  }
}
''';
    MQTTService.instance.publish(topic, payload, retain: true);
  }
}

