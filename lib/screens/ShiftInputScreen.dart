import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../services/local_database_service.dart';

class ShiftInputScreen extends StatefulWidget {
  const ShiftInputScreen({super.key});

  @override
  State<ShiftInputScreen> createState() => _ShiftInputScreenState();
}

class _ShiftInputScreenState extends State<ShiftInputScreen> {
  List<_ShiftRow> _shiftRows = [];

  @override
  void initState() {
    super.initState();
    _initializeRows();
  }

  void _initializeRows() {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    _shiftRows = List.generate(daysInMonth, (index) {
      final date = DateTime(now.year, now.month, index + 1);
      return _ShiftRow(date: date);
    });
  }

  void _addDuplicateRow(DateTime date) {
    setState(() {
      _shiftRows.add(_ShiftRow(date: date, isAdditional: true));
    });
  }

  void _removeRow(int index) {
    setState(() {
      _shiftRows.removeAt(index);
    });
  }

  Future<void> _saveShifts() async {
    for (final row in _shiftRows) {
      if (row.shiftType == null) continue;
      final event = CalendarEvent(
        id: '',
        eventDate: DateFormat('dd/MM/yyyy').format(row.date),
        startTime: row.startTime ?? '',
        endTime: row.endTime ?? '',
        title: row.shiftType ?? '',
        role: row.role ?? '',
        location: row.location ?? '',
        details: row.details ?? '',
      );
      await LocalDatabaseService.insertEvent(event);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ המשמרות נשמרו למסד בהצלחה")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("הזנת משמרות")),
      body: ListView.builder(
        itemCount: _shiftRows.length,
        itemBuilder: (context, index) {
          final row = _shiftRows[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(row.date)),
                      const Spacer(),
                      if (row.isAdditional)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeRow(index),
                        ),
                    ],
                  ),
                  DropdownButton<String>(
                    hint: const Text("בחר סוג משמרת"),
                    value: row.shiftType,
                    onChanged: (value) {
                      setState(() {
                        row.shiftType = value;
                        switch (value) {
                          case "בוקר":
                            row.startTime = "07:00";
                            row.endTime = "15:00";
                            break;
                          case "ערב":
                            row.startTime = "15:00";
                            row.endTime = "23:00";
                            break;
                          case "לילה":
                            row.startTime = "23:00";
                            row.endTime = "07:00";
                            break;
                        }
                      });
                    },
                    items: const [
                      DropdownMenuItem(value: "בוקר", child: Text("בוקר")),
                      DropdownMenuItem(value: "ערב", child: Text("ערב")),
                      DropdownMenuItem(value: "לילה", child: Text("לילה")),
                      DropdownMenuItem(value: "אבטחה", child: Text("אבטחה")),
                      DropdownMenuItem(value: "הדרכה", child: Text("הדרכה")),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: "שעת התחלה",
                          ),
                          initialValue: row.startTime,
                          onChanged: (val) => row.startTime = val,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: "שעת סיום",
                          ),
                          initialValue: row.endTime,
                          onChanged: (val) => row.endTime = val,
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "תפקיד / פירוט",
                    ),
                    onChanged: (val) => row.role = val,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: "תחנה / פירוט נוסף",
                    ),
                    onChanged: (val) => row.location = val,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addDuplicateRow(row.date),
                      icon: const Icon(Icons.add),
                      label: const Text("הוסף משמרת נוספת לאותו יום"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveShifts,
        label: const Text("שמור"),
        icon: const Icon(Icons.save),
      ),
    );
  }
}

class _ShiftRow {
  final DateTime date;
  bool isAdditional;
  String? shiftType;
  String? startTime;
  String? endTime;
  String? role;
  String? location;
  String? details;

  _ShiftRow({required this.date, this.isAdditional = false});
}
