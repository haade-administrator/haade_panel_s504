import 'package:flutter/material.dart';
import 'package:mqtt_hatab/services/io_service.dart';

class IoPage extends StatefulWidget {
  const IoPage({Key? key}) : super(key: key);

  @override
  State<IoPage> createState() => _IoPageState();
}

class _IoPageState extends State<IoPage> {

  void _onToggleOutput(int outputNumber, bool newState) {
    IoService.instance.setOutputState(outputNumber, newState);
  }

  Widget _buildOutputSwitch(String title, int outputNumber, ValueNotifier<bool> notifier) {
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
              _onToggleOutput(outputNumber, newValue);
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
        title: const Text('Contrôle des sorties IO'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOutputSwitch('Sortie OUT1', 1, IoService.instance.out1StateNotifier),
            const SizedBox(height: 20),
            _buildOutputSwitch('Sortie OUT2', 2, IoService.instance.out2StateNotifier),
          ],
        ),
      ),
    );
  }
}

