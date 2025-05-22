import 'package:flutter/material.dart';
import 'package:mqtt_hatab/services/io_service.dart';

class IoPage extends StatelessWidget {
  const IoPage({Key? key}) : super(key: key);

  Widget _buildInputStatus(String title, ValueNotifier<bool> notifier) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ValueListenableBuilder<bool>(
        valueListenable: notifier,
        builder: (context, currentState, _) {
          return ListTile(
            leading: Icon(
              currentState ? Icons.circle : Icons.circle_outlined,
              color: currentState ? Colors.green : Colors.grey,
              size: 32,
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
            trailing: Text(
              currentState ? 'ACTIF' : 'INACTIF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: currentState ? Colors.green : Colors.grey,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('État des entrées IO'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildInputStatus('Entrée IO1 (Bouton 1)', IoService.instance.io1StateNotifier),
            const SizedBox(height: 20),
            _buildInputStatus('Entrée IO2 (Bouton 2)', IoService.instance.io2StateNotifier),
          ],
        ),
      ),
    );
  }
}


