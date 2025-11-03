import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../database/database_helper.dart';
import '../services/habit_auto_check_service.dart';
import '../widgets/notes_dialog.dart';
import '../widgets/daily_progress_card.dart';
import '../widgets/habit_list_section.dart';
import 'add_habit_page.dart';

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

  void _setupAutoCheckCallback() {
    _autoCheckService.onHabitAutoCompleted = (habit, dateKey) {
      print('🎉 Habit auto-completed: ${habit.name}');
      print('📝 Should show notes dialog...');
      
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
    
    final updatedHabit = habit.copyWith(
      completedDates: wasCompleted
          ? habit.completedDates.where((d) => d != dateKey).toList()
          : [...habit.completedDates, dateKey],
    );

    await _dbHelper.updateHabit(updatedHabit);
    await _loadHabits();

    if (!wasCompleted && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        _showNotesDialog(updatedHabit, dateKey);
      }
    }
  }

  Future<void> _showNotesDialog(Habit habit, String dateKey) async {
    final note = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => NotesDialog(
        habitName: habit.name,
        habitIcon: habit.icon,
        existingNote: habit.notes[dateKey],
      ),
    );

    if (note != null && mounted) {
      final newNotes = Map<String, String>.from(habit.notes);
      if (note.isNotEmpty) {
        newNotes[dateKey] = note;
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

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();
    final filteredHabits = _getFilteredHabits();
    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF64B5F6),
                  Color(0xFF42A5F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Text(
                      'StreakUp',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildTab('Today', isToday),
                        const SizedBox(width: 32),
                        _buildTab('Manage', !isToday),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                    child: SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
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
                              margin: EdgeInsets.only(right: index == weekDates.length - 1 ? 0 : 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.white 
                                    : Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    weekdays[date.weekday - 1],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected 
                                          ? const Color(0xFF42A5F5)
                                          : Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected 
                                          ? const Color(0xFF42A5F5)
                                          : Colors.white,
                                    ),
                                  ),
                                  if (isCurrentDay && !isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Container(
                        height: 50,
                        margin: const EdgeInsets.only(top: 20),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildFilterChip('☀️', 'Morning'),
                            _buildFilterChip('☁️', 'Afternoon'),
                            _buildFilterChip('🌙', 'Evening'),
                            _buildFilterChip('⭐', 'Night'),
                            _buildFilterChip('🔵', 'All Habit'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      HabitListSection(
                        habits: filteredHabits,
                        selectedDate: _selectedDate,
                        onToggleHabit: _toggleHabit,
                      ),

                      const SizedBox(height: 16),

                      DailyProgressCard(
                        selectedDate: _selectedDate,
                        habits: _habits,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddHabit,
        backgroundColor: const Color(0xFF42A5F5),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'Today') {
          setState(() {
            _selectedDate = DateTime.now();
          });
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: Colors.white,
            ),
          ),
          if (isActive)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
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
          color: isSelected ? const Color(0xFF42A5F5) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}