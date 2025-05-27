import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_hatab/services/mqtt_service.dart';
import 'package:mqtt_hatab/main.dart' show reinitializeServices;
import '../l10n/app_localizations.dart';

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
  bool _passwordVisible = false;
  bool _isLoading = false;

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
    await prefs.setString('mqtt_broker', _brokerController.text.trim());
    await prefs.setInt('mqtt_port', int.parse(_portController.text.trim()));
    await prefs.setString('mqtt_username', _usernameController.text.trim());
    await prefs.setString('mqtt_password', _passwordController.text);
    await prefs.setBool('mqtt_ssl', _useSSL);
  }

  Future<void> _saveAndConnect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _saveSettings();

      // Déconnecter proprement si déjà connecté
      MQTTService.instance.disconnect();

      await MQTTService.instance.connect(
        broker: _brokerController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        useSSL: _useSSL,
        onConnectedCallback: () {
          reinitializeServices();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.mqttConnected)),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.mqttConnectionError}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.mqttSettings)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _brokerController,
                decoration: InputDecoration(labelText: loc.brokerAddress),
                validator: (v) => (v == null || v.isEmpty) ? loc.fieldRequired : null,
              ),
              TextFormField(
                controller: _portController,
                decoration: InputDecoration(labelText: loc.port),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return loc.fieldRequired;
                  final port = int.tryParse(v);
                  if (port == null || port <= 0) return loc.invalidPort;
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: loc.username),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: loc.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                obscureText: !_passwordVisible,
              ),
              SwitchListTile(
                title: Text(loc.sslConnection),
                value: _useSSL,
                onChanged: (value) => setState(() => _useSSL = value),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveAndConnect,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(loc.saveAndConnect),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



