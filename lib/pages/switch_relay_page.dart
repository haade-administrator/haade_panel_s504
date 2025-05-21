import 'package:flutter/material.dart';
import 'package:mqtt_hatab/services/switch_service.dart';

class SwitchRelayPage extends StatefulWidget {
  const SwitchRelayPage({Key? key}) : super(key: key);

  @override
  State<SwitchRelayPage> createState() => _SwitchRelayPageState();
}

class _SwitchRelayPageState extends State<SwitchRelayPage> {

  void _onToggleRelay(int relayNumber, bool newState) {
    SwitchService.instance.setRelayState(relayNumber, newState);
  }

  Widget _buildRelaySwitch(String title, int relayNumber, ValueNotifier<bool> notifier) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, currentState, _) {
          return SwitchListTile(
            title: Text(title, style: const TextStyle(fontSize: 18)),
            value: currentState,
            onChanged: (bool newValue) {
              _onToggleRelay(relayNumber, newValue);
            },
            secondary: Icon(
              currentState ? Icons.power : Icons.power_off,
              color: currentState ? Colors.green : Colors.grey,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contrôle des relais'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRelaySwitch('Relais 1 (IN1)', 1, SwitchService.instance.relay1StateNotifier),
            const SizedBox(height: 20),
            _buildRelaySwitch('Relais 2 (IN2)', 2, SwitchService.instance.relay2StateNotifier),
          ],
        ),
      ),
    );
  }
}

