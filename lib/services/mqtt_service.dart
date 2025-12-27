import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:haade_panel_s504/services/notification.dart';
import 'package:haade_panel_s504/services/app_localizations_helper.dart';

typedef MessageHandler = void Function(String topic, String message);

Timer? _reconnectTimer;
Timer? _heartbeatTimer;

/// Interface pour les services notifiés après reconnexion MQTT
abstract class MqttReconnectAware {
  void onMqttReconnected();
}

class MQTTService {
  // -------------------- SINGLETON --------------------
  static final MQTTService _instance = MQTTService._internal();
  factory MQTTService() => _instance;
  static MQTTService get instance => _instance;
  MQTTService._internal();

  // -------------------- CLIENT --------------------
  MqttServerClient? _client;

  /// Subscription MQTT (ANTI-LEAK)
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>?
      _updatesSubscription;

  bool _hasShownConnectionError = false;

  /// Listeners par topic
  final Map<String, void Function(String)> _listeners = {};

  /// Callback global
  VoidCallback? _onConnectedCallback;

  /// Callback messages non gérés
  MessageHandler? _onMessage;

  /// État de connexion pour l'UI
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  /// Availability globale
  final String globalAvailabilityTopic = 'haade_panel_s504/availability';

  /// Services à notifier après reconnexion
  final List<MqttReconnectAware> _reconnectAwareServices = [];

  /// ClientId unique
  late final String _clientId =
      'haade_panel_s504_${Random().nextInt(999999)}';

  // -------------------- REGISTER SERVICES --------------------
  void registerReconnectAware(MqttReconnectAware service) {
    if (!_reconnectAwareServices.contains(service)) {
      _reconnectAwareServices.add(service);
    }
  }

  // -------------------- CONNECT --------------------
  Future<void> connect({
    required String broker,
    required int port,
    required String username,
    required String password,
    required bool useSSL,
    MessageHandler? onMessage,
    VoidCallback? onConnectedCallback,
  }) async {
    // 🔥 Nettoyage complet avant reconnexion
    await _cleanupClient();

    _onMessage = onMessage;
    _onConnectedCallback = onConnectedCallback;

    _client = MqttServerClient(broker, _clientId)
      ..port = port
      ..secure = useSSL
      ..logging(on: false)
      ..keepAlivePeriod = 20
      ..onDisconnected = _onDisconnected
      ..onConnected = _onConnected
      ..onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(username, password)
        .startClean()
        .withWillTopic(globalAvailabilityTopic)
        .withWillMessage('offline')
        .withWillQos(MqttQos.atLeastOnce)
        .withWillRetain();

    _client!.connectionMessage = connMessage;

    try {
      await _client!.connect();
      _setupListener();
      publish(globalAvailabilityTopic, 'online', retain: true);
      _startHeartbeat();
    } catch (e) {
      NotificationService().showDefaultNotification(
        'MQTT',
        '${AppLocalizationsHelper.loc.mqttConnectionError} : $e',
      );
      await _cleanupClient();
      rethrow;
    }
  }

  // -------------------- CLEANUP --------------------
  Future<void> _cleanupClient() async {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();

    await _updatesSubscription?.cancel();
    _updatesSubscription = null;

    _client?.disconnect();
    _client = null;

    isConnected.value = false;
  }

  // -------------------- HEARTBEAT --------------------
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
      if (isConnected.value) {
        publish(globalAvailabilityTopic, 'online', retain: true);
      }
    });
  }

  // -------------------- PUBLISH --------------------
  void publish(String topic, String message, {bool retain = false}) {
    if (_client?.connectionStatus?.state !=
        MqttConnectionState.connected) {
      if (!_hasShownConnectionError) {
        NotificationService().showDefaultNotification(
          'MQTT',
          'Client MQTT déconnecté → publish ignoré ($topic)',
        );
        _hasShownConnectionError = true;
      }
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    _client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: retain,
    );
  }

  // -------------------- SUBSCRIBE --------------------
  void subscribe(String topic, void Function(String) onMessage) {
    _listeners[topic] = onMessage;

    if (_client?.connectionStatus?.state ==
        MqttConnectionState.connected) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }

    _setupListener();
  }

  void _resubscribeAllTopics() {
    if (_client?.connectionStatus?.state !=
        MqttConnectionState.connected) return;

    for (final topic in _listeners.keys) {
      _client!.subscribe(topic, MqttQos.atLeastOnce);
    }
  }

  // -------------------- LISTENER --------------------
  void _setupListener() {
    if (_client?.updates == null) return;

    // 🔥 ANTI-LEAK : un seul listener actif
    _updatesSubscription?.cancel();

    _updatesSubscription =
        _client!.updates!.listen((events) {
      final recMess = events.first.payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(
              recMess.payload.message);
      final topic = events.first.topic;

      if (_listeners.containsKey(topic)) {
        _listeners[topic]!(payload);
      } else {
        _onMessage?.call(topic, payload);
      }
    });
  }

  // -------------------- CALLBACKS --------------------
  void _onConnected() {
    isConnected.value = true;
    _hasShownConnectionError = false;
    _reconnectTimer?.cancel();

    _setupListener();
    publish(globalAvailabilityTopic, 'online', retain: true);
    _resubscribeAllTopics();

    for (final service in _reconnectAwareServices) {
      try {
        service.onMqttReconnected();
      } catch (e) {
        debugPrint('Reconnect error on $service → $e');
      }
    }

    _onConnectedCallback?.call();

    NotificationService()
        .showDefaultNotification('MQTT', '🔌 Connecté');
  }

  void _onDisconnected() {
    isConnected.value = false;
    _heartbeatTimer?.cancel();

    _updatesSubscription?.cancel();
    _updatesSubscription = null;

    NotificationService().showDefaultNotification(
      'MQTT',
      AppLocalizationsHelper.loc.mqttDisconnected,
    );

    if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
      _reconnectTimer =
          Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          await autoConnectIfConfigured(
              onConnectedCallback: _onConnectedCallback);
        } catch (_) {}
      });
    }
  }

  void _onSubscribed(String topic) {
    debugPrint('MQTT subscribed → $topic');
  }

  // -------------------- AUTO CONNECT --------------------
  Future<void> autoConnectIfConfigured(
      {VoidCallback? onConnectedCallback}) async {
    if (_client?.connectionStatus?.state ==
        MqttConnectionState.connecting) return;

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
      await connect(
        broker: broker,
        port: port,
        username: username,
        password: password,
        useSSL: useSSL,
        onConnectedCallback: onConnectedCallback,
      );
    }
  }

  // -------------------- DISCONNECT --------------------
  void disconnect() async {
    await _cleanupClient();
  }
}










