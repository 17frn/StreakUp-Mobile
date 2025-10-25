import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../database/database_helper.dart';
import '../widgets/habit_card.dart';
import '../services/habit_auto_check_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadHabits();
    _startAutoCheck();
  }

  void _startAutoCheck() {
    // Check habits every minute
    Future.delayed(Duration.zero, () async {
      while (mounted) {
        await _autoCheckService.checkAllHabits();
        await _loadHabits(); // Reload to show updated status
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
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    
    final updatedHabit = habit.copyWith(
      completedDates: habit.completedDates.contains(dateKey)
          ? habit.completedDates.where((d) => d != dateKey).toList()
          : [...habit.completedDates, dateKey],
    );

    await _dbHelper.updateHabit(updatedHabit);
    await _loadHabits();
  }

  Future<void> _deleteHabit(int id) async {
    await _dbHelper.deleteHabit(id);
    await _loadHabits();
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

  int _getCompletedToday() {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    return _habits.where((h) => h.completedDates.contains(dateKey)).length;
  }

  @override
  Widget build(BuildContext context) {
    final completedToday = _getCompletedToday();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreakUp'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_habits.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0077BE), Color(0xFF87CEEB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Progress Hari Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completedToday / ${_habits.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _habits.isEmpty ? 0 : completedToday / _habits.length,
                            minHeight: 8,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _habits.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada kegiatan',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap tombol + untuk menambahkan kegiatan baru',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadHabits,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _habits.length,
                            itemBuilder: (context, index) {
                              return HabitCard(
                                habit: _habits[index],
                                onToggle: () => _toggleHabit(_habits[index]),
                                onDelete: () => _deleteHabit(_habits[index].id!),
                                onTap: () => _navigateToDetail(_habits[index]),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddHabit,
        child: const Icon(Icons.add),
      ),
    );
  }
}