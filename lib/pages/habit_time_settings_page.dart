import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class HabitTimeSettingsPage extends StatefulWidget {
  final Habit habit;

  const HabitTimeSettingsPage({Key? key, required this.habit}) : super(key: key);

  @override
  State<HabitTimeSettingsPage> createState() => _HabitTimeSettingsPageState();
}

class _HabitTimeSettingsPageState extends State<HabitTimeSettingsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _notificationEnabled = false;
  int _reminderMinutes = 15;
  bool _endReminderEnabled = false;
  int _endReminderMinutes = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Load existing times if available
    if (widget.habit.startTime != null) {
      final parts = widget.habit.startTime!.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (widget.habit.endTime != null) {
      final parts = widget.habit.endTime!.split(':');
      _endTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    // Load notification settings
    _notificationEnabled = widget.habit.notificationEnabled;
    _reminderMinutes = widget.habit.reminderMinutes;
  }

  Future<void> _selectStartTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0077BE),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0077BE),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Belum diatur';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveTimeSettings() async {
    // Check if notification permission granted
    if (_notificationEnabled) {
      final hasPermission = await _notificationService.areNotificationsEnabled();
      if (!hasPermission) {
        final granted = await _notificationService.requestPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Izin notifikasi ditolak. Aktifkan di pengaturan.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _notificationEnabled = false);
          return;
        }
      }
    }

    final updatedHabit = widget.habit.copyWith(
      startTime: _startTime != null ? _formatTime(_startTime) : null,
      endTime: _endTime != null ? _formatTime(_endTime) : null,
      notificationEnabled: _notificationEnabled,
      reminderMinutes: _reminderMinutes,
    );

    await _dbHelper.updateHabit(updatedHabit);

    // Schedule notifications
    if (_notificationEnabled && _startTime != null) {
      await _notificationService.scheduleHabitReminder(
        habit: updatedHabit,
        minutesBefore: _reminderMinutes,
      );
    } else {
      // Cancel notifications if disabled
      await _notificationService.cancelHabitNotifications(widget.habit.id!);
    }

    // Schedule end reminder
    if (_endReminderEnabled && _endTime != null) {
      await _notificationService.scheduleHabitEndingReminder(
        habit: updatedHabit,
        minutesBefore: _endReminderMinutes,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan berhasil disimpan'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _clearTimeSettings() async {
    final updatedHabit = widget.habit.copyWith(
      startTime: null,
      endTime: null,
      notificationEnabled: false,
      reminderMinutes: 15,
    );

    await _dbHelper.updateHabit(updatedHabit);

    // Cancel all notifications
    await _notificationService.cancelHabitNotifications(widget.habit.id!);

    if (mounted) {
      setState(() {
        _startTime = null;
        _endTime = null;
        _notificationEnabled = false;
        _reminderMinutes = 15;
        _endReminderEnabled = false;
        _endReminderMinutes = 30;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan waktu dan notifikasi dihapus'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showInstantNotification(
      title: '🔔 Test Notifikasi',
      body: 'Notifikasi untuk habit "${widget.habit.name}" berfungsi!',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi test dikirim!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atur Waktu & Pengingat'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Notifikasi',
            onPressed: _testNotification,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit Info Card
            Card(
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
                          widget.habit.icon,
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
                            widget.habit.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.habit.description.isNotEmpty)
                            Text(
                              widget.habit.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF87CEEB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0077BE).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF0077BE),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Atur waktu dan aktifkan pengingat untuk habit ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Start Time
            const Text(
              'Waktu Mulai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectStartTime,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF87CEEB).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFF0077BE),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mulai',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_startTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0077BE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // End Time
            const Text(
              'Waktu Selesai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectEndTime,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selesai',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_endTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Notification Section
            const Divider(),
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Color(0xFF0077BE)),
                const SizedBox(width: 12),
                const Text(
                  'Pengingat Notifikasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Enable Notification Switch
            Card(
              child: SwitchListTile(
                title: const Text('Aktifkan Pengingat'),
                subtitle: const Text('Notifikasi sebelum waktu habit dimulai'),
                value: _notificationEnabled,
                activeColor: const Color(0xFF0077BE),
                onChanged: _startTime != null
                    ? (value) {
                        setState(() => _notificationEnabled = value);
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            // Reminder Time Dropdown
            if (_notificationEnabled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingatkan saya',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _reminderMinutes,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 5,
                            child: Text('5 menit sebelumnya'),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text('10 menit sebelumnya'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('15 menit sebelumnya'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 menit sebelumnya'),
                          ),
                          DropdownMenuItem(
                            value: 60,
                            child: Text('1 jam sebelumnya'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _reminderMinutes = value!);
                        },
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTimeSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077BE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan Pengaturan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Clear Button
            if (_startTime != null || _endTime != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _clearTimeSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B35),
                    side: const BorderSide(color: Color(0xFFFF6B35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hapus Semua Pengaturan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}