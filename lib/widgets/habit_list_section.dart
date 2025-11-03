import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../pages/habit_detail_page.dart';

class HabitListSection extends StatelessWidget {
  final List<Habit> habits;
  final DateTime selectedDate;
  final Function(Habit) onToggleHabit;

  const HabitListSection({
    Key? key,
    required this.habits,
    required this.selectedDate,
    required this.onToggleHabit,
  }) : super(key: key);

  bool _isHabitCompletedOnDate(Habit habit, DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return habit.completedDates.contains(dateKey);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: habits.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada habit',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final isCompleted = _isHabitCompletedOnDate(habit, selectedDate);

                return _buildHabitItem(context, habit, isCompleted);
              },
            ),
    );
  }

  Widget _buildHabitItem(BuildContext context, Habit habit, bool isCompleted) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitDetailPage(habit: habit),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => onToggleHabit(habit),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF42A5F5)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: isCompleted ? Colors.white : Colors.grey[400],
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? Colors.grey[400] : Colors.black87,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (habit.startTime != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        habit.startTime!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}