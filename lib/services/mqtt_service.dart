import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';

typedef MessageHandler = void Function(String topic, String message);

class MQTTService {
  // 🔁 Singleton standard
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;

  // ➕ Pour accéder via MQTTService.instance
  static MQTTService get instance => _instance;

  MQTTService._internal();

  late MqttServerClient client;
  final Map<String, void Function(String)> _listeners = {};
  bool _isListening = false;
  MessageHandler? _onMessage;

  Future<void> connect({
    required String broker,
    required int port,
    required String username,
    required String password,
    required bool useSSL,
    MessageHandler? onMessage,
  }) async {
    _onMessage = onMessage;

    client = MqttServerClient(broker, 'tablette_flutter_client');
    client.port = port;
    client.logging(on: true);
    client.secure = useSSL;
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('tablette_flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    try {
      await client.connect();
      _publishDiscoveryMessage();
      _setupListener();
    } catch (e) {
      print('❌ Erreur de connexion MQTT : $e');
      client.disconnect();
      rethrow;
    }
  }

  Future<void> connectWithCallback({
    required String broker,
    required int port,
    required String username,
    required String password,
    required bool useSSL,
    required MessageHandler onMessage,
  }) async {
    await connect(
      broker: broker,
      port: port,
      username: username,
      password: password,
      useSSL: useSSL,
      onMessage: onMessage,
    );
  }

  void _setupListener() {
    if (!_isListening && client.updates != null) {
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final topic = c[0].topic;

        if (_listeners.containsKey(topic)) {
          _listeners[topic]!(payload);
        } else {
          _onMessage?.call(topic, payload);
        }
      });
      _isListening = true;
    }
  }

  void publish(String topic, String message, {bool retain = false}) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void subscribe(String topic, void Function(String) onMessage) {
    client.subscribe(topic, MqttQos.atMostOnce);
    _listeners[topic] = onMessage;
    _setupListener(); // Assure que le listener est actif
  }

  Map<String, dynamic> parseJson(String message) => jsonDecode(message);

  void _publishDiscoveryMessage() {
    final configPayload = {
      "name": "ELC SMT101",
      "unique_id": "elc_smt_101",
      "command_topic": "tablette/led/set",
      "state_topic": "tablette/led/state",
      "schema": "json",
      "brightness": true,
      "rgb": true,
      "device": {
        "identifiers": ["tablette_mqtt"],
        "name": "Tablette MQTT",
        "manufacturer": "ELC",
        "model": "Android LED Control"
      }
    };
    final payload = json.encode(configPayload);
    publish("homeassistant/light/tablette_led/config", payload);
  }

  /// Déconnexion propre
  void disconnect() {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.disconnect();
      print('🔌 Déconnecté proprement');
    }
    _isListening = false;
  }

  void onConnected() => print('✅ Connecté au broker MQTT');
  void onDisconnected() => print('❌ Déconnecté du broker MQTT');
  void onSubscribed(String topic) => print('📡 Abonné au topic : $topic');
}
