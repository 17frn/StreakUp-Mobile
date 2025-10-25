import '../models/habit.dart';
import '../database/database_helper.dart';

class HabitAutoCheckService {
  static final HabitAutoCheckService _instance = HabitAutoCheckService._internal();
  factory HabitAutoCheckService() => _instance;
  HabitAutoCheckService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Check if current time is within habit's time range
  bool isWithinTimeRange(Habit habit) {
    if (habit.startTime == null || habit.endTime == null) {
      return false;
    }

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final startParts = habit.startTime!.split(':');
    final startMinutes = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

    final endParts = habit.endTime!.split(':');
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

    // Handle case where end time is on next day (e.g., 23:00 - 01:00)
    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }

    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  /// Auto-complete habit if within time range and not yet completed today
  Future<void> autoCheckHabit(Habit habit) async {
    if (!isWithinTimeRange(habit)) return;
    if (habit.isCompletedToday()) return;

    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';

    final updatedHabit = habit.copyWith(
      completedDates: [...habit.completedDates, dateKey],
    );

    await _dbHelper.updateHabit(updatedHabit);
  }

  /// Check all habits and auto-complete if needed
  Future<void> checkAllHabits() async {
    final habits = await _dbHelper.getHabits();
    
    for (var habit in habits) {
      if (habit.startTime != null && habit.endTime != null) {
        await autoCheckHabit(habit);
      }
    }
  }

  /// Get time until next check (in milliseconds)
  int getNextCheckDelay() {
    final now = DateTime.now();
    final nextMinute = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    return nextMinute.difference(now).inMilliseconds;
  }

  /// Calculate remaining time for habit
  String getRemainingTime(Habit habit) {
    if (habit.endTime == null) return '';

    final now = DateTime.now();
    final endParts = habit.endTime!.split(':');
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    var endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endHour,
      endMinute,
    );

    // If end time already passed today, it's for tomorrow
    if (endDateTime.isBefore(now)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    final difference = endDateTime.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return '$hours jam $minutes menit lagi';
    } else if (minutes > 0) {
      return '$minutes menit lagi';
    } else {
      return 'Segera berakhir';
    }
  }

  /// Check if habit should show reminder
  bool shouldShowReminder(Habit habit) {
    if (habit.endTime == null) return false;
    if (habit.isCompletedToday()) return false;

    final now = DateTime.now();
    final endParts = habit.endTime!.split(':');
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    var endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endHour,
      endMinute,
    );

    // If end time already passed today, it's for tomorrow
    if (endDateTime.isBefore(now)) {
      return false;
    }

    // Show reminder 1 hour before end time
    final reminderTime = endDateTime.subtract(const Duration(hours: 1));
    return now.isAfter(reminderTime) && now.isBefore(endDateTime);
  }
}