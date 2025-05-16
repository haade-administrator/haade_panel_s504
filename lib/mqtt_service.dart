import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MQTTService {
  late MqttServerClient client;
  final Map<String, void Function(String)> _listeners = {};
  bool _isListening = false;

  Future<void> connect({
    required String broker,
    required int port,
    required String username,
    required String password,
    required bool useSSL,
  }) async {
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
    } catch (e) {
      print('Erreur de connexion : $e');
      client.disconnect();
      rethrow;
    }
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void subscribe(String topic, void Function(String) onMessage) {
    client.subscribe(topic, MqttQos.atMostOnce);
    _listeners[topic] = onMessage;

    if (!_isListening) {
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final recMess = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final topic = c[0].topic;

        if (_listeners.containsKey(topic)) {
          _listeners[topic]!(payload);
        } else {
          print("Message reçu sur un topic non géré : $topic");
        }
      });
      _isListening = true;
    }
  }

  void onConnected() => print('✅ Connecté au broker MQTT');
  void onDisconnected() => print('❌ Déconnecté du broker MQTT');
  void onSubscribed(String topic) => print('📡 Abonné au topic : $topic');
}


