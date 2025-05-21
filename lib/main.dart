import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';
import 'package:mqtt_hatab/services/sensor_service.dart';
import 'package:mqtt_hatab/services/led_service.dart';
import 'package:mqtt_hatab/services/switch_service.dart';
import 'package:mqtt_hatab/services/io_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisations nécessaires avant de lancer l'app
  await MQTTService.instance.autoConnectIfConfigured();
  SensorService().initialize();
  LedService().initialize();
  SwitchService.instance.initialize();
  IoService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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


