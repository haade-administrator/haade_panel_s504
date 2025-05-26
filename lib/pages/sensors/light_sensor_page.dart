import 'package:flutter/material.dart';
import 'package:mqtt_hatab/services/light_service.dart';

class LightSensorPage extends StatefulWidget {
  const LightSensorPage({super.key});

  @override
  State<LightSensorPage> createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> {
  final double _threshold = 50.0; // tu peux garder si besoin en interne

  String _getLightDescription(double lux) {
    if (lux < 0) {
      return "Valeur invalide";
    } else if (lux < 320) {
      return "Sombre";
    } else if (lux < 640) {
      return "Lumière légère";
    } else if (lux < 1600) {
      return "Lumière modérée";
    } else if (lux < 2560) {
      return "Lumière forte";
    } else {
      return "Très forte luminosité";
    }
  }

  @override
  void initState() {
    super.initState();
    LightService.instance.setThreshold(_threshold);
    LightService.instance.startSensor();
    LightService.instance.publishDiscoveryConfig();
  }

  @override
  void dispose() {
    LightService.instance.stopSensor();
    super.dispose();
  }

Widget _buildLuxCard() {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ValueListenableBuilder<double>(
      valueListenable: LightService.instance.luxNotifier,
      builder: (context, lux, _) {
        final hasValidLux = lux > 0;
        final description = hasValidLux ? _getLightDescription(lux) : "Mesure en cours...";

        return ListTile(
          leading: Icon(
            Icons.light_mode,
            color: Colors.amber.shade700,
            size: 32,
          ),
          title: const Text(
            'Luminosité Ambiante',
            style: TextStyle(fontSize: 18),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: Text(
            hasValidLux ? '${lux.toStringAsFixed(1)} lx' : '-',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hasValidLux && lux > _threshold ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capteur de Luminosité')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildLuxCard(),
            const SizedBox(height: 20),
            // Plus de slider ni texte ici
          ],
        ),
      ),
    );
  }
}
