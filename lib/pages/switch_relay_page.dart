import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart'; // Import de la classe de localisation
import 'package:mqtt_hatab/services/switch_service.dart';

class SwitchRelayPage extends StatefulWidget {
  const SwitchRelayPage({super.key});

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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.relayControl), // Traduction
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRelaySwitch(loc.relay1Label, 1, SwitchService.instance.relay1StateNotifier),
            const SizedBox(height: 20),
            _buildRelaySwitch(loc.relay2Label, 2, SwitchService.instance.relay2StateNotifier),
          ],
        ),
      ),
    );
  }
}


