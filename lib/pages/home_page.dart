import 'package:flutter/material.dart';
import 'mqtt_settings_page.dart';
import 'led_control_page.dart';
import 'parameter_information.dart';
import 'switch_relay_page.dart';
import 'io_page.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';
import 'package:haade_panel_s504/services/sensor_service.dart';
import 'package:haade_panel_s504/services/led_service.dart';
import '../main.dart'; // Import pour accéder à MyApp.minimizeApp()
import '../l10n/app_localizations.dart';

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
    SensorService().initialize();
  }

  @override
  void dispose() {
    ledService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.white),
          tooltip: loc.minimizeAppTooltip,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.appWillMinimize),
                duration: const Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              MyApp.minimizeApp();
            });
          },
        ),
        title: Text(
          loc.title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 61, 61),
        actions: [
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
              title: loc.mqttSettingsTitle,
              subtitle: loc.mqttSettingsSubtitle,
              page: const SettingsPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.lightbulb_outline,
              title: loc.ledControlTitle,
              subtitle: loc.ledControlSubtitle,
              page: const LedControlPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.power_rounded,
              title: loc.relaySwitchTitle,
              subtitle: loc.relaySwitchSubtitle,
              page: const SwitchRelayPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.radio_button_checked,
              title: loc.ioButtonControlTitle,
              subtitle: loc.ioButtonControlSubtitle,
              page: const IoPage(),
            ),
            const SizedBox(height: 20),
            _buildNavigationCard(
              context,
              icon: Icons.settings,
              title: loc.parameterInformationTitle,
              subtitle: loc.parameterInformationSubtitle,
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





