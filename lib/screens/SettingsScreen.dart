import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shift_app/services/shift_settings.dart';
import 'package:shift_app/services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<String> _roles = [];
  List<String> _stations = [];
  List<String> _positions = [];
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
    _loadAppVersion();
  }

  Future<void> _loadSettingsData() async {
    final data = await ShiftSettings.loadAll();
    setState(() {
      _roles = data['roles']!;
      _stations = data['stations']!;
      _positions = data['positions']!;
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("הגדרות מערכת")),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            /// 🎯 הגדרות משמרות (תפקידים, תחנות, סוגים)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "הגדרת משמרות",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShiftSettings.buildSettingsSections(
                      context: context,
                      roles: _roles,
                      stations: _stations,
                      positions: _positions,
                      onRefresh: _loadSettingsData,
                    ),
                  ],
                ),
              ),
            ),

            /// ⚙️ הגדרות מערכת + בדיקת גרסה
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "הגדרות מערכת",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("גרסה נוכחית: $_appVersion"),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.system_update),
                      label: const Text("בדוק עדכון"),
                      onPressed:
                          () => UpdateService.checkForUpdates(
                            context,
                            manualCheck: true,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
