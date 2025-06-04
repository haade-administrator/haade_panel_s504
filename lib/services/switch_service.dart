import 'dart:async';
import 'package:flutter/services.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';
import 'package:flutter/foundation.dart'; // pour ValueNotifier
import 'package:haade_panel_s504/services/notification.dart'; // <-- Ajouté

class SwitchService {
  static final SwitchService instance = SwitchService._internal();
  factory SwitchService() => instance;

  SwitchService._internal();

  static const _platform = MethodChannel('com.example.relaycontrol/relay');

  final String _relay1TopicSet = 'haade_panel_s504/switch/relay1/set';
  final String _relay1TopicState = 'haade_panel_s504/switch/relay1/state';
  final String _relay2TopicSet = 'haade_panel_s504/switch/relay2/set';
  final String _relay2TopicState = 'haade_panel_s504/switch/relay2/state';

  final String _availabilityTopic = 'haade_panel_s504/switch/availability';

  final ValueNotifier<bool> relay1StateNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> relay2StateNotifier = ValueNotifier<bool>(false);

  bool _discoveryRelayPublished = false;

  Future<void> initialize() async {
    relay1StateNotifier.value = false;
    relay2StateNotifier.value = false;

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
    final payloadRelay1 = relay1StateNotifier.value ? 'ON' : 'OFF';
    final payloadRelay2 = relay2StateNotifier.value ? 'ON' : 'OFF';

    MQTTService.instance.publish(_relay1TopicState, payloadRelay1, retain: retain);
    MQTTService.instance.publish(_relay2TopicState, payloadRelay2, retain: retain);
  }

  void _publishDiscoveryRelayConfigs() {
    if (_discoveryRelayPublished) return;
    _discoveryRelayPublished = true;

    const relay1Config = '''{
      "name": "Relais 1 s504",
      "state_topic": "haade_panel_s504/switch/relay1/state",
      "command_topic": "haade_panel_s504/switch/relay1/set",
      "object_id": "haade_panel_s504_relay1",
      "unique_id": "haade_panel_s504_relay1",
      "availability": {
        "topic": "haade_panel_s504/switch/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      },
      "payload_on": "ON",
      "payload_off": "OFF",
      "state_on": "ON",
      "state_off": "OFF",
      "device": {
        "identifiers": ["haade_panel_s504"],
        "name": "Haade Panel s504",
        "model": "s504",
        "manufacturer": "HAADE",
        "sw_version": "1.0"
      }
    }''';

    const relay2Config = '''{
      "name": "Relais 2 s504",
      "state_topic": "haade_panel_s504/switch/relay2/state",
      "command_topic": "haade_panel_s504/switch/relay2/set",
      "object_id": "haade_panel_s504_relay2",
      "unique_id": "haade_panel_s504_relay2",
      "availability": {
        "topic": "haade_panel_s504/switch/availability",
        "payload_available": "online",
        "payload_not_available": "offline"
      },
      "payload_on": "ON",
      "payload_off": "OFF",
      "state_on": "ON",
      "state_off": "OFF",
      "device": {
        "identifiers": ["haade_panel_s504"],
        "name": "Haade Panel s504",
        "model": "s504",
        "manufacturer": "HAADE",
        "sw_version": "1.0"
      }
    }''';

    MQTTService.instance.publish('homeassistant/switch/haade_panel_s504_relay1/config', relay1Config, retain: true);
    MQTTService.instance.publish('homeassistant/switch/haade_panel_s504_relay2/config', relay2Config, retain: true);
  }

  Future<void> _onMessage(String topic, String message) async {
    await NotificationService().showNotification(
      'MQTT Switch',
      'Reçu : $topic => $message',
    );

    final isOn = (message.toUpperCase() == 'ON');

    if (topic == _relay1TopicSet) {
      await setRelayState(1, isOn, publishState: true);
    } else if (topic == _relay2TopicSet) {
      await setRelayState(2, isOn, publishState: true);
    }
  }

  Future<void> setRelayState(int relayNumber, bool state, {bool publishState = true}) async {
    try {

      await _platform.invokeMethod('setRelayState', {
        'relay': relayNumber,
        'state': state,
      });


      final payload = state ? 'ON' : 'OFF';

      if (relayNumber == 1) {
        relay1StateNotifier.value = state;
        if (publishState) {
          MQTTService.instance.publish(_relay1TopicState, payload, retain: true);
        }
      } else if (relayNumber == 2) {
        relay2StateNotifier.value = state;
        if (publishState) {
          MQTTService.instance.publish(_relay2TopicState, payload, retain: true);
        }
      }
    } on PlatformException catch (e) {
      await NotificationService().showNotification(
        'Erreur relais',
        'setRelayState: $e',
      );
    }
  }

  Future<void> setAvailability(bool online) async {
    MQTTService.instance.publish(_availabilityTopic, online ? 'ON' : 'OFF', retain: true);
  }

  void dispose() {
    MQTTService.instance.publish(_availabilityTopic, 'offline', retain: true);
  }
}






