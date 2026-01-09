import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';
import 'package:haade_panel_s504/services/notification.dart';

class LightService {
  static final LightService instance = LightService._internal();
  LightService._internal();

  // MethodChannel correspondant au MainActivity
  static const MethodChannel _channel =
      MethodChannel('com.example.haade_panel_s504/light');

  final ValueNotifier<double> luxNotifier = ValueNotifier(0.0);
  double _threshold = 50.0;
  bool _initialized = false;

  /// Définit le seuil de luminosité pour le réveil
  void setThreshold(double value) {
    _threshold = value;
    _channel.invokeMethod('setThreshold', {'threshold': value});
  }

  /// Initialise le service et le MethodChannel
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Définit le handler pour recevoir les mises à jour du capteur
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onLightChanged") {
        final lux = (call.arguments as num).toDouble();
        _handleLuxUpdate(lux);
      }
    });

    // Démarre la lecture du capteur
    startListening();
  }

  /// Démarre l'écoute du capteur de luminosité
  Future<void> startListening() async {
    try {
      await _channel.invokeMethod('startListening');
    } catch (e) {
      debugPrint('Erreur démarrage LightSensor: $e');
    }
  }

  /// Arrête l'écoute du capteur
  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopListening');
    } catch (e) {
      debugPrint('Erreur arrêt LightSensor: $e');
    }
  }

  /// Traite les nouvelles valeurs de luminosité
  void _handleLuxUpdate(double lux) {
    luxNotifier.value = lux;

    // Publication MQTT
    MQTTService.instance.publish(
      'haade_panel_s504/sensor/lux',
      '{"lux": ${lux.toStringAsFixed(1)}}',
      retain: true,
    );

    // Réveil si dépassement du seuil
    if (lux > _threshold) {
      _wakeUpTablet();
    }
  }

  /// Affiche une notification de luminosité dépassée
  void _wakeUpTablet() {
    NotificationService().showLuminosityNotification(
      'Réveil tablette',
      'Luminosité > seuil ($_threshold lx)',
    );
  }

  /// Publie la configuration Home Assistant (discovery)
  void publishDiscoveryConfig() {
    const topic = 'homeassistant/sensor/haade_panel_s504_lux/config';
    const payload = '''
{
  "name": "Luminosity",
  "state_topic": "haade_panel_s504/sensor/lux",
  "value_template": "{{ value_json.lux }}",
  "unit_of_measurement": "lx",
  "device_class": "illuminance",
  "enabled_by_default": false,
  "unique_id": "haade_panel_s504_lux",
  "availability": {
    "topic": "haade_panel_s504/availability",
    "payload_available": "online",
    "payload_not_available": "offline"
  },
  "device": {
    "identifiers": ["haade_panel_s504"],
    "name": "Haade Panel s504",
    "model": "s504",
    "sw_version": "1.2.1"
  }
}
''';
    MQTTService.instance.publish(topic, payload, retain: true);
  }
}




