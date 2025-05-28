import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
import 'package:haade_panel_s504/pages/sensors/light_sensor_page.dart';
import 'package:haade_panel_s504/pages/sensors/sensor_reader_page.dart';

class ParameterInformationPage extends StatefulWidget {
  const ParameterInformationPage({super.key});

  @override
  State<ParameterInformationPage> createState() => _ParameterInformationPageState();
}

class _ParameterInformationPageState extends State<ParameterInformationPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.sensorSettings),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.tempHumidity, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const SensorReaderPage(), // 🔥 plus de box décoratif

            const SizedBox(height: 24),
            Text(loc.brightness, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const LightSensorPage(), // 🔥 plus de box décoratif

            const SizedBox(height: 32),
            const Divider(),
            Align(
              alignment: Alignment.center,
              child: Text(
                '${loc.version}: $_version',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




