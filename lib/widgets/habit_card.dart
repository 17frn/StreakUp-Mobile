import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_auto_check_service.dart';
import '../pages/edit_habit_page.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const HabitCard({
    Key? key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();
    final streak = habit.getCurrentStreak();
    final autoCheckService = HabitAutoCheckService();
    final hasTimeSet = habit.startTime != null && habit.endTime != null;
    final isWithinTime = hasTimeSet && autoCheckService.isWithinTimeRange(habit);
    final remainingTime = hasTimeSet ? autoCheckService.getRemainingTime(habit) : '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon Container
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF87CEEB).withOpacity(0.3)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF0077BE)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Habit Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                    if (habit.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          habit.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (streak > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 16,
                              color: Color(0xFFFF6B35),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$streak hari beruntun',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF6B35),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Time Info
                    if (hasTimeSet)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: isWithinTime 
                                  ? const Color(0xFF4CAF50) 
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isWithinTime 
                                  ? remainingTime
                                  : '${habit.startTime} - ${habit.endTime}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isWithinTime 
                                    ? const Color(0xFF4CAF50) 
                                    : Colors.grey[600],
                                fontWeight: isWithinTime 
                                    ? FontWeight.w600 
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Action Buttons
              Column(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF0077BE)
                            : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Menu Button
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditHabitPage(habit: habit),
                          ),
                        );
                        if (result == true && onTap != null) {
                          onTap!();
                        }
                      } else if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Habit'),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${habit.name}"? Semua data history akan hilang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}