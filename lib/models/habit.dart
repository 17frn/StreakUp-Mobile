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
  final Map<String, String> notes; // ← INI YANG BARU

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
    this.notes = const {}, // ← INI YANG BARU
  });

  // Convert Habit object to Map for database
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
      'notes': notes.isEmpty ? '' : notes.entries.map((e) => '${e.key}|||${e.value}').join('###'), // ← INI YANG BARU
    };
  }

  // Create Habit object from Map (database result)
  factory Habit.fromMap(Map<String, dynamic> map) {
    // Parse notes ← INI YANG BARU
    Map<String, String> parsedNotes = {};
    if (map['notes'] != null && map['notes'].toString().isNotEmpty) {
      final notesStr = map['notes'].toString();
      final entries = notesStr.split('###');
      for (var entry in entries) {
        if (entry.isNotEmpty) {
          final parts = entry.split('|||');
          if (parts.length == 2) {
            parsedNotes[parts[0]] = parts[1];
          }
        }
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
      notes: parsedNotes, // ← INI YANG BARU
    );
  }

  // Copy with method for updating habit
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
    Map<String, String>? notes, // ← INI YANG BARU
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
      notes: notes ?? this.notes, // ← INI YANG BARU
    );
  }

  // Check if habit is completed today
  bool isCompletedToday() {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    return completedDates.contains(dateKey);
  }

  // Get current streak (consecutive days)
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

  // Get total completions count
  int getTotalCompletions() {
    return completedDates.length;
  }

  // Get completion rate (percentage)
  double getCompletionRate({int days = 30}) {
    if (completedDates.isEmpty) return 0.0;
    return (completedDates.length / days * 100).clamp(0.0, 100.0);
  }

  // Check if completed on specific date
  bool isCompletedOnDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return completedDates.contains(dateKey);
  }

  // Get last completion date
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

  // ← METHODS BARU UNTUK NOTES
  // Get note for specific date
  String? getNoteForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return notes[dateKey];
  }

  // Check if has note for date
  bool hasNoteForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return notes.containsKey(dateKey) && notes[dateKey]!.isNotEmpty;
  }
}