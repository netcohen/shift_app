import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shift_app/services/shift_settings.dart';
import 'package:shift_app/services/update_service.dart';
import 'package:shift_app/services/jewish_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/backup_service.dart';

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
  bool _shabbatMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
    _loadAppVersion();
    _checkGoogleConnection(); // ✅ נוסיף קריאת בדיקה לגוגל
    UpdateService.notifyIfVersionChanged(context);
  }

  @override
  void dispose() {
    try {
      BackupService.backupDatabases();
    } catch (e) {
      print("⚠️ שגיאה במהלך גיבוי ל-Drive: $e");
    }
    super.dispose();
  }

  Future<void> _checkGoogleConnection() async {
    final isSignedIn = await GoogleSignIn.standard().isSignedIn();
    if (!isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ לא מחובר לחשבון Google – חלק מהפונקציות לא זמינות',
            ),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  Future<void> _loadSettingsData() async {
    final data = await ShiftSettings.loadAll();
    setState(() {
      _roles = data['roles']!;
      _stations = data['stations']!;
      _positions = data['positions']!;
    });
  }

  void _showRawHolidayListDialog() async {
    // טען את הנתונים לפני ההצגה
    await JewishService.fetchJewishDates();

    final holidays = await JewishService.getAllHolidays();
    print("📦 נתוני החגים מה-DB: $holidays");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("רשימת חגים ושבתות"),
          content: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("חג/שבת")),
                  DataColumn(label: Text("כניסה")),
                  DataColumn(label: Text("יציאה")),
                ],
                rows:
                    holidays.map((holiday) {
                      return DataRow(
                        cells: [
                          DataCell(Text(holiday['title'] ?? '')),
                          DataCell(Text(holiday['candles'] ?? '')),
                          DataCell(Text(holiday['havdalah'] ?? '')),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("סגור"),
            ),
          ],
        );
      },
    );
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

                    /// מצב שבת וחג
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("הפעל מצב שבת וחג"),
                        Switch(
                          value: _shabbatMode,
                          onChanged: (val) {
                            setState(() {
                              _shabbatMode = val;
                            });
                            // ⏳ בעתיד: שמירה במסד נתונים
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    ElevatedButton(
                      onPressed: _showRawHolidayListDialog,
                      child: const Text("🔍 הצג רשימת חגים ושבתות (פיתוח)"),
                    ),

                    /// גרסה נוכחית
                    Text("גרסה נוכחית: $_appVersion"),

                    const SizedBox(height: 8),

                    /// כפתור עדכון
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
