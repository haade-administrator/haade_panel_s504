import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

typedef MessageHandler = void Function(String topic, String message);

class MQTTService {
  // 🔁 Singleton
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  static MQTTService get instance => _instance;
  MQTTService._internal();

  MqttServerClient? _client;
  MqttServerClient get client {
    if (_client == null) {
      throw Exception('MQTT client not initialized. Call connect() first.');
    }
    return _client!;
  }

  final Map<String, void Function(String)> _listeners = {};
  bool _isListening = false;
  MessageHandler? _onMessage;

  /// 🟢/🔴 État de connexion pour affichage UI
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  /// Connexion principale
  Future<void> connect({
    required String broker,
    required int port,
    required String username,
    required String password,
    required bool useSSL,
    MessageHandler? onMessage,
  }) async {
    _onMessage = onMessage;

    _client = MqttServerClient(broker, 'tablette_flutter_client');
    _client!.port = port;
    _client!.logging(on: true);
    _client!.secure = useSSL;
    _client!.keepAlivePeriod = 20;
    _client!.onDisconnected = onDisconnected;
    _client!.onConnected = onConnected;
    _client!.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('tablette_flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      _setupListener();
    } catch (e) {
      print('❌ Erreur de connexion MQTT : $e');
      _client!.disconnect();
      rethrow;
    }
  }

  /// Connexion avec callback obligatoire
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

  /// Connexion automatique si les paramètres sont disponibles
  Future<void> autoConnectIfConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final broker = prefs.getString('mqtt_broker');
    final port = prefs.getInt('mqtt_port');
    final username = prefs.getString('mqtt_username');
    final password = prefs.getString('mqtt_password');
    final useSSL = prefs.getBool('mqtt_ssl') ?? false;

    if (broker != null &&
        port != null &&
        username != null &&
        password != null) {
      try {
        await connect(
          broker: broker,
          port: port,
          username: username,
          password: password,
          useSSL: useSSL,
        );
      } catch (e) {
        print('⚠️ Connexion automatique échouée : $e');
      }
    }
  }

  /// Mise en place de l'écouteur global
  void _setupListener() {
    if (_isListening || _client?.updates == null) return;

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
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

  /// Publication sur un topic
  void publish(String topic, String message, {bool retain = false}) {
    if (_client == null) {
      print('❌ MQTT client not initialized. Cannot publish to $topic');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!,
        retain: retain);
  }

  /// Souscription à un topic
  void subscribe(String topic, void Function(String) onMessage) {
    if (_client == null) {
      print('❌ MQTT client not initialized. Cannot subscribe to $topic');
      return;
    }

    _client!.subscribe(topic, MqttQos.atMostOnce);
    _listeners[topic] = onMessage;
    _setupListener(); // Toujours assurer que l'écouteur est en place
  }

  /// Décode un message JSON
  Map<String, dynamic> parseJson(String message) => jsonDecode(message);

  /// Déconnexion propre
  void disconnect() {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.disconnect();
      print('🔌 Déconnecté proprement');
    }
    isConnected.value = false;
    _isListening = false;
  }

  /// Callbacks MQTT
  void onConnected() {
    print('✅ Connecté au broker MQTT');
    isConnected.value = true;
  }

  void onDisconnected() {
    print('❌ Déconnecté du broker MQTT');
    isConnected.value = false;
  }

  void onSubscribed(String topic) {
    print('📡 Abonné au topic : $topic');
  }
}



