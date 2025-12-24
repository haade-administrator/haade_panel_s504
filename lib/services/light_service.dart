import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';
import 'package:haade_panel_s504/services/notification.dart';

class LightService {
  static final LightService instance = LightService._internal();
  LightService._internal();

  static const _eventChannel = EventChannel('com.example.haade_panel_s504/LightSensorService');

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
      '{"lux": ${lux.toStringAsFixed(1)}}',
      retain: true,
    );

    if (lux > _threshold) {
      wakeUpTablet();
    }
  }

  void wakeUpTablet() {
    NotificationService().showLuminosityNotification('Réveil tablette','Luminosité > seuil ($_threshold lx)',);
  }

  void publishDiscoveryConfig() {
    const topic = 'homeassistant/sensor/haade_panel_s504_lux/config';
    const payload = '''
{
  "name": "Luminosity",
  "state_topic": "haade_panel_s504/sensor/lux",
  "value_template": "{{ value_json.lux }}",
  "unit_of_measurement": "lx",
  "device_class": "illuminance",
  "enabled_by_default": false,
  "unique_id": "haade_panel_s504_lux",
  "availability": {
    "topic": "haade_panel_s504/availability",
    "payload_available": "online",
    "payload_not_available": "offline"
  },
  "device": {
    "identifiers": ["haade_panel_s504"],
    "name": "Haade Panel s504",
    "model": "s504",
    "sw_version": "1.1.8"
  }
}
''';
    MQTTService.instance.publish(topic, payload, retain: true);
  }
}

