import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:mqtt_hatab/services/led_service.dart';

class LedControlPage extends StatefulWidget {
  const LedControlPage({super.key});

  @override
  State<LedControlPage> createState() => _LedControlPageState();
}

class _LedControlPageState extends State<LedControlPage> {
  final LedService _ledService = LedService();

  @override
  void initState() {
    super.initState();
    _ledService.initialize();
  }

  @override
  void dispose() {
    _ledService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrôle LED & Capteurs')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            Text('Couleur des LEDs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            ValueListenableBuilder<Color>(
              valueListenable: _ledService.selectedColor,
              builder: (context, color, _) {
                return ColorPicker(
                  pickerColor: color,
                  onColorChanged: (newColor) => _ledService.selectedColor.value = newColor,
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsv,
                );
              },
            ),

            const SizedBox(height: 20),

            ValueListenableBuilder<double>(
              valueListenable: _ledService.brightness,
              builder: (context, brightness, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Luminosité : ${(brightness * 100).round()}%'),
                    Slider(
                      value: brightness,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (val) => _ledService.brightness.value = val,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            ValueListenableBuilder<bool>(
              valueListenable: _ledService.isOn,
              builder: (context, isOn, _) {
                return Row(
                  children: [
                    const Text("LED allumée"),
                    Switch(
                      value: isOn,
                      onChanged: (val) => _ledService.isOn.value = val,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}







