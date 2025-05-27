import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  static Future<String?> checkForUpdate() async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/haade-administrator/haade_panel_s504/releases/latest'),
      headers: {
        'Accept': 'application/vnd.github+json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final latestVersion = data['tag_name'].toString().replaceAll('v', '');
      final appInfo = await PackageInfo.fromPlatform();
      final currentVersion = appInfo.version;

      if (_isNewerVersion(latestVersion, currentVersion)) {
        return data['html_url'];
      }
    }

    return null;
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }
}

