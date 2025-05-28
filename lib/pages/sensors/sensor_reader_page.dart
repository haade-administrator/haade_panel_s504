import 'package:flutter/material.dart';
import 'package:haade_panel_s504/services/sensor_service.dart';
import '../../l10n/app_localizations.dart';

class SensorReaderPage extends StatelessWidget {
  const SensorReaderPage({super.key});

@override
Widget build(BuildContext context) {
  final sensorService = SensorService();
  final loc = AppLocalizations.of(context)!;

  return ValueListenableBuilder<double>(
    valueListenable: sensorService.temperature,
    builder: (context, temp, _) {
      return ValueListenableBuilder<double>(
        valueListenable: sensorService.humidity,
        builder: (context, hum, _) {
          return _buildSensorCard(context, loc, temp, hum);
        },
      );
    },
  );
}

Widget _buildSensorCard(BuildContext context, AppLocalizations loc, double temp, double hum) {
  return Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(context, Icons.thermostat, loc.temperature, '$temp °C'),
          const SizedBox(height: 20),
          _buildRow(context, Icons.water_drop, loc.humidity, '$hum %'),
        ],
      ),
    ),
  );
}

  Widget _buildRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(width: 10),
        Text(
          '$label : ',
          style: const TextStyle(fontSize: 20),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}




