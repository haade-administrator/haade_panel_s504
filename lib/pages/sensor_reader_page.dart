import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class SensorReaderPage extends StatefulWidget {
  const SensorReaderPage({super.key});

  @override
  State<SensorReaderPage> createState() => _SensorReaderPageState();
}

class _SensorReaderPageState extends State<SensorReaderPage> {
  static const platform = MethodChannel('com.example.elcapi/sensor');
  double _temperature = 0;
  double _humidity = 0;
  bool _isLoading = false;

  @override
void initState() {
  super.initState();
  _publishDiscoveryConfigs();
  _setupSensorChannel();
}

void _setupSensorChannel() {
  platform.setMethodCallHandler((call) async {
    switch (call.method) {
      case "onTemperature":
        final double temp = (call.arguments as num).toDouble();
        setState(() => _temperature = temp);
        MQTTService.instance.publish('SMT101/sensor/temperature', temp.toStringAsFixed(1), retain: true);
        break;

      case "onHumidity":
        final double hum = (call.arguments as num).toDouble();
        setState(() => _humidity = hum);
        MQTTService.instance.publish('SMT101/sensor/humidity', hum.toStringAsFixed(1), retain: true);
        break;

      case "onSensorError":
        _showSnackBar("Erreur capteur : ${call.arguments}");
        break;

      default:
        _showSnackBar("Méthode non reconnue : ${call.method}");
        break;
    }
  });

  // Déclarer en ligne que le capteur est disponible
  MQTTService.instance.publish('SMT101/availability', 'online', retain: true);
}


void _publishDiscoveryConfigs() {
  final tempConfig = '''
{
  "name": "Temperature SMT101",
  "unique_id": "smt101_temp",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "state_topic": "SMT101/sensor/temperature",
  "availability_topic": "SMT101/availability",
  "payload_available": "online",
  "payload_not_available": "offline",
  "device": {
    "identifiers": ["smt101_0x12"],
    "manufacturer": "ELC",
    "model": "SMT 101",
    "name": "SMT 101"
  }
}
''';

  final humConfig = '''
{
  "name": "Humidity SMT101",
  "unique_id": "smt101_humidity",
  "device_class": "humidity",
  "unit_of_measurement": "%",
  "state_topic": "SMT101/sensor/humidity",
  "availability_topic": "SMT101/availability",
  "payload_available": "online",
  "payload_not_available": "offline",
  "device": {
    "identifiers": ["elc_smt101"],
    "manufacturer": "ELC",
    "model": "SMT 101",
    "name": "SMT 101"
  }
}
''';

  MQTTService.instance.publish('homeassistant/sensor/elc_smt101/temperature/config', tempConfig, retain: true);
  MQTTService.instance.publish('homeassistant/sensor/elc_smt101/humidity/config', humConfig, retain: true);

  // Une seule publication pour l'état de disponibilité
  MQTTService.instance.publish('SMT101/availability', 'online', retain: true);
}


Future<void> _readSensors() async {
  setState(() => _isLoading = true);

  try {
    final result = await platform.invokeMethod<Map>('readSensors');

    if (result != null &&
        result['temperature'] is num &&
        result['humidity'] is num) {
      final temperature = result['temperature'].toDouble();
      final humidity = result['humidity'].toDouble();

      setState(() {
        _temperature = temperature;
        _humidity = humidity;
      });

      MQTTService.instance.publish('SMT101/sensor/temperature', temperature.toStringAsFixed(1), retain: true);
      MQTTService.instance.publish('SMT101/sensor/humidity', humidity.toStringAsFixed(1), retain: true);
    } else {
      _showSnackBar("Valeurs capteurs invalides ou absentes.");
    }
  } on PlatformException catch (e) {
    _showSnackBar("Erreur de lecture capteur : ${e.message}");
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _readSensorsPeriodically() {
    Future.doWhile(() async {
      await _readSensors();
      await Future.delayed(const Duration(seconds: 30));
      return true;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Température & Humidité")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              Text(
                "🌡 Température : ${_temperature.toStringAsFixed(1)} °C",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                "💧 Humidité : ${_humidity.toStringAsFixed(1)} %",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

