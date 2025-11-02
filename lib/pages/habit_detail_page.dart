import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../database/database_helper.dart';
import 'habit_time_settings_page.dart';

class HabitDetailPage extends StatefulWidget {
  final Habit habit;

  const HabitDetailPage({Key? key, required this.habit}) : super(key: key);

  @override
  State<HabitDetailPage> createState() => _HabitDetailPageState();
}

class _HabitDetailPageState extends State<HabitDetailPage> {
  late Habit _habit;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _habit = widget.habit;
    _loadHabit();
  }

  Future<void> _loadHabit() async {
    final habit = await _dbHelper.getHabit(widget.habit.id!);
    if (habit != null && mounted) {
      setState(() {
        _habit = habit;
      });
    }
  }

  Future<void> _navigateToTimeSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitTimeSettingsPage(habit: _habit),
      ),
    );
    if (result == true) {
      await _loadHabit();
    }
  }

  Future<void> _toggleDate(DateTime date) async {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    
    final updatedHabit = _habit.copyWith(
      completedDates: _habit.completedDates.contains(dateKey)
          ? _habit.completedDates.where((d) => d != dateKey).toList()
          : [..._habit.completedDates, dateKey],
    );

    await _dbHelper.updateHabit(updatedHabit);
    setState(() {
      _habit = updatedHabit;
    });
  }

  bool _isDateCompleted(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return _habit.completedDates.contains(dateKey);
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _habit.completedDates.isEmpty
        ? 0.0
        : (_habit.completedDates.length / 30 * 100).clamp(0.0, 100.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Habit'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            tooltip: 'Atur Waktu',
            onPressed: _navigateToTimeSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF0077BE),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _habit.icon,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _habit.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_habit.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _habit.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_habit.startTime != null || _habit.endTime != null)
                    Card(
                      color: const Color(0xFF87CEEB).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Color(0xFF0077BE),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Waktu Habit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_habit.startTime ?? "?"} - ${_habit.endTime ?? "?"}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0077BE),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: const Color(0xFF0077BE),
                              onPressed: _navigateToTimeSettings,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_habit.startTime != null || _habit.endTime != null)
                    const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Streak',
                          '${_habit.getCurrentStreak()}',
                          'hari',
                          Icons.local_fire_department,
                          const Color(0xFFFF6B35),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          'Total',
                          '${_habit.completedDates.length}',
                          'kali',
                          Icons.check_circle,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tingkat Penyelesaian',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: completionRate / 100,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF0077BE),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${completionRate.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0077BE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Riwayat 30 Hari Terakhir',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCalendarGrid(),
                  
                  const SizedBox(height: 24),
                  const Text(
                    '📝 Catatan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNotesHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final now = DateTime.now();
    final days = List.generate(30, (index) {
      return now.subtract(Duration(days: 29 - index));
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final date = days[index];
        final isCompleted = _isDateCompleted(date);
        final isToday = date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;

        return GestureDetector(
          onTap: () => _toggleDate(date),
          child: Container(
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF0077BE)
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: const Color(0xFF87CEEB), width: 2)
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.white : Colors.grey[700],
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesHistory() {
    final sortedNotes = _habit.getSortedNotes();
    
    if (sortedNotes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.note_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  'Belum ada catatan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedNotes.length,
      itemBuilder: (context, index) {
        final entry = sortedNotes[index];
        final dateKey = entry.key;
        final note = entry.value;
        
        final parts = dateKey.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        final formattedDate = '${date.day} ${months[date.month - 1]} ${date.year}';
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0077BE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.note,
                color: Color(0xFF0077BE),
                size: 20,
              ),
            ),
            title: Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Catatan?'),
                    content: const Text('Catatan ini akan dihapus permanen.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  final newNotes = Map<String, String>.from(_habit.notes);
                  newNotes.remove(dateKey);
                  
                  final updatedHabit = _habit.copyWith(notes: newNotes);
                  await _dbHelper.updateHabit(updatedHabit);
                  setState(() {
                    _habit = updatedHabit;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Catatan dihapus'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      },
    );
  }
}