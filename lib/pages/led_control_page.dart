import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class LedControlPage extends StatefulWidget {
  const LedControlPage({super.key});

  @override
  _LedControlPageState createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  static const platform = MethodChannel('com.example.elcapi/led');

  Color _selectedColor = Colors.white;
  double _brightness = 1.0;

  @override
  void initState() {
    super.initState();
    _publishDiscoveryConfig();
    MQTTService.instance.subscribe('tablette/led/set', _handleMQTTMessage);
  }

  void _publishDiscoveryConfig() {
    const configPayload = '''
{
  "name": "SMT 101",
  "unique_id": "smt101_0x12",
  "object_id": "led_tablette",
  "state_topic": "SMT101/led/state",
  "command_topic": "SMT101/led/set",
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
    "identifiers": ["smt101_0x12"],
    "manufacturer": "ELC",
    "model": "SMT 101",
    "name": "SMT 101",
    "sw_version": "1.0"
  },
  "effect": false
}
''';
    MQTTService.instance.publish(
      'homeassistant/light/SMT101',
      configPayload,
      retain: true,
    );
  }

  Color _applyBrightness(Color color, double brightness) {
    return Color.fromARGB(
      255,
      (color.red * brightness).round().clamp(0, 255),
      (color.green * brightness).round().clamp(0, 255),
      (color.blue * brightness).round().clamp(0, 255),
    );
  }

Future<void> _setLed() async {
  try {
    final scaledColor = _applyBrightness(_selectedColor, _brightness);

    final r = (scaledColor.red / 17).round().clamp(0, 15);
    final g = (scaledColor.green / 17).round().clamp(0, 15);
    final b = (scaledColor.blue / 17).round().clamp(0, 15);

    await platform.invokeMethod('setLed', {"r": r, "g": g, "b": b});
    _publishLedState();
  } on PlatformException catch (e) {
    print("Erreur JNI: ${e.message}");
  }
}

void _publishLedState() {
  final isOn = _brightness > 0;
  final scaled = _applyBrightness(_selectedColor, _brightness);

  final r = scaled.red;
  final g = scaled.green;
  final b = scaled.blue;

  final payload = '''
{
  "state": "${isOn ? "ON" : "OFF"}",
  "brightness": ${(_brightness * 255).round()},
  "color": {
    "r": $r,
    "g": $g,
    "b": $b
  }
}
''';
    MQTTService.instance.publish('tablette/led/state', payload);
  }

  void _handleMQTTMessage(String message) {
    try {
      final data = Map<String, dynamic>.from(MQTTService.instance.parseJson(message));
      final r = data['color']?['r'] ?? 0;
      final g = data['color']?['g'] ?? 0;
      final b = data['color']?['b'] ?? 0;
      final brightness = (data['brightness'] ?? 255) / 255.0;

      setState(() {
        _selectedColor = Color.fromARGB(255, r, g, b);
        _brightness = brightness;
      });

      _setLed();
    } catch (e) {
      print("Erreur parsing MQTT: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrôle LED')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Couleur des LEDs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() => _selectedColor = color);
                _setLed();
              },
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsv,
            ),
            const SizedBox(height: 20),
            Text('Luminosité : ${(_brightness * 100).round()}%'),
            Slider(
              value: _brightness,
              onChanged: (val) {
                setState(() => _brightness = val);
                _setLed();
              },
              min: 0.0,
              max: 1.0,
              divisions: 20,
            ),
          ],
        ),
      ),
    );
  }
}




