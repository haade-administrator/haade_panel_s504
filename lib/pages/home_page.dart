import 'package:flutter/material.dart';
import 'mqtt_settings_page.dart';
import 'led_control_page.dart';
import 'parameter_information.dart';
import 'switch_relay_page.dart';
import 'io_page.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';
import 'package:mqtt_hatab/services/sensor_service.dart';
import 'package:mqtt_hatab/services/led_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MQTTService mqtt = MQTTService.instance;
  final LedService ledService = LedService();

  @override
  void initState() {
    super.initState();
    // Suppression de l'init LedService ici (fait dans main.dart)
    SensorService().initialize();
    // mqtt.autoConnectIfConfigured() aussi dans main.dart, donc optionnel ici
  }

  @override
  void dispose() {
    ledService.dispose();  // On garde le dispose pour bien détacher les listeners
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
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
              icon: Icons.power_rounded,
              title: 'Relay switch',
              subtitle: 'Control switch relay in live',
              page: const SwitchRelayPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.radio_button_checked,
              title: 'IO Button Control',
              subtitle: 'Control IO Button in live',
              page: const IoPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.settings,
              title: 'Parameter and Information',
              subtitle: 'temp, humidity, lux',
              page: const ParameterInformationPage(),
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



