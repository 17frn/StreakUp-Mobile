import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../database/database_helper.dart';
import '../services/habit_auto_check_service.dart';
import '../widgets/notes_dialog.dart';
import 'add_habit_page.dart';
import 'habit_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final HabitAutoCheckService _autoCheckService = HabitAutoCheckService();
  List<Habit> _habits = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All Habit';

  @override
  void initState() {
    super.initState();
    _setupAutoCheckCallback();
    _loadHabits();
    _startAutoCheck();
  }

  // Setup callback untuk auto-complete
  void _setupAutoCheckCallback() {
    _autoCheckService.onHabitAutoCompleted = (habit, dateKey) {
      print('🎉 Habit auto-completed: ${habit.name}');
      print('📝 Should show notes dialog...');
      
      // Show dialog notes di frame berikutnya
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showNotesDialog(habit, dateKey);
        }
      });
    };
  }

  void _startAutoCheck() {
    Future.delayed(Duration.zero, () async {
      while (mounted) {
        await _autoCheckService.checkAllHabits();
        await _loadHabits();
        await Future.delayed(const Duration(minutes: 1));
      }
    });
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    final habits = await _dbHelper.getHabits();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  Future<void> _toggleHabit(Habit habit) async {
    final dateKey = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}';
    final wasCompleted = habit.completedDates.contains(dateKey);
    
    print('🔄 Toggle habit: ${habit.name}');
    print('📅 Date key: $dateKey');
    print('✅ Was completed: $wasCompleted');
    
    // Toggle completion
    final updatedHabit = habit.copyWith(
      completedDates: wasCompleted
          ? habit.completedDates.where((d) => d != dateKey).toList()
          : [...habit.completedDates, dateKey],
    );

    await _dbHelper.updateHabit(updatedHabit);
    await _loadHabits();

    // Show notes dialog ONLY if:
    // 1. Marking as complete (not uncomplete)
    // 2. Context is still mounted
    if (!wasCompleted && mounted) {
      print('📝 Showing notes dialog (manual toggle)...');
      
      // Add small delay to ensure UI is updated
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        _showNotesDialog(updatedHabit, dateKey);
      }
    } else {
      print('⏭️ Skipping notes dialog (wasCompleted: $wasCompleted, mounted: $mounted)');
    }
  }

  Future<void> _showNotesDialog(Habit habit, String dateKey) async {
    print('🎬 Opening notes dialog for: ${habit.name}');
    
    final note = await showDialog<String>(
      context: context,
      barrierDismissible: true, // Can dismiss by tapping outside
      builder: (context) => NotesDialog(
        habitName: habit.name,
        habitIcon: habit.icon,
        existingNote: habit.notes[dateKey],
      ),
    );

    print('📝 Notes dialog result: $note');

    // Only save if note is not null (user didn't cancel)
    if (note != null && mounted) {
      final newNotes = Map<String, String>.from(habit.notes);
      if (note.isNotEmpty) {
        newNotes[dateKey] = note;
        print('💾 Saving note: $note');
      }
      
      final updatedHabit = habit.copyWith(notes: newNotes);
      await _dbHelper.updateHabit(updatedHabit);
      await _loadHabits();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(note.isEmpty ? 'Habit selesai!' : 'Catatan tersimpan!'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToAddHabit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddHabitPage()),
    );
    if (result == true) {
      await _loadHabits();
    }
  }

  void _navigateToDetail(Habit habit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailPage(habit: habit),
      ),
    );
    if (result == true) {
      await _loadHabits();
    }
  }

  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  List<Habit> _getFilteredHabits() {
    if (_selectedFilter == 'All Habit') {
      return _habits;
    }
    
    return _habits.where((habit) {
      if (habit.startTime == null) return false;
      
      final parts = habit.startTime!.split(':');
      final hour = int.parse(parts[0]);
      
      if (_selectedFilter == 'Morning') {
        return hour >= 4 && hour < 12;
      } else if (_selectedFilter == 'Afternoon') {
        return hour >= 12 && hour < 17;
      } else if (_selectedFilter == 'Evening') {
        return hour >= 17 && hour < 21;
      } else if (_selectedFilter == 'Night') {
        return hour >= 21 || hour < 4;
      }
      
      return true;
    }).toList();
  }

  bool _isHabitCompletedOnDate(Habit habit, DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return habit.completedDates.contains(dateKey);
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();
    final filteredHabits = _getFilteredHabits();
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Journal',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime.now();
                      });
                    },
                    child: Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 16,
                        color: isToday ? Colors.black : Colors.grey,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to manage page
                    },
                    child: Text(
                      'Manage',
                      style: TextStyle(
                        fontSize: 16,
                        color: !isToday ? const Color(0xFF0077BE) : Colors.grey,
                        fontWeight: !isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Calendar Week View
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: weekDates.length,
                itemBuilder: (context, index) {
                  final date = weekDates[index];
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month;
                  final isCurrentDay = date.day == DateTime.now().day &&
                      date.month == DateTime.now().month;
                  
                  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0077BE) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFF0077BE)
                              : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isCurrentDay && !isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[400],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            weekdays[date.weekday - 1],
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Filter Chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildFilterChip('☀️', 'Morning'),
                  _buildFilterChip('☁️', 'Afternoon'),
                  _buildFilterChip('🌙', 'Evening'),
                  _buildFilterChip('⭐', 'Night'),
                  _buildFilterChip('🔵', 'All Habit'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Habits List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredHabits.isEmpty
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredHabits.length,
                          itemBuilder: (context, index) {
                            final habit = filteredHabits[index];
                            final isCompleted = _isHabitCompletedOnDate(habit, _selectedDate);

                            return GestureDetector(
                              onTap: () => _navigateToDetail(habit),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Checkbox
                                    GestureDetector(
                                      onTap: () => _toggleHabit(habit),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isCompleted
                                              ? const Color(0xFF0077BE)
                                              : Colors.grey[200],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: isCompleted
                                              ? Colors.white
                                              : Colors.grey[400],
                                          size: 24,
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
                                              fontWeight: FontWeight.w600,
                                              color: isCompleted
                                                  ? Colors.grey[500]
                                                  : Colors.black,
                                            ),
                                          ),
                                          if (habit.startTime != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                _formatTimeDisplay(habit.startTime!),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Arrow Icon
                                    Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      // FloatingActionButton di pojok kanan bawah
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddHabit,
        backgroundColor: const Color(0xFF0077BE),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String emoji, String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0077BE) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF0077BE) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeDisplay(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    
    if (hour == 0) {
      return '12:$minute AM';
    } else if (hour < 12) {
      return '$hour:$minute AM';
    } else if (hour == 12) {
      return '12:$minute PM';
    } else {
      return '${hour - 12}:$minute PM';
    }
  }
}