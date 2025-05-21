import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SettingsDatabaseService {
  static Database? _db;

  static Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'settings.db');

    _db = await openDatabase(
      path,
      version: 3, // ⬅️ העלינו מ־2 ל־3!
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE roles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

        await db.execute('''
        CREATE TABLE stations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

        await db.execute('''
        CREATE TABLE position_metadata (
          position_name TEXT PRIMARY KEY,
          code INTEGER
        )
      ''');

        await db.execute('''
        CREATE TABLE role_metadata (
          role_name TEXT PRIMARY KEY,
          code INTEGER,
          start_time TEXT,
          end_time TEXT,
          mode TEXT
        )
      ''');

        await db.execute('''
        CREATE TABLE positions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');

        await db.execute('''
        CREATE TABLE role_positions (
          role_name TEXT NOT NULL,
          position_name TEXT NOT NULL,
          PRIMARY KEY (role_name, position_name)
        )
      ''');

        // ✅ טבלת חגים תיווצר גם בהתקנה חדשה
        await createHolidayTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE role_metadata (
            role_name TEXT PRIMARY KEY,
            code INTEGER,
            start_time TEXT,
            end_time TEXT,
            mode TEXT
          )
        ''');
        }

        if (oldVersion < 3) {
          // ✅ הוספת טבלת holidays לכל מי שמשדרג מגרסה קודמת
          await createHolidayTable(db);
        }
      },
    );
  }

  // 🔽 משימות
  static Future<List<String>> getAllRoles() async {
    final db = _db;
    if (db == null) return [];
    final result = await db.query('roles', orderBy: 'name ASC');
    return result.map((e) => e['name'] as String).toList();
  }

  static Future<void> insertRole(String role) async {
    final db = _db;
    if (db == null) return;
    await db.insert('roles', {
      'name': role,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deleteRole(String role) async {
    final db = _db;
    if (db == null) return;
    await db.delete('roles', where: 'name = ?', whereArgs: [role]);
    await db.delete('role_metadata', where: 'role_name = ?', whereArgs: [role]);
    await db.delete(
      'role_positions',
      where: 'role_name = ?',
      whereArgs: [role],
    );
  }

  // 🔽 תחנות
  static Future<List<String>> getAllStations() async {
    final db = _db;
    if (db == null) return [];
    final result = await db.query('stations', orderBy: 'name ASC');
    return result.map((e) => e['name'] as String).toList();
  }

  static Future<void> insertStation(String station) async {
    final db = _db;
    if (db == null) return;
    await db.insert('stations', {
      'name': station,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deleteStation(String station) async {
    final db = _db;
    if (db == null) return;
    await db.delete('stations', where: 'name = ?', whereArgs: [station]);
  }

  // 🧠 הגדרות נוספות לכל משימה
  static Future<void> saveRoleMetadata({
    required String roleName,
    required String startTime,
    required String endTime,
    required String mode,
  }) async {
    final db = _db;
    if (db == null) return;

    await db.insert('role_metadata', {
      'role_name': roleName,
      'start_time': startTime,
      'end_time': endTime,
      'mode': mode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getRoleMetadata(String roleName) async {
    final db = _db;
    if (db == null) return null;

    final result = await db.query(
      'role_metadata',
      where: 'role_name = ?',
      whereArgs: [roleName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // 🔽 תפקידים
  static Future<List<String>> getAllPositions() async {
    final db = _db;
    if (db == null) return [];
    final result = await db.query('positions', orderBy: 'name ASC');
    return result.map((e) => e['name'] as String).toList();
  }

  static Future<void> insertPosition(String pos) async {
    final db = _db;
    if (db == null) return;
    await db.insert('positions', {
      'name': pos,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deletePosition(String pos) async {
    final db = _db;
    if (db == null) return;
    await db.delete('positions', where: 'name = ?', whereArgs: [pos]);
  }

  // 🔗 קשרים בין משימות לתפקידים
  static Future<void> saveRolePositions({
    required String roleName,
    required List<String> positions,
  }) async {
    final db = _db;
    if (db == null) return;

    final batch = db.batch();
    batch.delete(
      'role_positions',
      where: 'role_name = ?',
      whereArgs: [roleName],
    );

    for (final pos in positions) {
      batch.insert('role_positions', {
        'role_name': roleName,
        'position_name': pos,
      });
    }

    await batch.commit(noResult: true);
  }

  static Future<List<String>> getPositionsForRole(String roleName) async {
    final db = _db;
    if (db == null) return [];

    final result = await db.query(
      'role_positions',
      where: 'role_name = ?',
      whereArgs: [roleName],
    );

    return result.map((e) => e['position_name'] as String).toList();
  }

  static Future<void> savePositionMetadata({
    required String positionName,
    required int code,
  }) async {
    final db = _db;
    if (db == null) return;

    await db.insert('position_metadata', {
      'position_name': positionName,
      'code': code,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int?> getPositionCode(String positionName) async {
    final db = _db;
    if (db == null) return null;

    final result = await db.query(
      'position_metadata',
      where: 'position_name = ?',
      whereArgs: [positionName],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['code'] as int?;
    }
    return null;
  }

  static Future<void> createHolidayTable(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS holidays (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT,
      type TEXT,
      title TEXT,
      candles TEXT,
      havdalah TEXT
    )
  ''');
  }

  static Future<void> clearHolidays() async {
    final db = _db!;
    await db.delete('holidays');
  }

  static Future<void> insertHoliday({
    required String date,
    required String type,
    required String title,
    String candles = '',
    String havdalah = '',
  }) async {
    final db = _db!;
    await db.insert('holidays', {
      'date': date,
      'type': type,
      'title': title,
      'candles': candles,
      'havdalah': havdalah,
    });
  }
}
