class Habit {
  final int? id;
  final String name;
  final String description;
  final String icon;
  final List<String> completedDates;
  final String? startTime; // Format: "HH:mm"
  final String? endTime;   // Format: "HH:mm"

  Habit({
    this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.completedDates,
    this.startTime,
    this.endTime,
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
    };
  }

  // Create Habit object from Map (database result)
  factory Habit.fromMap(Map<String, dynamic> map) {
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
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      completedDates: completedDates ?? this.completedDates,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
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

    // Convert string dates to DateTime and sort descending
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
    
    // Normalize to start of day for comparison
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
}