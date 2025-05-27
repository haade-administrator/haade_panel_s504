import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';
import 'package:mqtt_hatab/services/sensor_service.dart';
import 'package:mqtt_hatab/services/led_service.dart';
import 'package:mqtt_hatab/services/switch_service.dart';
import 'package:mqtt_hatab/services/io_service.dart';
import 'package:mqtt_hatab/services/light_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../l10n/app_localizations.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MQTTService.instance.autoConnectIfConfigured(
    onConnectedCallback: () {
      reinitializeServices();

      // 🔽 Délai pour laisser Flutter rendre au moins un frame avant de minimiser
      Future.delayed(const Duration(seconds: 2), () {
        MyApp.minimizeApp();
      });
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
  LightService.instance.startSensor();
  LightService.instance.publishDiscoveryConfig();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const platform = MethodChannel('com.example.mqtt_hatab/background');

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

      // 🔤 Configuration de la localisation
      localizationsDelegates: const [
        AppLocalizations.delegate, // ton fichier généré automatiquement
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // anglais
        Locale('fr'), // français
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





