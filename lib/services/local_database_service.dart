import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/calendar_event.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class LocalDatabaseService {
  static Database? _db;
  static final ValueNotifier<int> dataVersion = ValueNotifier(0); // רענון תצוגה

  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'events.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE events (
            id TEXT PRIMARY KEY,
            event_date TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            title TEXT NOT NULL,
            role TEXT,
            location TEXT,
            details TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertEvent(CalendarEvent event) async {
    final db = _db;
    if (db == null) return;

    await db.insert('events', {
      'id': event.id.isNotEmpty ? event.id : const Uuid().v4(),
      'event_date': event.eventDate,
      'start_time': event.startTime,
      'end_time': event.endTime,
      'title': event.title,
      'role': event.role,
      'location': event.location,
      'details': event.details,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // 🔄 ריענון תצוגה
    dataVersion.value++;
  }

  static Future<List<CalendarEvent>> getEventsForDay(String date) async {
    final db = _db;
    if (db == null) return [];

    final result = await db.query(
      'events',
      where: 'event_date = ?',
      whereArgs: [date],
    );

    return result.map((e) => CalendarEvent.fromMap(e)).toList();
  }

  static Future<List<CalendarEvent>> getEventsForMonthByMonth(
    DateTime month,
  ) async {
    final db = _db;
    if (db == null) return [];

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final allEvents = await db.query('events');

    return allEvents.map((e) => CalendarEvent.fromMap(e)).where((event) {
      final eventDate = dateFormat.parse(event.eventDate);
      return eventDate.isAtSameMomentAs(firstDay) ||
          (eventDate.isAfter(firstDay) && eventDate.isBefore(lastDay)) ||
          eventDate.isAtSameMomentAs(lastDay);
    }).toList();
  }

  static Future<void> updateEventId(String oldId, String newId) async {
    final db = _db;
    if (db == null) return;

    await db.update(
      'events',
      {'id': newId},
      where: 'id = ?',
      whereArgs: [oldId],
    );

    // 🔄 במידה ויש השפעה על התצוגה
    dataVersion.value++;
  }

  static Future<void> clearAllEvents() async {
    final db = _db;
    if (db == null) return;
    await db.delete('events');

    // 🔄 גם כאן נעדכן
    dataVersion.value++;
  }

  static Future<CalendarEvent?> findEventByDateTime(
    String eventDate,
    String startTime,
    String endTime,
  ) async {
    final db = _db;
    if (db == null) return null;

    final result = await db.query(
      'events',
      where: 'event_date = ? AND start_time = ? AND end_time = ?',
      whereArgs: [eventDate, startTime, endTime],
    );

    if (result.isNotEmpty) {
      return CalendarEvent.fromMap(result.first);
    }
    return null;
  }
}
