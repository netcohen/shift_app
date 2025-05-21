// lib/services/jewish_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shift_app/services/settings_database_service.dart';

class JewishService {
  static Future<void> fetchJewishDates({int? year}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;

    print("📥 מושך נתוני חגים ושבתות עבור $targetYear...");

    final url =
        'https://www.hebcal.com/hebcal/?v=1&year=$targetYear&cfg=json&maj=on&min=on&mod=on&nx=on&ss=on&mf=on&c=on&geo=city&city=IL-Jerusalem';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print("❌ שגיאה בשליפת נתונים מה־API של Hebcal");
      return;
    }

    final data = json.decode(response.body);
    final items = List<Map<String, dynamic>>.from(data['items']);

    await SettingsDatabaseService.clearHolidays();

    for (final item in items) {
      final date = item['date'];
      final title = item['title'];
      final type = item['category'] ?? 'holiday';
      final candles = item['candles'] ?? '';
      final havdalah = item['havdalah'] ?? '';

      await SettingsDatabaseService.insertHoliday(
        date: date,
        type: type,
        title: title,
        candles: candles,
        havdalah: havdalah,
      );
    }

    print("✅ נשמרו ${items.length} מועדים במסד הנתונים");
  }
}
