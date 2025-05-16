import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class LedControlPage extends StatefulWidget {
  const LedControlPage({super.key});

  @override
  _LedControlPageState createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  static const platform = MethodChannel('com.example.elcapi/led');

  // Controllers pour la config MQTT
  final TextEditingController _brokerController =
      TextEditingController(text: 'test.mosquitto.org');
  final TextEditingController _portController = TextEditingController(text: '1883');
  final TextEditingController _usernameController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');
  bool _useSSL = false;

  int red = 0, green = 0, blue = 0;
  final MQTTService mqttService = MQTTService();

  @override
  void dispose() {
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connectMQTT() async {
    try {
      await mqttService.connect(
        broker: _brokerController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
        useSSL: _useSSL,
        onMessage: _handleMQTTMessage,
      );
    } catch (e) {
      print("Erreur connexion MQTT: $e");
    }
  }

  Future<void> _setLed() async {
    try {
      await platform.invokeMethod('setLed', {"r": red, "g": green, "b": blue});
      _publishLedState();
    } on PlatformException catch (e) {
      print("Erreur JNI: ${e.message}");
    }
  }

  void _publishLedState() {
    final payload = '{"r": ${red * 17}, "g": ${green * 17}, "b": ${blue * 17}}';
    mqttService.publish('tablette/led/state', payload);
  }

  void _handleMQTTMessage(String topic, String message) {
    if (topic == 'tablette/led/set') {
      try {
        final data = Map<String, dynamic>.from(mqttService.parseJson(message));
        final r255 = data['r'] ?? 0;
        final g255 = data['g'] ?? 0;
        final b255 = data['b'] ?? 0;
        updateFromMQTT(r255, g255, b255);
      } catch (e) {
        print("Erreur parsing MQTT: $e");
      }
    }
  }

  void updateFromMQTT(int r255, int g255, int b255) {
    setState(() {
      red = (r255 / 17).round().clamp(0, 15);
      green = (g255 / 17).round().clamp(0, 15);
      blue = (b255 / 17).round().clamp(0, 15);
    });
    _setLed();
  }

  Widget _buildSlider(
      String label, int value, ValueChanged<int> onChanged, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value', style: TextStyle(color: color)),
        Slider(
          value: value.toDouble(),
          onChanged: (val) => onChanged(val.toInt()),
          min: 0,
          max: 15,
          divisions: 15,
          activeColor: color,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contrôle LED')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuration MQTT', style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: _brokerController,
              decoration: InputDecoration(labelText: 'Broker MQTT'),
            ),
            TextField(
              controller: _portController,
              decoration: InputDecoration(labelText: 'Port'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SwitchListTile(
              title: Text('Utiliser SSL'),
              value: _useSSL,
              onChanged: (val) => setState(() => _useSSL = val),
            ),
            Center(
              child: ElevatedButton(
                onPressed: _connectMQTT,
                child: Text('Connecter MQTT'),
              ),
            ),
            Divider(height: 40),
            Text('Contrôle des LEDs', style: Theme.of(context).textTheme.titleLarge),
            _buildSlider('Rouge', red, (v) => setState(() => red = v), Colors.red),
            _buildSlider('Vert', green, (v) => setState(() => green = v), Colors.green),
            _buildSlider('Bleu', blue, (v) => setState(() => blue = v), Colors.blue),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _setLed,
                child: Text('Appliquer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

