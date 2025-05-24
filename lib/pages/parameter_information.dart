import 'package:flutter/material.dart';
import 'package:mqtt_hatab/pages/sensors/light_sensor_page.dart';
import 'package:mqtt_hatab/pages/sensors/sensor_reader_page.dart';

class ParameterInformationPage extends StatelessWidget {
  const ParameterInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres Capteurs'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Temp/Humidité', icon: Icon(Icons.thermostat)),
              Tab(text: 'Luminosité', icon: Icon(Icons.light_mode)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SensorReaderPage(),
            LightSensorPage(),
          ],
        ),
      ),
    );
  }
}
