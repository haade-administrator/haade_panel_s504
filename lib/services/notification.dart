import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:haade_panel_s504/services/app_localizations_helper.dart';

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

  /// ➤ Getters dynamiques pour inclure la traduction complète
  AndroidNotificationDetails get switchDetails => AndroidNotificationDetails(
        'notify_switch_state',
        AppLocalizationsHelper.loc.notificationSwitch,
        channelDescription: AppLocalizationsHelper.loc.notificationDescriptionSwitch,
        importance: Importance.high,
        priority: Priority.high,
      );

  AndroidNotificationDetails get ioDetails => AndroidNotificationDetails(
        'notify_io_state',
        AppLocalizationsHelper.loc.notificationIo,
        channelDescription: AppLocalizationsHelper.loc.notificationDescriptionIo,
        importance: Importance.high,
        priority: Priority.high,
      );

  AndroidNotificationDetails get luminosityDetails => AndroidNotificationDetails(
        'notify_luminosity_state',
        AppLocalizationsHelper.loc.notificationLuminosity,
        channelDescription: AppLocalizationsHelper.loc.notificationDescriptionLuminosity,
        importance: Importance.high,
        priority: Priority.high,
      );

  AndroidNotificationDetails get defaultDetails => AndroidNotificationDetails(
        'default_channel',
        AppLocalizationsHelper.loc.notificationDefault,
        channelDescription: AppLocalizationsHelper.loc.notificationDescriptionDefault,
        importance: Importance.high,
        priority: Priority.high,
      );

  /// ➤ Notification générique (canal par défaut)
  Future<void> showDefaultNotification(String title, String body) async {
    final details = NotificationDetails(android: defaultDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// ➤ Notification pour Switch
  Future<void> showSwNotification(String title, String body) async {
    final details = NotificationDetails(android: switchDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// ➤ Notification pour IO
  Future<void> showIoNotification(String title, String body) async {
    final details = NotificationDetails(android: ioDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  /// ➤ Notification pour capteur de luminosité
  Future<void> showLuminosityNotification(String title, String body) async {
    final details = NotificationDetails(android: luminosityDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}



