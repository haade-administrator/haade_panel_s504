import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwitchRelayPage extends StatefulWidget {
  const SwitchRelayPage({Key? key}) : super(key: key);

  @override
  State<SwitchRelayPage> createState() => _SwitchRelayPageState();
}

class _SwitchRelayPageState extends State<SwitchRelayPage> {
  static const platform = MethodChannel('com.example.relaycontrol/relay');

  bool relay1State = false;
  bool relay2State = false;

  Future<void> toggleRelay(int relayNumber, bool state) async {
    try {
      await platform.invokeMethod(
        'setRelayState',
        {'relay': relayNumber, 'state': state},
      );
    } on PlatformException catch (e) {
      debugPrint("Erreur lors du changement d'état du relais $relayNumber: ${e.message}");
    }
  }

  Widget _buildRelaySwitch(String title, int relayNumber, bool currentState) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        value: currentState,
        onChanged: (bool newValue) {
          setState(() {
            if (relayNumber == 1) {
              relay1State = newValue;
            } else {
              relay2State = newValue;
            }
          });
          toggleRelay(relayNumber, newValue);
        },
        secondary: Icon(
          currentState ? Icons.power : Icons.power_off,
          color: currentState ? Colors.green : Colors.grey,
        ),
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
            _buildRelaySwitch('Relais 1 (IN1)', 1, relay1State),
            const SizedBox(height: 20),
            _buildRelaySwitch('Relais 2 (IN2)', 2, relay2State),
          ],
        ),
      ),
    );
  }
}
