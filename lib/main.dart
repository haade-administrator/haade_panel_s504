import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'pages/home_page.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';
import 'package:haade_panel_s504/services/sensor_service.dart';
import 'package:haade_panel_s504/services/led_service.dart';
import 'package:haade_panel_s504/services/switch_service.dart';
import 'package:haade_panel_s504/services/io_service.dart';
import 'package:haade_panel_s504/services/light_service.dart';
import 'package:haade_panel_s504/services/notification.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize local notifications
  await NotificationService().initialize();

  // ✅ Request notification permission
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // ✅ Request microphone permission
  if (await Permission.microphone.isDenied) {
    await Permission.microphone.request();
  }

  // ✅ Request phone permission
  if (await Permission.phone.isDenied) {
    await Permission.phone.request();
  }

  // 🔆 Start light sensor immediately
  LightService.instance.startSensor();
  LightService.instance.publishDiscoveryConfig();

  // ✅ Connect to MQTT if configured
  await MQTTService.instance.autoConnectIfConfigured(
    onConnectedCallback: () {
      reinitializeServices();

      // 🔽 Optional: minimize after startup
      // Future.delayed(const Duration(seconds: 2), () {
      //   MyApp.minimizeApp();
      // });
    },
  );

  runApp(const MyApp());
}

/// Relance tous les services dépendant du MQTT
void reinitializeServices() {
  SensorService().initialize();
  LedService().initialize();
  SwitchService.instance.initialize();
  IoService.instance.initialize();
  LightService.instance.publishDiscoveryConfig(); // OK ici, mais plus de startSensor()
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const platform = MethodChannel('com.example.haade_panel_s504/background');

  /// Fonction pour minimiser l'application (Android)
  static Future<void> minimizeApp() async {
    try {
      await platform.invokeMethod('minimizeApp');
    } on PlatformException catch (e) {
      debugPrint("Erreur lors de la tentative de minimisation : ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tablette MQTT',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,

      // 🔤 Localisation
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
    );
  }
}






