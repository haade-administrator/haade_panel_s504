import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

// Page de contrôle LED avec MQTT + JNI (méthodes natives Android)
class LedControlPage extends StatefulWidget {
  const LedControlPage({super.key});

  @override
  _LedControlPageState createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  // Canal de communication avec la couche native Android via JNI
  static const platform = MethodChannel('com.example.elcapi/led');

  // Contrôleurs pour les champs de configuration MQTT
  final TextEditingController _brokerController =
      TextEditingController(text: 'test.mosquitto.org');
  final TextEditingController _portController = TextEditingController(text: '1883');
  final TextEditingController _usernameController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');
  bool _useSSL = false; // SSL activé ou non

  // Valeurs de couleurs (4 bits: 0–15)
  int red = 0, green = 0, blue = 0;

  // Service MQTT encapsulé dans une classe
  final MQTTService mqttService = MQTTService();

  @override
  void dispose() {
    // Libération des contrôleurs
    _brokerController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Connexion au broker MQTT
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

  /// Envoi de la couleur sélectionnée à la LED via JNI + MQTT
  Future<void> _setLed() async {
    try {
      // Appel JNI pour changer la couleur
      await platform.invokeMethod('setLed', {"r": red, "g": green, "b": blue});
      // Publication de l'état LED en MQTT
      _publishLedState();
    } on PlatformException catch (e) {
      print("Erreur JNI: ${e.message}");
    }
  }

  /// Publie l’état actuel de la LED sur le topic `tablette/led/state`
  void _publishLedState() {
    final payload = '{"r": ${red * 17}, "g": ${green * 17}, "b": ${blue * 17}}';
    mqttService.publish('tablette/led/state', payload);
  }

  /// Réagit aux messages MQTT entrants
  void _handleMQTTMessage(String topic, String message) {
    if (topic == 'tablette/led/set') {
      try {
        // Parsing JSON
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

  /// Met à jour l'interface avec les nouvelles valeurs reçues en MQTT
  void updateFromMQTT(int r255, int g255, int b255) {
    setState(() {
      red = (r255 / 17).round().clamp(0, 15);
      green = (g255 / 17).round().clamp(0, 15);
      blue = (b255 / 17).round().clamp(0, 15);
    });
    _setLed();
  }

  /// Création d’un slider pour chaque composante RGB
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

  /// Construction de l'interface graphique
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contrôle LED')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration MQTT
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
            // Contrôle LED
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


