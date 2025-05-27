import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shift_app/services/settings_database_service.dart';

class JewishService {
  static final Map<String, String> _holidayTranslationMap = {
    'Shabbat': 'שבת',
    'Pesach': 'פסח',
    'Erev Pesach': 'פסח',
    'Shvi’i shel Pesach': 'שביעי של פסח',
    'Shavuot': 'שבועות',
    'Erev Shavuot': 'שבועות',
    'Rosh Hashana': 'ראש השנה',
    'Erev Rosh Hashana': 'ראש השנה',
    'Yom Kippur': 'יום כיפור',
    'Erev Yom Kippur': 'יום כיפור',
    'Sukkot': 'סוכות',
    'Erev Sukkot': 'סוכות',
    'Shemini Atzeret': 'שמיני עצרת',
    'Erev Shemini Atzeret': 'שמיני עצרת',
  };

  static Future<void> fetchJewishDates({int? year}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;

    print("📥 מושך נתוני חגים ושבתות עבור $targetYear...");

    if (await SettingsDatabaseService.isYearAlreadySaved(targetYear)) {
      print("✅ המידע לשנת $targetYear כבר קיים, מדלג...");
      return;
    }

    await SettingsDatabaseService.clearHolidays();

    final url =
        'https://www.hebcal.com/hebcal/?v=1&year=$targetYear&cfg=json&maj=on&min=on&mod=on&nx=on&ss=on&mf=on&c=on&geo=city&city=IL-Jerusalem';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print("❌ שגיאה בשליפת נתונים מה־API של Hebcal");
      return;
    }

    final data = json.decode(response.body);
    final items = List<Map<String, dynamic>>.from(data['items']);
    final dateFormatter = DateFormat('HH:mm dd/MM/yyyy');

    final List<Map<String, dynamic>> events = [];
    DateTime? lastCandleLighting;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final title = item['title'] ?? '';
      final type = item['category'] ?? '';
      final dateStr = item['date'] ?? '';
      final dt = DateTime.tryParse(dateStr);

      if (dt == null) continue;

      // בדיקה אם מדובר בחג או שבת
      if (type == 'holiday' && _holidayTranslationMap.containsKey(title)) {
        final hebrewTitle = _holidayTranslationMap[title]!;
        final nextItem = (i + 1 < items.length) ? items[i + 1] : null;
        final candles =
            (nextItem != null && nextItem['category'] == 'candles')
                ? DateTime.tryParse(nextItem['date'] ?? '')
                : null;
        final havdalahItem = items
            .skip(i + 1)
            .cast<Map<String, dynamic>>()
            .firstWhere((e) => e['category'] == 'havdalah', orElse: () => {});

        final havdalah =
            havdalahItem.isNotEmpty
                ? DateTime.tryParse(havdalahItem['date'] ?? '')
                : null;

        events.add({
          'title': hebrewTitle,
          'start':
              candles != null
                  ? dateFormatter.format(candles)
                  : dateFormatter.format(dt),
          'end': havdalah != null ? dateFormatter.format(havdalah) : '',
          'candles': candles != null ? dateFormatter.format(candles) : '',
          'havdalah': havdalah != null ? dateFormatter.format(havdalah) : '',
        });
      }

      // שבתות
      if (type == 'candles') {
        lastCandleLighting = dt;
      } else if (type == 'havdalah' && lastCandleLighting != null) {
        events.add({
          'title': 'שבת',
          'start': dateFormatter.format(lastCandleLighting),
          'end': dateFormatter.format(dt),
          'candles': dateFormatter.format(lastCandleLighting),
          'havdalah': dateFormatter.format(dt),
        });
        lastCandleLighting = null;
      }
    }

    for (final event in events) {
      await SettingsDatabaseService.insertHoliday(
        start: event['start'],
        end: event['end'],
        year: targetYear,
        type: event['title'] == 'שבת' ? 'shabbat' : 'holiday',
        title: event['title'],
        candles: event['candles'],
        havdalah: event['havdalah'],
      );
    }

    print("✅ נשמרו ${events.length} מועדים במסד הנתונים לשנת $targetYear");
  }

  static Future<List<Map<String, dynamic>>> getAllHolidays() async {
    return await SettingsDatabaseService.getAllHolidays();
  }
}
