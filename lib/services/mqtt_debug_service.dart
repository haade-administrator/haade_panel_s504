import 'package:mqtt_hatab/services/mqtt_service.dart';

class MqttDebugService {
  static final MqttDebugService instance = MqttDebugService._internal();
  factory MqttDebugService() => instance;
  MqttDebugService._internal();

  void publishTestMessage() {
    const topic = 'debug/test_topic';
    const payload = 'hello from debug';
    MQTTService.instance.publish(topic, payload, retain: true);
    print('[DEBUG] Message publié → $topic : $payload');
  }

  void publishIoFakeState(int ioNumber, bool state) {
    final topic = 'elc_s504007700001/binary_sensor/io$ioNumber/state';
    final payload = state ? 'ON' : 'OFF';
    MQTTService.instance.publish(topic, payload, retain: true);
    print('[DEBUG] IO$ioNumber → $payload publié sur $topic');
  }
}
