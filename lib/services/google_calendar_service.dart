import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../services/local_database_service.dart';
import '../services/sync_utils.dart';

class GoogleHttpClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}

class GoogleCalendarService {
  static bool _isSyncing = false;

  static Future<void> getEventsForMonth(DateTime month) async {
    if (_isSyncing) {
      print("⏳ [GoogleCalendarService] סנכרון כבר מתבצע, מדלגים...");
      return;
    }

    _isSyncing = true;

    try {
      final account = await GoogleSignIn().signInSilently();
      final auth = await account?.authentication;
      if (auth == null) {
        print("❌ [GoogleCalendarService] אין הרשאות גישה לחשבון Google");
        return;
      }

      final httpClient = GoogleHttpClient(auth.accessToken!);
      final calendarApi = calendar.CalendarApi(httpClient);

      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59);

      final result = await calendarApi.events.list(
        "primary",
        timeMin: firstDay.toUtc(),
        timeMax: lastDay.toUtc(),
        singleEvents: true,
        orderBy: "startTime",
      );

      await LocalDatabaseService.clearAllEvents();

      if (result.items != null) {
        for (var e in result.items!) {
          final description = e.description ?? "";
          if (!description.contains("יומן-משמרות")) continue;

          final start = e.start?.dateTime ?? e.start?.date;
          final end = e.end?.dateTime ?? e.end?.date;
          final summary = e.summary ?? "";

          if (start == null || end == null || summary.isEmpty) continue;

          final localStart = start.toLocal();
          final localEnd = end.toLocal();
          final dateStr =
              "${localStart.day.toString().padLeft(2, '0')}/${localStart.month.toString().padLeft(2, '0')}/${localStart.year}";

          String role = "";
          String location = "";
          String details = "";
          String taskTitle = "";

          if (summary.contains(',')) {
            final parts = summary.split(',').map((s) => s.trim()).toList();
            if (parts.length >= 3) {
              taskTitle = parts[0];
              role = parts[1];
              location = parts[2];
            }
          } else if (summary.contains('-')) {
            final parts = summary.split('-').map((s) => s.trim()).toList();
            if (parts.length >= 2) {
              taskTitle = parts[0];
              details = parts[1];
            }
          }

          final event = CalendarEvent(
            id: e.id ?? '${localStart.millisecondsSinceEpoch}',
            eventDate: dateStr,
            startTime: DateFormat.Hm().format(localStart),
            endTime: DateFormat.Hm().format(localEnd),
            title: taskTitle,
            role: role,
            location: location,
            details: details,
          );

          await LocalDatabaseService.insertEvent(event);
        }
      }

      print("✅ [GoogleCalendarService] סנכרון הסתיים לחודש ${month.month}");
      await SyncUtils.saveLastSync(DateTime.now());
    } catch (e) {
      print("❌ [GoogleCalendarService] שגיאה כללית: $e");
    } finally {
      _isSyncing = false;
    }
  }

  static Map<String, String?> _parseEventTitle(String title) {
    // דוגמה: "ערב, נ.אט\"ן, ק.מלאכי"
    final parts = title.split(',');
    final cleaned = parts.map((p) => p.trim()).toList();

    if (cleaned.isEmpty) return {};

    if (cleaned.first == "אבטחה" || cleaned.first == "הדרכה") {
      return {
        "title": cleaned.first,
        "role": cleaned.length > 1 ? cleaned[1] : null,
        "location": null,
        "details": cleaned.length > 2 ? cleaned.sublist(2).join(", ") : null,
      };
    }

    // אחרת משמרת רגילה
    return {
      "title": cleaned.first,
      "role": cleaned.length > 1 ? cleaned[1] : null,
      "location": cleaned.length > 2 ? cleaned[2] : null,
      "details": null,
    };
  }
}
