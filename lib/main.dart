import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/home_page.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';
import 'package:mqtt_hatab/services/sensor_service.dart';
import 'package:mqtt_hatab/services/led_service.dart';
import 'package:mqtt_hatab/services/switch_service.dart';
import 'package:mqtt_hatab/services/io_service.dart';
import 'package:mqtt_hatab/services/light_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisations nécessaires avant de lancer l'app
  await MQTTService.instance.autoConnectIfConfigured();
  SensorService().initialize();
  LedService().initialize();
  SwitchService.instance.initialize();
  IoService.instance.initialize();
  LightService.instance.startSensor();
  LightService.instance.publishDiscoveryConfig();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const platform = MethodChannel('com.example.mqtt_hatab/background');

  /// Fonction pour minimiser l'application
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
    );
  }
}



