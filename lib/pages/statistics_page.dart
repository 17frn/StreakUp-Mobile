import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../database/database_helper.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    final habits = await _dbHelper.getHabits();
    setState(() {
      _habits = habits;
      _isLoading = false;
    });
  }

  int _getTotalCompletions() {
    return _habits.fold(0, (sum, habit) => sum + habit.completedDates.length);
  }

  int _getCompletionsThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    int count = 0;
    for (var habit in _habits) {
      for (var dateStr in habit.completedDates) {
        final parts = dateStr.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        
        if (date.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
          count++;
        }
      }
    }
    return count;
  }

  int _getCompletionsToday() {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month}-${today.day}';
    
    return _habits.where((habit) => habit.completedDates.contains(dateKey)).length;
  }

  Habit? _getBestStreak() {
    if (_habits.isEmpty) return null;
    
    return _habits.reduce((current, next) => 
      next.getCurrentStreak() > current.getCurrentStreak() ? next : current
    );
  }

  @override
  Widget build(BuildContext context) {
    final bestStreak = _getBestStreak();
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Progress',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatCard(
                            'Hari Ini',
                            _getCompletionsToday().toString(),
                            'habit diselesaikan',
                            Icons.today,
                            const Color(0xFF0077BE),
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            'Minggu Ini',
                            _getCompletionsThisWeek().toString(),
                            'total penyelesaian',
                            Icons.calendar_today,
                            const Color(0xFF87CEEB),
                          ),
                          const SizedBox(height: 12),
                          _buildStatCard(
                            'Total Semua',
                            _getTotalCompletions().toString(),
                            'habit diselesaikan',
                            Icons.emoji_events,
                            const Color(0xFFFFD700),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Streak Terbaik',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (bestStreak != null && bestStreak.getCurrentStreak() > 0)
                            Card(
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF87CEEB).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          bestStreak.icon,
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bestStreak.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.local_fire_department,
                                                size: 20,
                                                color: Color(0xFFFF6B35),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${bestStreak.getCurrentStreak()} hari beruntun',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFFFF6B35),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Card(
                              color: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'Belum ada streak',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          const Text(
                            'Semua Habit',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._habits.map((habit) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF87CEEB).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    habit.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              title: Text(
                                habit.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${habit.completedDates.length} kali diselesaikan',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: habit.getCurrentStreak() > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.local_fire_department,
                                            size: 16,
                                            color: Color(0xFFFF6B35),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${habit.getCurrentStreak()}',
                                            style: const TextStyle(
                                              color: Color(0xFFFF6B35),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null,
                            ),
                          )),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 30,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0077BE),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}