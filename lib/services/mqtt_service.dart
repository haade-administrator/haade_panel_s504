import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:haade_panel_s504/services/notification.dart';
import 'package:haade_panel_s504/services/app_localizations_helper.dart';

typedef MessageHandler = void Function(String topic, String message);

Timer? _reconnectTimer;
Timer? _heartbeatTimer;

class MQTTService {
  // 🔁 Singleton
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  static MQTTService get instance => _instance;
  MQTTService._internal();

  bool _hasShownConnectionError = false;
  MqttServerClient? _client;

  final Map<String, void Function(String)> _listeners = {};
  bool _isListening = false;
  MessageHandler? _onMessage;
  VoidCallback? _onConnectedCallback;

  /// 🟢/🔴 État de connexion pour UI
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  /// Topic global LWT
  final String globalAvailabilityTopic = 'haade_panel_s504/availability';

  MqttServerClient get client {
    if (_client == null) {
      throw Exception(AppLocalizationsHelper.loc.mqttInitError);
    }
    return _client!;
  }

  /// Connexion principale avec LWT global
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

    _client = MqttServerClient(broker, 'tablette_flutter_client')
      ..port = port
      ..secure = useSSL
      ..logging(on: true)
      ..keepAlivePeriod = 20
      ..onDisconnected = onDisconnected
      ..onConnected = onConnected
      ..onSubscribed = onSubscribed;

    // LWT global
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('tablette_flutter_client')
        .authenticateAs(username, password)
        .startClean()
        .withWillTopic(globalAvailabilityTopic)
        .withWillMessage('offline') // sera publié si déconnexion brutale
        .withWillQos(MqttQos.atLeastOnce);

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      _setupListener();

      // Publier online dès la connexion
      publish(globalAvailabilityTopic, 'online', retain: true);

      // Heartbeat pour maintenir l'état online
      _startHeartbeat();
    } catch (e) {
      NotificationService().showDefaultNotification(
        'MQTT',
        '${AppLocalizationsHelper.loc.mqttConnectionError} : $e',
      );
      _client!.disconnect();
      rethrow;
    }
  }

  /// Heartbeat périodique pour "online"
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected.value) {
        publish(globalAvailabilityTopic, 'online', retain: true);
      }
    });
  }

  /// Publication
  void publish(String topic, String message, {bool retain = false}) {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) {
      if (!_hasShownConnectionError) {
        NotificationService().showDefaultNotification(
          'MQTT',
          'Le client MQTT est déconnecté. Impossible de publier sur "$topic".',
        );
        _hasShownConnectionError = true;
      }
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!, retain: retain);
  }

  /// Souscription
  void subscribe(String topic, void Function(String) onMessage) {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) return;
    _client!.subscribe(topic, MqttQos.atMostOnce);
    _listeners[topic] = onMessage;
    _setupListener();
  }

  /// Écouteur global
  void _setupListener() {
    if (_isListening || _client?.updates == null) return;

    _client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final recMess = events[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = events[0].topic;

      if (_listeners.containsKey(topic)) {
        _listeners[topic]!(payload);
      } else {
        _onMessage?.call(topic, payload);
      }
    });

    _isListening = true;
  }

  /// Callbacks
  void onConnected() {
    NotificationService().showDefaultNotification('MQTT', '🔌 Connecté au broker MQTT');
    _hasShownConnectionError = false;
    isConnected.value = true;
    _reconnectTimer?.cancel();
    _resubscribeAllTopics();
    _onConnectedCallback?.call();
  }

  void onDisconnected() {
    NotificationService().showDefaultNotification('MQTT', AppLocalizationsHelper.loc.mqttDisconnected);
    isConnected.value = false;
    _heartbeatTimer?.cancel();

    // Reconnexion automatique
    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        NotificationService().showDefaultNotification('MQTT', AppLocalizationsHelper.loc.mqttAttempt);
        try {
          await autoConnectIfConfigured(onConnectedCallback: _onConnectedCallback);
          if (isConnected.value) timer.cancel();
        } catch (e) {
          NotificationService().showDefaultNotification('MQTT', '${AppLocalizationsHelper.loc.mqttNewTentative} $e');
        }
      });
    }
  }

  void onSubscribed(String topic) {
    NotificationService().showDefaultNotification('MQTT', '📡 Abonné au topic : $topic');
  }

  void _resubscribeAllTopics() {
    if (_client == null || _client!.connectionStatus?.state != MqttConnectionState.connected) return;
    for (final topic in _listeners.keys) {
      _client!.subscribe(topic, MqttQos.atMostOnce);
      NotificationService().showDefaultNotification('MQTT', '🔄 Resouscription au topic : $topic');
    }
  }

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
        NotificationService().showDefaultNotification('MQTT', '${AppLocalizationsHelper.loc.mqttAutoConnectionError} : $e');
      }
    }
  }

  /// Déconnexion propre (éviter de publier offline si l’app continue en arrière-plan)
  void disconnect() {
    if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
      _client!.disconnect();
      NotificationService().showDefaultNotification('MQTT', '🔌 Déconnecté proprement');
    }
    isConnected.value = false;
    _isListening = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}







