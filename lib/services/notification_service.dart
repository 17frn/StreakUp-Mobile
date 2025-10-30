import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone FIRST
    tz.initializeTimeZones();
    
    // Get device timezone
    final String? timeZoneName = await FlutterLocalNotificationsPlugin()
        .getNotificationAppLaunchDetails()
        .then((_) {
      // Try to get system timezone
      try {
        return tz.local.name;
      } catch (e) {
        return 'Asia/Jakarta'; // Fallback
      }
    });
    
    tz.setLocalLocation(tz.getLocation(timeZoneName ?? 'Asia/Jakarta'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions immediately
    await requestPermission();

    _initialized = true;
    
    print('✅ Notification service initialized with timezone: ${tz.local.name}');
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to habit detail when notification tapped
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      // Request notifications permission
      final notifGranted = await android.requestNotificationsPermission();
      
      // Request exact alarm permission (Android 12+)
      final alarmGranted = await android.requestExactAlarmsPermission();
      
      print('📱 Notification permission: $notifGranted');
      print('⏰ Exact alarm permission: $alarmGranted');
      
      return notifGranted ?? false;
    }
    
    return true; // iOS handles permission automatically
  }

  /// Schedule notification before habit start time
  Future<void> scheduleHabitReminder({
    required Habit habit,
    required int minutesBefore,
  }) async {
    if (habit.startTime == null) return;

    await cancelHabitNotifications(habit.id!);

    final parts = habit.startTime!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Calculate reminder time
    var reminderTime = DateTime.now();
    reminderTime = DateTime(
      reminderTime.year,
      reminderTime.month,
      reminderTime.day,
      hour,
      minute,
    ).subtract(Duration(minutes: minutesBefore));

    // If time already passed today, schedule for tomorrow
    if (reminderTime.isBefore(DateTime.now())) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    final tzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _notifications.zonedSchedule(
      habit.id!, // Unique ID per habit
      '⏰ Pengingat: ${habit.name}',
      'Waktunya ${habit.name} dalam $minutesBefore menit!',
      tzDateTime,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'habit_${habit.id}',
    );
  }

  /// Schedule notification before habit end time
  Future<void> scheduleHabitEndingReminder({
    required Habit habit,
    required int minutesBefore,
  }) async {
    if (habit.endTime == null) return;

    final parts = habit.endTime!.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Calculate reminder time
    var reminderTime = DateTime.now();
    reminderTime = DateTime(
      reminderTime.year,
      reminderTime.month,
      reminderTime.day,
      hour,
      minute,
    ).subtract(Duration(minutes: minutesBefore));

    // If time already passed today, schedule for tomorrow
    if (reminderTime.isBefore(DateTime.now())) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    final tzDateTime = tz.TZDateTime.from(reminderTime, tz.local);

    // Use different ID for end reminder (habit.id + 10000)
    await _notifications.zonedSchedule(
      habit.id! + 10000,
      '⚠️ ${habit.name} akan berakhir!',
      'Masih ada $minutesBefore menit untuk menyelesaikannya!',
      tzDateTime,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit_end_${habit.id}',
    );
  }

  /// Cancel all notifications for a habit
  Future<void> cancelHabitNotifications(int habitId) async {
    await _notifications.cancel(habitId); // Start reminder
    await _notifications.cancel(habitId + 10000); // End reminder
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get notification details
  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Pengingat Habit',
      channelDescription: 'Notifikasi pengingat untuk habit harian',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      visibility: NotificationVisibility.public,
      autoCancel: false,
      ongoing: false,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    
    return true;
  }

  /// Show instant notification (for testing)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      _notificationDetails(),
    );
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Print all pending notifications (debug)
  Future<void> debugPendingNotifications() async {
    final pending = await getPendingNotifications();
    print('📋 Pending notifications: ${pending.length}');
    for (var notif in pending) {
      print('  - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}');
    }
  }
}