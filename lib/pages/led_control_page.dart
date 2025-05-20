import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class LedControlPage extends StatefulWidget {
  const LedControlPage({super.key});

  @override
  State<LedControlPage> createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  static const platform = MethodChannel('com.example.elcapi/led');

  Color _selectedColor = Colors.white;
  double _brightness = 1.0;
  bool _isOn = true;

  @override
  void initState() {
    super.initState();
    _publishDiscoveryConfig();

    // Subscribe to control topic
    MQTTService.instance.subscribe('elc_s8504007700001/led/set', _handleMQTTMessage);

    // Publish availability
    MQTTService.instance.publish('elc_s8504007700001/led/availability', 'online', retain: true);

    // Publish initial state
    _publishLedState();
  }

  void _publishDiscoveryConfig() {
    const configPayload = '''
{
  "name": "SMT 101",
  "object_id": "elc_s504007700001_led",
  "unique_id": "elc_s504007700001_led",
  "state_topic": "elc_s504007700001/state",
  "command_topic": "elc_s504007700001/set",
  "availability": [
    {
      "topic": "elc_s504007700001/availability",
      "payload_available": "online",
      "payload_not_available": "offline"
    }
  ],
  "schema": "json",
  "brightness": true,
  "brightness_scale": 255,
  "color_mode": true,
  "supported_color_modes": ["rgb"],
  "device": {
    "identifiers": ["elc_s504007700001"],
    "name": "Tablette SMT",
    "model": "SMT101",
    "manufacturer": "ELC",
    "sw_version": "1.0"
  },
  "effect": false
}
''';

    MQTTService.instance.publish(
      'homeassistant/light/elc_s504007700001_led/config',
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
      if (!_isOn) {
        await platform.invokeMethod('setLed', {"r": 0, "g": 0, "b": 0});
      } else {
        final scaledColor = _applyBrightness(_selectedColor, _brightness);
        final r = (scaledColor.red / 17).round().clamp(0, 15);
        final g = (scaledColor.green / 17).round().clamp(0, 15);
        final b = (scaledColor.blue / 17).round().clamp(0, 15);
        await platform.invokeMethod('setLed', {"r": r, "g": g, "b": b});
      }

      _publishLedState();
    } on PlatformException catch (e) {
      print("Erreur JNI: ${e.message}");
    }
  }

  void _publishLedState() {
    final scaled = _applyBrightness(_selectedColor, _brightness);
    final r = scaled.red;
    final g = scaled.green;
    final b = scaled.blue;

    final payload = '''
{
  "state": "${_isOn ? "ON" : "OFF"}",
  "brightness": ${(_brightness * 255).round()},
  "color": {
    "r": $r,
    "g": $g,
    "b": $b
  }
}
''';

    MQTTService.instance.publish('elc_s8504007700001/led/state', payload, retain: true);
  }

  void _handleMQTTMessage(String message) {
    try {
      final data = Map<String, dynamic>.from(MQTTService.instance.parseJson(message));
      final state = data['state'];
      final r = data['color']?['r'] ?? _selectedColor.red;
      final g = data['color']?['g'] ?? _selectedColor.green;
      final b = data['color']?['b'] ?? _selectedColor.blue;
      final brightness = (data['brightness'] ?? (_brightness * 255)) / 255.0;

      setState(() {
        _isOn = state == null || state.toString().toUpperCase() != "OFF";
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
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("LED allumée"),
                Switch(
                  value: _isOn,
                  onChanged: (val) {
                    setState(() => _isOn = val);
                    _setLed();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}






