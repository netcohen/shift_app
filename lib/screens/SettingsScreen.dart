import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  Future<void> _loadSettingsData() async {
    final data = await ShiftSettings.loadAll();
    setState(() {
      _roles = data['roles']!;
      _stations = data['stations']!;
      _positions = data['positions']!;
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
            /// 🎯 הגדרות סוג משמרת + תפקיד + תחנה
            ShiftSettings.buildSettingsSections(
              context: context,
              roles: _roles,
              stations: _stations,
              positions: _positions,
              onRefresh: _loadSettingsData,
            ),

            const Divider(),

            /// 🔄 מערכת עדכון
            ElevatedButton.icon(
              icon: const Icon(Icons.system_update),
              label: const Text("בדוק עדכון"),
              onPressed:
                  () =>
                      UpdateService.checkForUpdates(context, manualCheck: true),
            ),
          ],
        ),
      ),
    );
  }
}
