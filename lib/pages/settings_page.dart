import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _brokerController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _useSSL = false;

  final MQTTService mqttService = MQTTService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _brokerController.text = prefs.getString('mqtt_broker') ?? '192.168.1.100';
      _portController.text = (prefs.getInt('mqtt_port') ?? 1883).toString();
      _usernameController.text = prefs.getString('mqtt_username') ?? '';
      _passwordController.text = prefs.getString('mqtt_password') ?? '';
      _useSSL = prefs.getBool('mqtt_ssl') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mqtt_broker', _brokerController.text);
    await prefs.setInt('mqtt_port', int.parse(_portController.text));
    await prefs.setString('mqtt_username', _usernameController.text);
    await prefs.setString('mqtt_password', _passwordController.text);
    await prefs.setBool('mqtt_ssl', _useSSL);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paramètres enregistrés')),
    );

    await _connectAndPublishTest();
  }

  Future<void> _connectAndPublishTest() async {
    try {
      await mqttService.connect(
        broker: _brokerController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
        useSSL: _useSSL,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connecté au broker MQTT')),
      );
      mqttService.publish('test/tablette', 'Message test depuis l’application MQTT Tablette');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion MQTT: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paramètres MQTT')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _brokerController,
                decoration: InputDecoration(labelText: 'Adresse du broker'),
              ),
              TextFormField(
                controller: _portController,
                decoration: InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Nom d’utilisateur'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
              ),
              SwitchListTile(
                title: Text('Connexion SSL'),
                value: _useSSL,
                onChanged: (value) => setState(() => _useSSL = value),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Enregistrer et connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
