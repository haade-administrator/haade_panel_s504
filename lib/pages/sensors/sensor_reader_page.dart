import 'package:flutter/material.dart';
import 'package:mqtt_hatab/services/sensor_service.dart';

class SensorReaderPage extends StatelessWidget {
  const SensorReaderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sensorService = SensorService();

    return Scaffold(
      appBar: AppBar(title: const Text("Température & Humidité")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ValueListenableBuilder<double>(
            valueListenable: sensorService.temperature,
            builder: (context, temp, _) {
              return ValueListenableBuilder<double>(
                valueListenable: sensorService.humidity,
                builder: (context, hum, _) {
                  return _buildSensorCard(temp, hum);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSensorCard(double temp, double hum) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow(Icons.thermostat, 'Température', '$temp °C'),
            const SizedBox(height: 20),
            _buildRow(Icons.water_drop, 'Humidité', '$hum %'),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
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


