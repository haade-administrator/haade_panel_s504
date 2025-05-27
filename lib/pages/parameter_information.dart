import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:haade_panel_s504/pages/sensors/light_sensor_page.dart';
import 'package:haade_panel_s504/pages/sensors/sensor_reader_page.dart';

class ParameterInformationPage extends StatelessWidget {
  const ParameterInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.sensorSettings),
          bottom: TabBar(
            tabs: [
              Tab(text: loc.tempHumidity, icon: const Icon(Icons.thermostat)),
              Tab(text: loc.brightness, icon: const Icon(Icons.light_mode)),
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

