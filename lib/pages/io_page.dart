import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart'; // Import traduction
import 'package:haade_panel_s504/services/io_service.dart';

class IoPage extends StatefulWidget {
  const IoPage({super.key});

  @override
  State<IoPage> createState() => _IoPageState();
}

class _IoPageState extends State<IoPage> {
  // 🟢 CONFIGURATION : définir ici les IO comme Entrée (false) ou Sortie (true)
  final bool isOutput1 = false; // IO1 en mode entrée
  final bool isOutput2 = true;  // IO2 en mode sortie

  bool _manualState1 = false;
  bool _manualState2 = false;

  @override
  void initState() {
    super.initState();

    // Initialiser l'état manuel depuis les notifiers
    _manualState1 = IoService.instance.io1StateNotifier.value;
    _manualState2 = IoService.instance.io2StateNotifier.value;
  }

  Widget _buildIoCard({
    required String title,
    required ValueNotifier<bool> notifier,
    required bool isOutput,
    required int ioNumber,
    required String subtitleOutput,
    required String subtitleInput,
    required String tooltipTrigger,
    required String activeText,
    required String inactiveText,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, currentState, _) {
          final bool isActive = currentState;

          return ListTile(
            leading: Icon(
              isActive ? Icons.circle : Icons.circle_outlined,
              color: isActive ? Colors.green : Colors.grey,
              size: 32,
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
            subtitle: Text(isOutput ? subtitleOutput : subtitleInput),
            trailing: isOutput
                ? IconButton(
                    icon: const Icon(Icons.radio_button_checked, color: Colors.blueGrey),
                    iconSize: 32,
                    tooltip: tooltipTrigger,
                    onPressed: () async {
                      await IoService.instance.setIoHigh(ioNumber);
                      await Future.delayed(const Duration(milliseconds: 200));
                      await IoService.instance.setIoLow(ioNumber);
                    },
                  )
                : Text(
                    isActive ? activeText : inactiveText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.ioControlTitle), // traduction
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIoCard(
              title: loc.io1Label,
              notifier: IoService.instance.io1StateNotifier,
              isOutput: isOutput1,
              ioNumber: 1,
              subtitleOutput: loc.modeOutput,
              subtitleInput: loc.modeInput,
              tooltipTrigger: loc.triggerIo(1),
              activeText: loc.active,
              inactiveText: loc.inactive,
            ),
            const SizedBox(height: 20),
            _buildIoCard(
              title: loc.io2Label,
              notifier: IoService.instance.io2StateNotifier,
              isOutput: isOutput2,
              ioNumber: 2,
              subtitleOutput: loc.modeOutput,
              subtitleInput: loc.modeInput,
              tooltipTrigger: loc.triggerIo(2),
              activeText: loc.active,
              inactiveText: loc.inactive,
            ),
          ],
        ),
      ),
    );
  }
}


