import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';
import 'package:haade_panel_s504/services/notification.dart';

class SwitchService implements MqttReconnectAware {
  static final SwitchService instance = SwitchService._internal();
  factory SwitchService() => instance;
  SwitchService._internal() {
    // Enregistrer auprès de MQTTService pour reconnexion
    MQTTService.instance.registerReconnectAware(this);
  }

  static const _platform = MethodChannel('com.example.relaycontrol/relay');

  final String _relay1TopicSet = 'haade_panel_s504/switch/relay1/set';
  final String _relay1TopicState = 'haade_panel_s504/switch/relay1/state';
  final String _relay2TopicSet = 'haade_panel_s504/switch/relay2/set';
  final String _relay2TopicState = 'haade_panel_s504/switch/relay2/state';

  final String _availabilityTopic = 'haade_panel_s504/switch/availability';

  final ValueNotifier<bool> relay1StateNotifier = ValueNotifier(false);
  final ValueNotifier<bool> relay2StateNotifier = ValueNotifier(false);

  bool _discoveryRelayPublished = false;

  Future<void> initialize() async {
    relay1StateNotifier.value = false;
    relay2StateNotifier.value = false;

    _publishDiscoveryRelayConfigs();

    // Publier availability
    MQTTService.instance.publish(_availabilityTopic, 'online', retain: true);

    // Publier l’état initial
    _publishRelayStates(retain: true);

    // S’abonner aux topics de commande avec closure
    _subscribeToTopics();
  }

  void _subscribeToTopics() {
    MQTTService.instance.subscribe(
      _relay1TopicSet,
      (msg) => _onMessageHandler(msg, _relay1TopicSet),
    );
    MQTTService.instance.subscribe(
      _relay2TopicSet,
      (msg) => _onMessageHandler(msg, _relay2TopicSet),
    );
  }

  void _publishRelayStates({bool retain = false}) {
    MQTTService.instance.publish(
      _relay1TopicState,
      relay1StateNotifier.value ? 'ON' : 'OFF',
      retain: retain,
    );
    MQTTService.instance.publish(
      _relay2TopicState,
      relay2StateNotifier.value ? 'ON' : 'OFF',
      retain: retain,
    );
  }

  void _publishDiscoveryRelayConfigs() {
    if (_discoveryRelayPublished) return;
    _discoveryRelayPublished = true;

    const relay1Config = '''{ ... }'''; // ton JSON complet
    const relay2Config = '''{ ... }'''; // ton JSON complet

    MQTTService.instance.publish(
      'homeassistant/switch/haade_panel_s504_relay1/config',
      relay1Config,
      retain: true,
    );
    MQTTService.instance.publish(
      'homeassistant/switch/haade_panel_s504_relay2/config',
      relay2Config,
      retain: true,
    );
  }

  Future<void> _onMessageHandler(String message, String topic) async {
    final isOn = message.toUpperCase() == 'ON';
    if (topic == _relay1TopicSet) {
      await setRelayState(1, isOn, publishState: true);
    } else if (topic == _relay2TopicSet) {
      await setRelayState(2, isOn, publishState: true);
    }
  }

  Future<void> setRelayState(int relayNumber, bool state, {bool publishState = true}) async {
    try {
      await _platform.invokeMethod('setRelayState', {'relay': relayNumber, 'state': state});
      if (relayNumber == 1) {
        relay1StateNotifier.value = state;
        if (publishState) MQTTService.instance.publish(_relay1TopicState, state ? 'ON' : 'OFF', retain: true);
      } else if (relayNumber == 2) {
        relay2StateNotifier.value = state;
        if (publishState) MQTTService.instance.publish(_relay2TopicState, state ? 'ON' : 'OFF', retain: true);
      }
    } on PlatformException catch (e) {
      await NotificationService().showSwNotification('Erreur relais', 'setRelayState: $e');
    }
  }

  Future<void> setAvailability(bool online) async {
    MQTTService.instance.publish(_availabilityTopic, online ? 'ON' : 'OFF', retain: true);
  }

  @override
  void onMqttReconnected() {
    // 1️⃣ Resubscribe d’abord
    _subscribeToTopics();

    // 2️⃣ Republier l’état
    _publishRelayStates(retain: true);

    // 3️⃣ Forcer le hardware selon l’état local
    setRelayState(1, relay1StateNotifier.value, publishState: false);
    setRelayState(2, relay2StateNotifier.value, publishState: false);
  }
}










