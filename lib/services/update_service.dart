import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static const _jsonUrl =
      'https://raw.githubusercontent.com/netcohen/shift_app/main/version.json';

  static Future<void> checkAndInstallSilently() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(_jsonUrl));
      if (response.statusCode != 200) return;

      final remote = json.decode(response.body);
      final latestVersion = remote['version'];
      final apkUrl = remote['apkUrl'];

      if (latestVersion == null || apkUrl == null) return;

      if (_isNewerVersion(currentVersion, latestVersion)) {
        print("📲 עדכון זמין – מתבצעת פתיחה שקטה של הקישור...");
        final uri = Uri.parse(apkUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print("⚠️ לא ניתן לפתוח את הקישור לעדכון");
        }
      } else {
        print("✅ המערכת כבר מעודכנת");
      }
    } catch (e) {
      print("❌ שגיאה בבדיקה שקטה לעדכון: $e");
    }
  }

  static Future<void> checkForUpdates(
    BuildContext context, {
    bool manualCheck = false,
  }) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(_jsonUrl));
      if (response.statusCode != 200) {
        throw Exception("Version file not found");
      }

      final remote = json.decode(response.body);
      final latestVersion = remote['version'];
      final apkUrl = remote['apkUrl'];
      final changelog = remote['changelog'] ?? '';

      if (latestVersion == null || apkUrl == null) {
        throw Exception("Missing 'version' or 'apkUrl' in version.json");
      }

      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (manualCheck) {
          _showUpdateDialog(context, apkUrl, latestVersion, changelog);
        } else {
          // בעתיד ניתן להוסיף הורדה ברקע או תזכורת
        }
      } else {
        if (manualCheck) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("🔄 המערכת שלך מעודכנת")),
          );
        }
      }
    } catch (e) {
      if (manualCheck) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ שגיאה בבדיקת עדכון: $e")));
      }
    }
  }

  static Future<void> notifyIfVersionChanged(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final prefs = await SharedPreferences.getInstance();
      final lastVersion = prefs.getString('last_known_version');

      if (lastVersion != null && lastVersion != currentVersion) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🎉 העדכון לגרסה $currentVersion הושלם בהצלחה!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // תמיד נעדכן את הגרסה האחרונה הידועה
      await prefs.setString('last_known_version', currentVersion);
    } catch (e) {
      print("⚠️ שגיאה בזיהוי שינוי גרסה: $e");
    }
  }

  static bool _isNewerVersion(String current, String remote) {
    List<int> parseVersion(String v) {
      final parts = v.split('.').map(int.tryParse).whereType<int>().toList();
      while (parts.length < 3) parts.add(0);
      return parts.sublist(0, 3);
    }

    final c = parseVersion(current);
    final r = parseVersion(remote);

    for (int i = 0; i < 3; i++) {
      if (r[i] > c[i]) return true;
      if (r[i] < c[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String url,
    String version,
    String changelog,
  ) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("🆕 עדכון זמין ($version)"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (changelog.isNotEmpty) Text("מה חדש:\n$changelog"),
                const SizedBox(height: 12),
                const Text("האם להתקין את העדכון כעת?"),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("לא עכשיו"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: const Text("התקן"),
              ),
            ],
          ),
    );
  }
}
