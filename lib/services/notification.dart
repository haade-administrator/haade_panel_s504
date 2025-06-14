import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// ➤ Initialisation du plugin
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
  }


  static const AndroidNotificationDetails _switchDetails = AndroidNotificationDetails(
    'notify_switch_state',
    'Notifications switch',
    channelDescription: 'Notifications pour l’état des Switch',
    importance: Importance.high,
    priority: Priority.high,
  );
  /// ➤ Définir les canaux Android
  static const AndroidNotificationDetails _ioDetails = AndroidNotificationDetails(
    'notify_io_state',
    'Notifications I/O',
    channelDescription: 'Notifications pour l’état des IOs',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const AndroidNotificationDetails _luminosityDetails = AndroidNotificationDetails(
    'notify_luminosity_state',
    'Notifications Light sensor',
    channelDescription: 'Notifications pour l’état du capteur de luminosité',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const AndroidNotificationDetails _defaultDetails = AndroidNotificationDetails(
    'default_channel',
    'Default Mqtt Notifications',
    channelDescription: 'MQTT et Notifications par défaut',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// ➤ Notification générique (canal par défaut)
  Future<void> showDefaultNotification(String title, String body) async {
    const details = NotificationDetails(android: _defaultDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> showSwNotification(String title, String body) async {
    const details = NotificationDetails(android: _switchDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// ➤ Notification pour IO
  Future<void> showIoNotification(String title, String body) async {
    const details = NotificationDetails(android: _ioDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// ➤ Notification pour capteur de luminosité
  Future<void> showLuminosityNotification(String title, String body) async {
    const details = NotificationDetails(android: _luminosityDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

