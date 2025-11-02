import 'dart:convert';

class Habit {
  final int? id;
  final String name;
  final String description;
  final String icon;
  final List<String> completedDates;
  final String? startTime;
  final String? endTime;
  final bool notificationEnabled;
  final int reminderMinutes;
  final Map<String, String> notes;

  Habit({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.completedDates,
    this.startTime,
    this.endTime,
    this.notificationEnabled = false,
    this.reminderMinutes = 15,
    this.notes = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'completedDates': completedDates.join(','),
      'startTime': startTime,
      'endTime': endTime,
      'notificationEnabled': notificationEnabled ? 1 : 0,
      'reminderMinutes': reminderMinutes,
      'notes': jsonEncode(notes),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    Map<String, String> notesMap = {};
    if (map['notes'] != null && map['notes'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['notes']);
        notesMap = Map<String, String>.from(decoded);
      } catch (e) {
        print('Error parsing notes: $e');
      }
    }

    return Habit(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
      completedDates: map['completedDates'].toString().isEmpty
          ? []
          : map['completedDates'].toString().split(','),
      startTime: map['startTime'],
      endTime: map['endTime'],
      notificationEnabled: map['notificationEnabled'] == 1,
      reminderMinutes: map['reminderMinutes'] ?? 15,
      notes: notesMap,
    );
  }

  Habit copyWith({
    int? id,
    String? name,
    String? description,
    String? icon,
    List<String>? completedDates,
    String? startTime,
    String? endTime,
    bool? notificationEnabled,
    int? reminderMinutes,
    Map<String, String>? notes,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      completedDates: completedDates ?? this.completedDates,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      notes: notes ?? this.notes,
    );
  }

  bool isCompletedToday() {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    return completedDates.contains(dateKey);
  }

  int getCurrentStreak() {
    if (completedDates.isEmpty) return 0;

    final sortedDates = completedDates.map((dateStr) {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    for (var date in sortedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      final difference = checkDate.difference(normalizedDate).inDays;
      
      if (difference <= streak) {
        streak++;
        checkDate = normalizedDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int getTotalCompletions() {
    return completedDates.length;
  }

  double getCompletionRate({int days = 30}) {
    if (completedDates.isEmpty) return 0.0;
    return (completedDates.length / days * 100).clamp(0.0, 100.0);
  }

  bool isCompletedOnDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return completedDates.contains(dateKey);
  }

  DateTime? getLastCompletionDate() {
    if (completedDates.isEmpty) return null;
    
    final sortedDates = completedDates.map((dateStr) {
      final parts = dateStr.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedDates.first;
  }

  String? getNoteForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return notes[dateKey];
  }

  List<MapEntry<String, String>> getSortedNotes() {
    final entries = notes.entries.toList();
    entries.sort((a, b) {
      final dateA = DateTime.parse(a.key.replaceAll('-', ''));
      final dateB = DateTime.parse(b.key.replaceAll('-', ''));
      return dateB.compareTo(dateA);
    });
    return entries;
  }
}