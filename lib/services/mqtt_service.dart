import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:haade_panel_s504/services/notification.dart';

typedef MessageHandler = void Function(String topic, String message);

Timer? _reconnectTimer;

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
  VoidCallback? _onConnectedCallback;

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
    VoidCallback? onConnectedCallback,
  }) async {
    _onMessage = onMessage;
    _onConnectedCallback = onConnectedCallback;

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
      NotificationService().showNotification('MQTT', 'Erreur de connection MQTT : $e');
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
  Future<void> autoConnectIfConfigured({VoidCallback? onConnectedCallback}) async {
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
          onConnectedCallback: onConnectedCallback,
        );
      } catch (e) {
        NotificationService().showNotification('MQTT', 'Connexion automatique échouée : $e');
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
      NotificationService().showNotification('MQTT', 'MQTT client not initialized. Cannot publish to $topic');
      return;
    }

    if (_client!.connectionStatus?.state != MqttConnectionState.connected) {
      NotificationService().showNotification('MQTT', 'MQTT client not initialized. Cannot publish to $topic');
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
      NotificationService().showNotification('MQTT', 'MQTT client not initialized. Cannot subscribe to $topic');
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
      NotificationService().showNotification('MQTT', '🔌 Déconnecté proprement');
    }
    isConnected.value = false;
    _isListening = false;
  }

  /// Callbacks MQTT
  void onConnected() {
    NotificationService().showNotification('MQTT', '🔌 Connecté au broker MQTT');
    isConnected.value = true;
    _reconnectTimer?.cancel(); // On arrête les tentatives si connecté
    _reconnectTimer = null;
    _resubscribeAllTopics();
    _isListening = false; // ← important pour permettre _setupListener de se relancer
    _setupListener();     // ← relance l’écoute MQTT
    _onConnectedCallback?.call();
  }

  void onDisconnected() {
    NotificationService().showNotification('MQTT', '🔌 Déconnecté du broker MQTT');
    isConnected.value = false;
      if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
    _reconnectTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      NotificationService().showNotification('MQTT', '🔁 Tentative de reconnexion MQTT...');
      try {
        await autoConnectIfConfigured(onConnectedCallback: _onConnectedCallback);
        if (isConnected.value) {
          NotificationService().showNotification('MQTT', '✅ Reconnexion réussie');
          timer.cancel(); // On arrête le timer si ça a marché
        }
      } catch (e) {
        NotificationService().showNotification('MQTT', '⏳ Nouvelle tentative dans 10s : $e');
      }
    });
  }
  }

  void onSubscribed(String topic) {
    NotificationService().showNotification('MQTT', '📡 Abonné au topic : $topic');
  }

  void _resubscribeAllTopics() {
  if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) return;

  for (final topic in _listeners.keys) {
    _client!.subscribe(topic, MqttQos.atMostOnce);
    NotificationService().showNotification('MQTT', '🔄 Resouscription au topic : $topic');
   }
  }
}





