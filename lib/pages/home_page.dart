import 'package:flutter/material.dart';
import 'mqtt_settings_page.dart';
import 'led_control_page.dart';
import 'parameter_information.dart';
import 'switch_relay_page.dart';
import 'io_page.dart';
import 'package:haade_panel_s504/services/mqtt_service.dart';
import 'package:haade_panel_s504/services/sensor_service.dart';
import 'package:haade_panel_s504/services/led_service.dart';
import '../main.dart'; // Import pour accéder à MyApp.minimizeApp()
import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:haade_panel_s504/services/update_checker.dart';
import 'package:haade_panel_s504/services/app_localizations_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MQTTService mqtt = MQTTService.instance;
  final LedService ledService = LedService();

  bool _updateAvailable = false;
  String? _updateUrl;

  // 👇 Flags pour activer/désactiver facilement les pages
  final bool _enableLedPage = false;
  final bool _enableSwitchPage = false;
  final bool _enableIoPage = true;
  final bool _enableParameterPage = true;

  @override
  void initState() {
    super.initState();

    // ✅ Initialiser AppLocalizationsHelper ici, quand le contexte est dispo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLocalizationsHelper.setLocalizations(AppLocalizations.of(context)!);
    });

    SensorService().initialize();
    _checkUpdateOnStart();
  }

  @override
  void dispose() {
    ledService.dispose();
    super.dispose();
  }

  Future<void> _checkUpdateOnStart() async {
    final url = await UpdateChecker.checkForUpdate();
    if (mounted) {
      setState(() {
        _updateAvailable = url != null;
        _updateUrl = url;
      });
    }
  }

  Future<void> _launchUpdateUrl() async {
    if (_updateUrl == null) return;
    final uri = Uri.parse(_updateUrl!);

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.updateLaunchFailed),
        ),
      );
    }
  }

  Future<void> _manualCheckUpdate() async {
    final url = await UpdateChecker.checkForUpdate();
    if (!mounted) return;

    if (url != null) {
      setState(() {
        _updateAvailable = true;
        _updateUrl = url;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.updateAvailableTitle),
          content: Text(AppLocalizations.of(context)!.updateAvailableContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _launchUpdateUrl();
              },
              child: Text(AppLocalizations.of(context)!.download),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _updateAvailable = false;
        _updateUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noUpdateAvailable)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.white),
          tooltip: loc.minimizeAppTooltip,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc.appWillMinimize),
                duration: const Duration(seconds: 2),
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              MyApp.minimizeApp();
            });
          },
        ),
        title: Text(
          loc.title,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 61, 61, 61),
        actions: [
          if (_updateAvailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  loc.newVersionAvailable,
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.system_update,
              color: _updateAvailable ? Colors.red : Colors.white,
            ),
            tooltip: loc.checkUpdateTooltip,
            onPressed: _manualCheckUpdate,
          ),
          ValueListenableBuilder<bool>(
            valueListenable: mqtt.isConnected,
            builder: (context, connected, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.circle,
                  color: connected ? Colors.green : Colors.red,
                  size: 18,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildNavigationCard(
              context,
              icon: Icons.settings,
              title: loc.mqttSettingsTitle,
              subtitle: loc.mqttSettingsSubtitle,
              page: const SettingsPage(),
            ),
            const SizedBox(height: 20),
            if (_enableLedPage)
              _buildNavigationCard(
                context,
                icon: Icons.lightbulb_outline,
                title: loc.ledControlTitle,
                subtitle: loc.ledControlSubtitle,
                page: const LedControlPage(),
              ),
            const SizedBox(height: 20),
            if (_enableSwitchPage)
              _buildNavigationCard(
                context,
                icon: Icons.power_rounded,
                title: loc.relaySwitchTitle,
                subtitle: loc.relaySwitchSubtitle,
                page: const SwitchRelayPage(),
              ),
            const SizedBox(height: 20),
            if (_enableIoPage)
              _buildNavigationCard(
                context,
                icon: Icons.radio_button_checked,
                title: loc.ioButtonControlTitle,
                subtitle: loc.ioButtonControlSubtitle,
                page: const IoPage(),
              ),
            const SizedBox(height: 20),
            if (_enableParameterPage)
              _buildNavigationCard(
                context,
                icon: Icons.settings,
                title: loc.parameterInformationTitle,
                subtitle: loc.parameterInformationSubtitle,
                page: const ParameterInformationPage(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, size: 36, color: Colors.teal),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
      ),
    );
  }
}
