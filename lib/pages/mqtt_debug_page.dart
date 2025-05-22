import 'package:flutter/material.dart';
import 'package:mqtt_hatab/services/mqtt_debug_service.dart';

class MqttDebugPage extends StatelessWidget {
  const MqttDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MQTT Debug')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => MqttDebugService.instance.publishTestMessage(),
              child: const Text('Publier test_topic'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => MqttDebugService.instance.publishIoFakeState(1, true),
              child: const Text('Simuler IO1 ON'),
            ),
            ElevatedButton(
              onPressed: () => MqttDebugService.instance.publishIoFakeState(1, false),
              child: const Text('Simuler IO1 OFF'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => MqttDebugService.instance.publishIoFakeState(2, true),
              child: const Text('Simuler IO2 ON'),
            ),
            ElevatedButton(
              onPressed: () => MqttDebugService.instance.publishIoFakeState(2, false),
              child: const Text('Simuler IO2 OFF'),
            ),
          ],
        ),
      ),
    );
  }
}
