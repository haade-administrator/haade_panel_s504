import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_page.dart';

class LedControlPage extends StatefulWidget {
  @override
  _LedControlPageState createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  static const platform = MethodChannel('com.example.elcapi/led');

  int red = 0, green = 0, blue = 0;

  Future<void> _setLed() async {
    try {
      await platform.invokeMethod('setLed', {"r": red, "g": green, "b": blue});
      mqttService.publish('tablette/leds', '{"r":$red,"g":$green,"b":$blue}');

    } on PlatformException catch (e) {
      print("Erreur JNI: ${e.message}");
    }
  }

  Widget _buildSlider(String label, int value, ValueChanged<int> onChanged, Color color) {
    return Column(
      children: [
        Text('$label: $value', style: TextStyle(color: color)),
        Slider(
          value: value.toDouble(),
          onChanged: (val) => onChanged(val.toInt()),
          min: 0,
          max: 15,
          activeColor: color,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contrôle LED')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSlider('Rouge', red, (v) => setState(() => red = v), Colors.red),
            _buildSlider('Vert', green, (v) => setState(() => green = v), Colors.green),
            _buildSlider('Bleu', blue, (v) => setState(() => blue = v), Colors.blue),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setLed,
              child: Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}
