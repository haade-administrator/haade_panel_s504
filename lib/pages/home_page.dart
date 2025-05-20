import 'package:flutter/material.dart';
import 'mqtt_settings_page.dart';
import 'led_control_page.dart';
import 'sensor_reader_page.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';
import 'package:mqtt_hatab/services/sensor_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MQTTService mqtt = MQTTService.instance;

  @override
  void initState() {
    super.initState();
    mqtt.autoConnectIfConfigured();
    SensorService().initialize(); // Active les capteurs au démarrage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
    'Contrôle MQTT Tablette',
    style: TextStyle(color: Colors.white),
  ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 61, 61),
        actions: [
          // Voyant de connexion MQTT (vert si connecté, rouge sinon)
          ValueListenableBuilder<bool>(
            valueListenable: mqtt.isConnected,
            builder: (context, connected, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.circle,
                  color: connected ? Colors.green : Colors.red,
                  size: 18,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavigationCard(
              context,
              icon: Icons.settings,
              title: 'Paramètres MQTT',
              subtitle: 'Configurer la connexion au broker',
              page: const SettingsPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.lightbulb_outline,
              title: 'Contrôle LEDs',
              subtitle: 'Allumer/Éteindre et changer la couleur',
              page: const LedControlPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.thermostat_outlined,
              title: 'Température & Humidité',
              subtitle: 'Lire les capteurs en temps réel',
              page: const SensorReaderPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, size: 36, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}


