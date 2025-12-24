import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:haade_panel_s504/services/app_localizations_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// ➤ Initialisation du plugin avec des noms de canaux **figés**
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);

    // Création manuelle des canaux avec des NOMS STATIQUES
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'notify_switch_state',
          'Switch',
          description: 'Notifications for switch states',
          importance: Importance.low,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'notify_io_state',
          'I/O',
          description: 'Notifications for I/O states',
          importance: Importance.low,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'notify_luminosity_state',
          'Luminosity',
          description: 'Notifications for light sensor',
          importance: Importance.low,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'default_channel',
          'Default',
          description: 'General notifications',
          importance: Importance.high,
        ),
      );
    }
  }

  /// ➤ Détails de notification — descriptions traduites (OK)
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

  /// ➤ Notifications spécialisées
  Future<void> showDefaultNotification(String title, String body) async {
    final details = NotificationDetails(android: defaultDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> showSwNotification(String title, String body) async {
    final details = NotificationDetails(android: switchDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> showIoNotification(String title, String body) async {
    final details = NotificationDetails(android: ioDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

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





