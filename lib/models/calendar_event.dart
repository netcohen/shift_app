class CalendarEvent {
  final String id; // מזהה ייחודי
  final String eventDate; // DD/MM/YYYY
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String title; // משימה
  final String? role; // תפקיד
  final String? location; // תחנה
  final String? details; // פרטים

  CalendarEvent({
    required this.id,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.role,
    this.location,
    this.details,
  });

  // 🔁 יצירת אובייקט ממסד נתונים
  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'],
      eventDate: map['event_date'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      title: map['title'],
      role: map['role'],
      location: map['location'],
      details: map['details'],
    );
  }

  // 🔁 המרה למסד נתונים
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_date': eventDate,
      'start_time': startTime,
      'end_time': endTime,
      'title': title,
      'role': role,
      'location': location,
      'details': details,
    };
  }
}
