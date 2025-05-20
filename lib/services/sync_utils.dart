import 'package:shared_preferences/shared_preferences.dart';

class SyncUtils {
  static const _key = 'last_sync_time';

  /// שמירת זמן סנכרון אחרון
  static Future<void> saveLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_key, time.toIso8601String());
  }

  /// החזרת טקסט להצגה לפי זמן הסנכרון האחרון
  static Future<String> getLastSyncText() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return 'לא בוצע סנכרון עדיין';
    final dt = DateTime.parse(raw);
    return '🕒 סונכרן לאחרונה: '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} '
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}
