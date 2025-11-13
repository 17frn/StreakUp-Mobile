import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Check if current platform supports full notification features
  bool get _supportsLaunchDetails {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if platform supports notifications
  bool get _supportsNotifications {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;
    if (!_supportsNotifications) {
      print('⚠️ Notifications not supported on this platform');
      return;
    }

    // Initialize timezone FIRST
    tz.initializeTimeZones();
    
    // Get device timezone (safe for all platforms)
    String timeZoneName = 'Asia/Jakarta'; // Default fallback
    
    if (_supportsLaunchDetails) {
      try {
        // Only try to get launch details on supported platforms
        await _notifications.getNotificationAppLaunchDetails();
        timeZoneName = tz.local.name;
      } catch (e) {
        print('⚠️ Could not get launch details: $e');
        timeZoneName = tz.local.name;
      }
    } else {
      // For desktop platforms, just use local timezone
      try {
        timeZoneName = tz.local.name;
      } catch (e) {
        print('⚠️ Using fallback timezone');
      }
    }
    
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Platform-specific initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions only on mobile
    if (_supportsLaunchDetails) {
      await requestPermission();
    }

    _initialized = true;
    
    print('✅ Notification service initialized');
    print('   Platform: ${_getPlatformName()}');
    print('   Timezone: ${tz.local.name}');
  }

  /// Get platform name for logging
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    return 'Unknown';
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    // TODO: Navigate to habit detail when notification tapped
    print('Notification tapped: ${response.payload}');
  }

  /// Request notification permission (Mobile only)
  Future<bool> requestPermission() async {
    if (!_supportsLaunchDetails) {
      return true; // Desktop doesn't need explicit permission
    }

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
    if (!_supportsNotifications || habit.startTime == null) return;

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

    // Use different scheduling based on platform
    if (Platform.isAndroid || Platform.isIOS) {
      await _notifications.zonedSchedule(
        habit.id!,
        '⏰ Pengingat: ${habit.name}',
        'Waktunya ${habit.name} dalam $minutesBefore menit!',
        tzDateTime,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_${habit.id}',
      );
    } else {
      // For desktop, use simple show at specific time
      await _notifications.zonedSchedule(
        habit.id!,
        '⏰ Pengingat: ${habit.name}',
        'Waktunya ${habit.name} dalam $minutesBefore menit!',
        tzDateTime,
        _notificationDetails(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_${habit.id}',
      );
    }

    print('📅 Scheduled reminder for ${habit.name} at ${tzDateTime.toString()}');
  }

  /// Schedule notification before habit end time
  Future<void> scheduleHabitEndingReminder({
    required Habit habit,
    required int minutesBefore,
  }) async {
    if (!_supportsNotifications || habit.endTime == null) return;

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
    if (Platform.isAndroid || Platform.isIOS) {
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
    } else {
      await _notifications.zonedSchedule(
        habit.id! + 10000,
        '⚠️ ${habit.name} akan berakhir!',
        'Masih ada $minutesBefore menit untuk menyelesaikannya!',
        tzDateTime,
        _notificationDetails(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'habit_end_${habit.id}',
      );
    }

    print('📅 Scheduled end reminder for ${habit.name} at ${tzDateTime.toString()}');
  }

  /// Cancel all notifications for a habit
  Future<void> cancelHabitNotifications(int habitId) async {
    if (!_supportsNotifications) return;
    
    await _notifications.cancel(habitId); // Start reminder
    await _notifications.cancel(habitId + 10000); // End reminder
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_supportsNotifications) return;
    await _notifications.cancelAll();
  }

  /// Get notification details (platform-aware)
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

    const linuxDetails = LinuxNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
      linux: linuxDetails,
    );
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_supportsNotifications) return false;
    
    if (_supportsLaunchDetails) {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
    }
    
    return true; // Assume enabled on desktop/iOS
  }

  /// Show instant notification (for testing)
  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    if (!_supportsNotifications) {
      print('⚠️ Cannot show notification on this platform');
      return;
    }

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      _notificationDetails(),
    );
  }

  /// Get list of pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_supportsNotifications) return [];
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