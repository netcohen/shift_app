import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../services/google_calendar_service.dart';
import '../services/local_database_service.dart';
import '../models/calendar_event.dart';
import '../services/sync_utils.dart';
import 'package:shift_app/screens/ShiftInputScreen.dart';
import 'package:shift_app/screens/SettingsScreen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _displayedMonth = DateTime.now();
  DateTime? _selectedDate;
  List<CalendarEvent> _events = [];
  GoogleSignInAccount? _user;
  bool _initialized = false;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar.readonly',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  @override
  void initState() {
    super.initState();

    // ✅ מאזין לשינויים במסד הנתונים
    LocalDatabaseService.dataVersion.addListener(() {
      final now = DateTime.now();
      if (_displayedMonth.year == now.year &&
          _displayedMonth.month == now.month) {
        _loadEvents();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initSignIn();
      _initialized = true;
    }
  }

  Future<void> _initSignIn() async {
    final account = await _googleSignIn.signInSilently();
    setState(() => _user = account);
    _loadEvents();
  }

  Future<void> _handleSignIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        setState(() => _user = account);
        _loadEvents();
      }
    } catch (e) {
      debugPrint("Sign-in failed: $e");
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _user = null;
      _events = [];
    });
  }

  Future<void> _loadEvents() async {
    if (_user == null) return;

    // ✅ סנכרון מול Google
    await GoogleCalendarService.getEventsForMonth(_displayedMonth);

    // ✅ שליפה מתוך המסד המקומי לאחר הסנכרון
    final events = await LocalDatabaseService.getEventsForMonthByMonth(
      _displayedMonth,
    );

    // ✅ עדכון סטייט
    setState(() => _events = events);
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
      );
    });
    _loadEvents();
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
      );
    });
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final weekdayOffset = firstDayOfMonth.weekday % 7;

    final calendarDays = List<Widget>.generate(
      weekdayOffset,
      (_) => const SizedBox(),
    );

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, i);
      final dateStr = DateFormat('dd/MM/yyyy').format(date);

      final hasEvent = _events.any((e) => e.eventDate == dateStr);

      Color? bgColor;

      if (date.isBefore(DateTime.now()) && hasEvent) {
        bgColor = const Color(0xFFE9ECEF); // אפור
      } else if (DateUtils.isSameDay(date, DateTime.now())) {
        bgColor = const Color(0xFFD3F9D8); // ירוק
      } else if (date.isAfter(DateTime.now()) && hasEvent) {
        bgColor = const Color(0xFFD0EBFF); // תכלת
      }

      calendarDays.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              color: bgColor,
            ),
            child: Center(child: Text(i.toString())),
          ),
        ),
      );
    }

    return Scaffold(
      drawerEdgeDragWidth: 80, // מאפשר פתיחה מהצד, אבל לא רגיש מדי
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('תפריט ראשי', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              leading: Icon(Icons.edit_calendar),
              title: Text('הזנת משמרות'),
              onTap: () {
                Navigator.pop(context); // סוגר את המגירה
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShiftInputScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('הגדרות'),
              onTap: () {
                Navigator.pop(context); // סוגר את המגירה
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: Text(DateFormat.yMMMM('he').format(_displayedMonth)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _goToNextMonth,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
        leading: IconButton(
          onPressed: _goToPreviousMonth,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
                _user == null
                    ? ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text('התחבר עם Google'),
                      onPressed: _handleSignIn,
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_user!.displayName ?? 'לא ידוע'),
                            Text(
                              _user!.email,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _handleSignOut,
                        ),
                      ],
                    ),
          ),
          SizedBox(
            height: 350,
            child: GridView.count(
              crossAxisCount: 7,
              children: calendarDays,
              physics: const NeverScrollableScrollPhysics(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildEventDetails(),
            ),
          ),

          // ✅ תצוגת זמן סנכרון אחרון
          FutureBuilder(
            future: SyncUtils.getLastSyncText(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  snapshot.data!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventDetails() {
    final selected = _selectedDate ?? DateTime.now();
    final selectedStr = DateFormat('dd/MM/yyyy').format(selected);

    final eventsForDay =
        _events.where((e) => e.eventDate == selectedStr).toList();

    if (eventsForDay.isEmpty) {
      return [const Text("📭 אין אירועים ליום זה")];
    }

    return eventsForDay.map((e) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          "🕒 ${e.startTime} - ${e.endTime} | ${e.title} (${e.role}) - ${e.location}",
        ),
      );
    }).toList();
  }
}
