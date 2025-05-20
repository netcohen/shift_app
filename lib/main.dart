import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:background_fetch/background_fetch.dart';

import 'screens/calendar_screen.dart';
import 'services/local_database_service.dart';
import 'services/settings_database_service.dart';
import 'services/google_calendar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('he');
  await SettingsDatabaseService.init();
  await LocalDatabaseService.init();
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);

  // ⏰ רישום משימת רקע עם בדיקת סטטוס
  try {
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15, // דקות
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );

    final status = await BackgroundFetch.status;
    print("📦 BackgroundFetch Status: $status");
  } catch (e) {
    print("❌ שגיאה בהפעלת BackgroundFetch: $e");
  }

  runApp(const ShiftApp());
}

// 🎯 פונקציית סנכרון ברקע
void _onBackgroundFetch(String taskId) async {
  try {
    final now = DateTime.now();
    await GoogleCalendarService.getEventsForMonth(now);
    print("📡 [BackgroundFetch] סנכרון הושלם");
  } catch (e) {
    print("❌ [BackgroundFetch] שגיאה: $e");
  }
  BackgroundFetch.finish(taskId);
}

// ⏳ טיפול בזמן חריגה
void _onBackgroundFetchTimeout(String taskId) {
  print("⚠️ [BackgroundFetch] TIMEOUT: $taskId");
  BackgroundFetch.finish(taskId);
}

class ShiftApp extends StatelessWidget {
  const ShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shift App',
      theme: ThemeData(primarySwatch: Colors.blue),
      locale: const Locale('he'),
      supportedLocales: const [Locale('he')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: CalendarScreen(),
      ),
    );
  }
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool timeout = task.timeout;

  if (timeout) {
    print("⚠️ [Headless] TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  print("🎯 [Headless] ביצוע סנכרון ברקע (אפליקציה סגורה)");

  try {
    final now = DateTime.now();
    await GoogleCalendarService.getEventsForMonth(now);
    print("📡 [Headless] סנכרון הושלם");
  } catch (e) {
    print("❌ [Headless] שגיאת סנכרון: $e");
  }

  BackgroundFetch.finish(taskId);
}
