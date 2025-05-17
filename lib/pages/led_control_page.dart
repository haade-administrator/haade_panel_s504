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

  // Service MQTT encapsulé dans une classe
  final MQTTService mqttService = MQTTService();

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
          onChanged: (val) {
            final newValue = val.toInt();
            setState(() {
              if (label == 'Rouge') red = newValue;
              if (label == 'Vert') green = newValue;
              if (label == 'Bleu') blue = newValue;
            });
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
      appBar: AppBar(title: Text('Contrôle LED')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contrôle des LEDs', style: Theme.of(context).textTheme.titleLarge),
            _buildSlider('Rouge', red, (v) {}, Colors.red),
            _buildSlider('Vert', green, (v) {}, Colors.green),
            _buildSlider('Bleu', blue, (v) {}, Colors.blue),
          ],
        ),
      ),
    );
  }
}




