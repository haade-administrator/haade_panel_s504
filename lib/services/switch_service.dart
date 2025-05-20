import 'dart:async';
import 'package:flutter/services.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class SwitchService {
  static final SwitchService instance = SwitchService._internal();
  factory SwitchService() => instance;

  SwitchService._internal();

  static const _platform = MethodChannel('com.example.relaycontrol/relay');

  final String _relay1TopicSet = 'elc_s504007700001/switch/relay1/set';
  final String _relay1TopicState = 'elc_s504007700001/switch/relay1/state';
  final String _relay2TopicSet = 'elc_s504007700001/switch/relay2/set';
  final String _relay2TopicState = 'elc_s504007700001/switch/relay2/state';

  final String _availabilityTopic = 'elc_s504007700001/switch/availability';

  bool relay1State = false;
  bool relay2State = false;
  bool _availabilityState = false;
  bool _discoveryRelayPublished = false;

  /// Initialise le service : publie la config, les états et s’abonne aux topics MQTT.
  Future<void> initialize() async {

    relay1State = false;
    relay2State = false;

    _publishDiscoveryRelayConfigs();

    MQTTService.instance.publish(_availabilityTopic, 'online', retain: true);

    _publishRelayStates(retain: true);

    MQTTService.instance.subscribe(_relay1TopicSet, (String message) {
      _onMessage(_relay1TopicSet, message);
    });
    MQTTService.instance.subscribe(_relay2TopicSet, (String message) {
      _onMessage(_relay2TopicSet, message);
    });
  }

  void _publishRelayStates({bool retain = false}) {
    final payloadRelay1 = relay1State ? 'ON' : 'OFF';
    final payloadRelay2 = relay2State ? 'ON' : 'OFF';

    MQTTService.instance.publish(_relay1TopicState, payloadRelay1, retain: true);
    MQTTService.instance.publish(_relay2TopicState, payloadRelay2, retain: true);
  }

void _publishDiscoveryRelayConfigs() {
  if (_discoveryRelayPublished) return;
  _discoveryRelayPublished = true;

  const relay1Config = '''{
    "name": "Relais 1 SMT101",
    "state_topic": "elc_s504007700001/switch/relay1/state",
    "command_topic": "elc_s504007700001/switch/relay1/set",
    "object_id": "elc_s504007700001_relay1",
    "unique_id": "elc_s504007700001_relay1",
    "availability": [{
      "topic": "elc_s504007700001/switch/availability",
      "payload_available": "online",
      "payload_not_available": "offline"
    }],
    "device_class": "switch",
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

  const relay2Config = '''{
    "name": "Relais 2 SMT101",
    "state_topic": "elc_s504007700001/switch/relay2/state",
    "command_topic": "elc_s504007700001/switch/relay2/set",
    "object_id": "elc_s504007700001_relay2",
    "unique_id": "elc_s504007700001_relay2",
    "availability": [{
      "topic": "elc_s504007700001/switch/availability",
      "payload_available": "online",
      "payload_not_available": "offline"
    }],
    "device_class": "switch",
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

  MQTTService.instance.publish('homeassistant/switch/elc_s504007700001_relay1/config', relay1Config, retain: true);
  MQTTService.instance.publish('homeassistant/switch/elc_s504007700001_relay2/config', relay2Config, retain: true);
}


  Future<void> _onMessage(String topic, String message) async {
  print('SwitchService MQTT received: $topic => $message');
  final isOn = (message.toUpperCase() == 'ON');

  if (topic == _relay1TopicSet) {
    await setRelayState(1, isOn, publishState: true);
  } else if (topic == _relay2TopicSet) {
    await setRelayState(2, isOn, publishState: true);
  }
}

  /// Modifie l'état du relais physiquement et publie l'état si demandé.
  Future<void> setRelayState(int relayNumber, bool state, {bool publishState = true}) async {
    try {
      await _platform.invokeMethod('setRelayState', {
        'relay': relayNumber,
        'state': state,
      });

      final payload = state ? 'ON' : 'OFF';

      if (relayNumber == 1) {
        relay1State = state;
        if (publishState) {
          MQTTService.instance.publish(_relay1TopicState, payload, retain: true);
          
        }
      } else if (relayNumber == 2) {
        relay2State = state;
        if (publishState) {
          MQTTService.instance.publish(_relay2TopicState, payload, retain: true);
          
        }
      }
    } on PlatformException catch (e) {
      print('Erreur SwitchService setRelayState: $e');
    }
  }

  /// Met à jour l'état de disponibilité de la tablette
  Future<void> setAvailability(bool online) async {
    _availabilityState = online;
    MQTTService.instance.publish(_availabilityTopic, online ? 'ON' : 'OFF', retain: true);
  }

  void dispose() {
    MQTTService.instance.publish(_availabilityTopic, 'offline', retain: true);

  }
}



