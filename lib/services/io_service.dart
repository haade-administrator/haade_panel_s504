import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';
import 'package:flutter/foundation.dart'; // pour ValueNotifier

class IoService {
  static final IoService instance = IoService._internal();
  factory IoService() => instance;

  IoService._internal();

  static const _platform = MethodChannel('com.example.gpiocontrol/io');

  final String _out1TopicSet = 'elc_s504007700001/switch/out1/set';
  final String _out1TopicState = 'elc_s504007700001/switch/out1/state';
  final String _out2TopicSet = 'elc_s504007700001/switch/out2/set';
  final String _out2TopicState = 'elc_s504007700001/switch/out2/state';

  final String _availabilityTopic = 'elc_s504007700001/switch/availability';

  // ValueNotifier pour suivre l’état des sorties en temps réel
  final ValueNotifier<bool> out1StateNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> out2StateNotifier = ValueNotifier<bool>(false);

  bool _discoveryPublished = false;

  Future<void> initialize() async {
    out1StateNotifier.value = false;
    out2StateNotifier.value = false;

    _publishDiscoveryConfigs();
    MQTTService.instance.publish(_availabilityTopic, 'online', retain: true);
    _publishIoStates(retain: true);

    MQTTService.instance.subscribe(_out1TopicSet, (String message) {
      _onMessage(_out1TopicSet, message);
    });
    MQTTService.instance.subscribe(_out2TopicSet, (String message) {
      _onMessage(_out2TopicSet, message);
    });
  }

  void _publishIoStates({bool retain = false}) {
    final payloadOut1 = out1StateNotifier.value ? 'ON' : 'OFF';
    final payloadOut2 = out2StateNotifier.value ? 'ON' : 'OFF';

    MQTTService.instance.publish(_out1TopicState, payloadOut1, retain: retain);
    MQTTService.instance.publish(_out2TopicState, payloadOut2, retain: retain);
  }

  void _publishDiscoveryConfigs() {
    if (_discoveryPublished) return;
    _discoveryPublished = true;

    const out1Config = '''{
      "name": "Sortie OUT1 SMT101",
      "state_topic": "elc_s504007700001/switch/out1/state",
      "command_topic": "elc_s504007700001/switch/out1/set",
      "object_id": "elc_s504007700001_out1",
      "unique_id": "elc_s504007700001_out1",
      "availability": [{
        "topic": "elc_s504007700001/switch/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      }],
      "payload_on": "ON",
      "payload_off": "OFF",
      "state_on": "ON",
      "state_off": "OFF",
      "device": {
        "identifiers": ["elc_s504007700001"],
        "name": "Tablette SMT",
        "model": "SMT101",
        "manufacturer": "ELC",
        "sw_version": "1.0"
      }
    }''';

    const out2Config = '''{
      "name": "Sortie OUT2 SMT101",
      "state_topic": "elc_s504007700001/switch/out2/state",
      "command_topic": "elc_s504007700001/switch/out2/set",
      "object_id": "elc_s504007700001_out2",
      "unique_id": "elc_s504007700001_out2",
      "availability": [{
        "topic": "elc_s504007700001/switch/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      }],
      "payload_on": "ON",
      "payload_off": "OFF",
      "state_on": "ON",
      "state_off": "OFF",
      "device": {
        "identifiers": ["elc_s504007700001"],
        "name": "Tablette SMT",
        "model": "SMT101",
        "manufacturer": "ELC",
        "sw_version": "1.0"
      }
    }''';

    MQTTService.instance.publish('homeassistant/switch/elc_s504007700001_out1/config', out1Config, retain: true);
    MQTTService.instance.publish('homeassistant/switch/elc_s504007700001_out2/config', out2Config, retain: true);
  }

  Future<void> _onMessage(String topic, String message) async {
    print('IoService MQTT received: $topic => $message');
    final isOn = (message.toUpperCase() == 'ON');

    if (topic == _out1TopicSet) {
      await setOutputState(1, isOn, publishState: true);
    } else if (topic == _out2TopicSet) {
      await setOutputState(2, isOn, publishState: true);
    }
  }

  Future<void> setOutputState(int outputNumber, bool state, {bool publishState = true}) async {
    try {
      await _platform.invokeMethod('setOutputState', {
        'output': outputNumber,
        'state': state,
      });

      final payload = state ? 'ON' : 'OFF';

      if (outputNumber == 1) {
        out1StateNotifier.value = state;
        if (publishState) {
          MQTTService.instance.publish(_out1TopicState, payload, retain: true);
        }
      } else if (outputNumber == 2) {
        out2StateNotifier.value = state;
        if (publishState) {
          MQTTService.instance.publish(_out2TopicState, payload, retain: true);
        }
      }
    } on PlatformException catch (e) {
      print('Erreur IoService setOutputState: $e');
    }
  }

  Future<void> setAvailability(bool online) async {
    MQTTService.instance.publish(_availabilityTopic, online ? 'online' : 'offline', retain: true);
  }

  void dispose() {
    MQTTService.instance.publish(_availabilityTopic, 'offline', retain: true);
  }
}

