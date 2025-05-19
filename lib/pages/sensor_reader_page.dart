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
  "name": "SMT101 Temperature",
  "unique_id": "smt101_temperature",
  "state_topic": "SMT101/sensor/temperature",
  "availability_topic": "SMT101/availability",
  "device_class": "temperature",
  "unit_of_measurement": "°C",
  "payload_available": "online",
  "payload_not_available": "offline",
  "device": {
    "identifiers": ["smt101"],
    "name": "SMT 1016",
    "manufacturer": "ELC",
    "model": "SMT 1018"
  }
}
''';

final humConfig = '''
{
  "name": "SMT101 Humidity",
  "unique_id": "smt101_humidity",
  "state_topic": "SMT101/sensor/humidity",
  "availability_topic": "SMT101/availability",
  "device_class": "humidity",
  "unit_of_measurement": "%",
  "payload_available": "online",
  "payload_not_available": "offline",
  "device": {
    "identifiers": ["smt101"],
    "name": "SMT 1016",
    "manufacturer": "ELC",
    "model": "SMT 1018"
  }
}
''';

MQTTService.instance.publish('homeassistant/sensor/smt101_temperature/config', tempConfig, retain: true);
MQTTService.instance.publish('homeassistant/sensor/smt101_humidity/config', humConfig, retain: true);


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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Card(
              color: const Color.fromARGB(255, 255, 255, 255),
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.thermostat, color: Colors.teal),
                        SizedBox(width: 10),
                        Text(
                          'Température :',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 58, 58, 58),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_temperature.toStringAsFixed(1)} °C",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 58, 58, 58),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Icon(Icons.water_drop, color: Colors.teal),
                        SizedBox(width: 10),
                        Text(
                          'Humidité :',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 58, 58, 58),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${_humidity.toStringAsFixed(1)} %",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 58, 58, 58),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),

      floatingActionButton: FloatingActionButton(
        onPressed: _readSensors,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

