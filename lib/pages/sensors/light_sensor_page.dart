import 'package:flutter/material.dart';
import 'package:haade_panel_s504/services/light_service.dart';
import '../../l10n/app_localizations.dart';

class LightSensorPage extends StatefulWidget {
  const LightSensorPage({super.key});

  @override
  State<LightSensorPage> createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> {
  final double _threshold = 50.0;

  String _getLightDescription(BuildContext context, double lux) {
    final loc = AppLocalizations.of(context)!;

    if (lux < 0) {
      return loc.luxErrorValue;
    } else if (lux < 320) {
      return loc.luxDark;
    } else if (lux < 640) {
      return loc.luxDim;
    } else if (lux < 1600) {
      return loc.luxModerate;
    } else if (lux < 2560) {
      return loc.luxBright;
    } else {
      return loc.luxVeryBright;
    }
  }

  @override
  void initState() {
    super.initState();
    LightService.instance.setThreshold(_threshold);
    LightService.instance.initialize();
    LightService.instance.publishDiscoveryConfig();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildLuxCard(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ValueListenableBuilder<double>(
        valueListenable: LightService.instance.luxNotifier,
        builder: (context, lux, _) {
          final hasValidLux = lux > 0;
          final description = hasValidLux
              ? _getLightDescription(context, lux)
              : loc.luxMeasuring;

          return ListTile(
            leading: Icon(
              Icons.light_mode,
              color: Colors.amber.shade700,
              size: 32,
            ),
            title: Text(
              loc.luxAmbientTitle,
              style: const TextStyle(fontSize: 18),
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
    return Column(
      children: [
        _buildLuxCard(context),
        const SizedBox(height: 20),
      ],
    );
  }
}



