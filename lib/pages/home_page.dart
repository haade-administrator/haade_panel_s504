import 'package:flutter/material.dart';
import 'settings_page.dart';
import 'led_control_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contrôle MQTT Tablette')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Paramètres MQTT'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => SettingsPage())),
            ),
            ElevatedButton(
              child: Text('Contrôle LEDs'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => LedControlPage())),
            ),
          ],
        ),
      ),
    );
  }
}
