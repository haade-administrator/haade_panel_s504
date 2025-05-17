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

  // Valeurs de couleurs (4 bits: 0–15)
  int red = 0, green = 0, blue = 0;

  @override
  void initState() {
    super.initState();
    // Publier la config MQTT discovery pour Home Assistant au démarrage
    _publishDiscoveryConfig();

    // S'abonner au topic de commande MQTT et gérer les messages entrants
    MQTTService.instance.subscribe('tablette/led/set', _handleMQTTMessage);
  }

  /// Publie la configuration MQTT discovery pour Home Assistant
  void _publishDiscoveryConfig() {
    const configPayload = '''
{
  "name": "LED Tablette",
  "unique_id": "tablette_led_01",
  "object_id": "led_tablette",
  "state_topic": "tablette/led/state",
  "command_topic": "tablette/led/set",
  "availability": [
    {
      "topic": "tablette/availability",
      "payload_available": "online",
      "payload_not_available": "offline"
    }
  ],
  "schema": "json",
  "brightness": true,
  "brightness_scale": 255,
  "color_mode": "rgb",
  "supported_color_modes": ["rgb"],
  "device": {
    "identifiers": ["tablette_led_01"],
    "manufacturer": "MonFabricant",
    "model": "LED Controller V1",
    "name": "LED Tablette",
    "sw_version": "1.0"
  },
  "effect": false
}
''';

    MQTTService.instance.publish(
      'homeassistant/light/tablette_led/config',
      configPayload,
      retain: true, // important pour que HA garde la config
    );
  }

  /// Envoi de la couleur sélectionnée à la LED via JNI + MQTT
  Future<void> _setLed() async {
    try {
      // Appel JNI pour changer la couleur
      await platform.invokeMethod('setLed', {"r": red, "g": green, "b": blue});
      // Publication de l'état LED en MQTT avec format HA
      _publishLedState();
    } on PlatformException catch (e) {
      print("Erreur JNI: ${e.message}");
    }
  }

  /// Publie l’état actuel de la LED sur le topic `tablette/led/state` au format Home Assistant
  void _publishLedState() {
    final isOn = (red + green + blue) > 0;
    final brightness = ((red + green + blue) / 45 * 255).round().clamp(0, 255); // max 15*3=45
    final payload = '''
{
  "state": "${isOn ? "ON" : "OFF"}",
  "brightness": $brightness,
  "color": {
    "r": ${red * 17},
    "g": ${green * 17},
    "b": ${blue * 17}
  }
}
''';

    MQTTService.instance.publish('tablette/led/state', payload);
  }

  /// Réagit aux messages MQTT entrants sur `tablette/led/set`
  void _handleMQTTMessage(String message) {
      try {
        final data = Map<String, dynamic>.from(MQTTService.instance.parseJson(message));
        final r255 = data['r'] ?? 0;
        final g255 = data['g'] ?? 0;
        final b255 = data['b'] ?? 0;
        updateFromMQTT(r255, g255, b255);
      } catch (e) {
        print("Erreur parsing MQTT: $e");
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
          onChanged: (val) {
            final newValue = val.toInt();
            onChanged(newValue);
            _setLed(); // Mise à jour automatique
          },
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
      appBar: AppBar(title: const Text('Contrôle LED')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contrôle des LEDs', style: Theme.of(context).textTheme.titleLarge),
            _buildSlider('Rouge', red, (v) => setState(() => red = v), Colors.red),
            _buildSlider('Vert', green, (v) => setState(() => green = v), Colors.green),
            _buildSlider('Bleu', blue, (v) => setState(() => blue = v), Colors.blue),
          ],
        ),
      ),
    );
  }
}






