// lib/notification_manager.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/todo_features.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/zikr_features.dart';
import 'package:app/app_core.dart';

class NotificationManager {
  NotificationManager._privateConstructor();
  static final NotificationManager instance =
      NotificationManager._privateConstructor();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  // --- Quran Download Notifications ---
  static const int _quranDownloadNotificationId = 1001;
  static const String _quranDownloadChannelId = 'quran_download_channel';
  static const String _quranDownloadChannelName = 'Quran Download';
  static const String _quranDownloadChannelDescription =
      'Download progress notifications';

  static Future<void> scheduleTodoNotification(
      BuildContext context, TodoItem task, AppLocalizations s) async {
    final prefs = await SharedPreferences.getInstance();
    final todoEnabled = prefs.getBool('notif_todo_enabled') ?? true;
    if (!todoEnabled) {
      final plugin =
          Provider.of<FlutterLocalNotificationsPlugin>(context, listen: false);
      await plugin.cancel(task.hashCode);
      return;
    }

    final plugin =
        Provider.of<FlutterLocalNotificationsPlugin>(context, listen: false);
    if (task.dueDate == null || task.dueTime == null || task.isCompleted) {
      await plugin.cancel(task.hashCode);
      return;
    }

    final now = DateTime.now();
    DateTime scheduleDateTime = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      task.dueTime!.hour,
      task.dueTime!.minute,
    );

    // --- Integrate vibration and timing settings ---
    final todoVibration = prefs.getBool('notif_todo_vibration') ?? true;
    final taskTimeIdx = prefs.getInt('notif_task_time') ?? 0;
    // Map TaskNotificationTimeOption index to Duration
    final List<Duration> advanceDurations = [
      Duration.zero, // atDeadline
      const Duration(minutes: 5),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(hours: 1),
      const Duration(hours: 2),
      const Duration(hours: 3),
    ];
    final advance = (taskTimeIdx >= 0 && taskTimeIdx < advanceDurations.length)
        ? advanceDurations[taskTimeIdx]
        : Duration.zero;
    final scheduledDateTime = scheduleDateTime.subtract(advance);
    if (scheduledDateTime.isBefore(now)) {
      await plugin.cancel(task.hashCode);
      return;
    }
    final tz.TZDateTime tzScheduleDateTime =
        tz.TZDateTime.from(scheduledDateTime, tz.local);
    final androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'Reminders for your tasks',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: todoVibration,
      playSound: true,
    );
    final notificationDetails = NotificationDetails(android: androidDetails);

    DateTimeComponents? dateTimeComponents;
    if (task.isRepeating) {
      if (task.repeatInterval == s.daily)
        dateTimeComponents = DateTimeComponents.time;
      else if (task.repeatInterval == s.weekly)
        dateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
      else if (task.repeatInterval == s.monthly)
        dateTimeComponents = DateTimeComponents.dayOfMonthAndTime;
    }

    await plugin.cancel(task.hashCode);
    await plugin.zonedSchedule(
      task.hashCode,
      s.appTitle,
      '${s.notificationReminderBody} ${task.title}',
      tzScheduleDateTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime, // FIX
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: dateTimeComponents,
      payload: 'task_id:${task.hashCode}',
    );
  }

  static Future<void> cancelTodoNotification(
      BuildContext context, TodoItem task) async {
    final plugin =
        Provider.of<FlutterLocalNotificationsPlugin>(context, listen: false);
    await plugin.cancel(task.hashCode);
  }

  // --- Quran Download Notifications ---
  static Future<void> showQuranDownloadNotification(
      BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final quranEnabled = prefs.getBool('notif_quran_enabled') ?? true;
    if (!quranEnabled) {
      await instance.plugin.cancel(_quranDownloadNotificationId);
      return;
    }

    try {
      print('🔔 Showing Quran download notification');

      final quranVibration = prefs.getBool('notif_quran_vibration') ?? true;

      // Create a more persistent notification for modern Android
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _quranDownloadChannelId,
          _quranDownloadChannelName,
          channelDescription: _quranDownloadChannelDescription,
          importance:
              Importance.max, // Use max importance for better persistence
          priority: Priority.max, // Use max priority
          ongoing: true,
          autoCancel: false,
          enableVibration: quranVibration,
          playSound: false,
          silent: true,
          category: AndroidNotificationCategory.progress,
          visibility: NotificationVisibility.public,
          showWhen: false,
          icon: 'ic_stat_notify',
          // Add these for better persistence on modern Android
          channelShowBadge: true,
          onlyAlertOnce: false,
          // Make it more prominent
          styleInformation: BigTextStyleInformation(
            'Starting download...\nThis notification will show download progress',
            htmlFormatBigText: false,
            contentTitle: 'Quran Download',
            htmlFormatContentTitle: false,
            summaryText: 'Download in progress',
            htmlFormatSummaryText: false,
          ),
        ),
      );

      await instance.plugin.show(
        _quranDownloadNotificationId,
        'Quran Download',
        'Starting download...',
        notificationDetails,
        payload: 'quran_download',
      );
    } catch (e) {
      print('❌ Error showing Quran download notification: $e');
    }
  }

  static Future<void> updateQuranDownloadNotification(
      BuildContext context, String title, String body,
      {int? progress}) async {
    final prefs = await SharedPreferences.getInstance();
    final quranEnabled = prefs.getBool('notif_quran_enabled') ?? true;
    if (!quranEnabled) {
      await instance.plugin.cancel(_quranDownloadNotificationId);
      return;
    }

    try {
      print(
          '🔔 Updating Quran download notification: $title - $body (Progress: $progress%)');

      final quranVibration = prefs.getBool('notif_quran_vibration') ?? true;

      // Create a more detailed body with progress
      String detailedBody = body;
      if (progress != null) {
        detailedBody = '$body\nProgress: $progress%';
      }

      // Create a more persistent notification for modern Android
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _quranDownloadChannelId,
          _quranDownloadChannelName,
          channelDescription: _quranDownloadChannelDescription,
          importance:
              Importance.max, // Use max importance for better persistence
          priority: Priority.max, // Use max priority
          ongoing: true,
          autoCancel: false,
          enableVibration: quranVibration,
          playSound: false,
          silent: true,
          category: AndroidNotificationCategory.progress,
          visibility: NotificationVisibility.public,
          showWhen: false,
          icon: 'ic_stat_notify',
          // Add these for better persistence on modern Android
          channelShowBadge: true,
          onlyAlertOnce: false,
          // Make it more prominent with progress
          styleInformation: BigTextStyleInformation(
            detailedBody,
            htmlFormatBigText: false,
            contentTitle: title,
            htmlFormatContentTitle: false,
            summaryText: 'Download in progress',
            htmlFormatSummaryText: false,
          ),
        ),
      );

      await instance.plugin.show(
        _quranDownloadNotificationId,
        title,
        detailedBody,
        notificationDetails,
        payload: 'quran_download',
      );
    } catch (e) {
      print('❌ Error updating Quran download notification: $e');
    }
  }

  static Future<void> hideQuranDownloadNotification(
      BuildContext context) async {
    try {
      print('🔔 Hiding Quran download notification');
      await instance.plugin.cancel(_quranDownloadNotificationId);
    } catch (e) {
      print('❌ Error hiding Quran download notification: $e');
    }
  }

  static AndroidNotificationDetails _getQuranDownloadNotificationDetails() {
    return const AndroidNotificationDetails(
      _quranDownloadChannelId,
      _quranDownloadChannelName,
      channelDescription: _quranDownloadChannelDescription,
      importance:
          Importance.high, // Changed from low to high for better persistence
      priority: Priority.high, // Changed from low to high
      ongoing: true,
      autoCancel: false,
      enableVibration: false,
      playSound: false,
      silent: true,
      category: AndroidNotificationCategory.progress,
      visibility: NotificationVisibility.public,
      // Additional settings for modern Android persistence
      showWhen: false,
      // Use a custom icon that's more visible
      icon: 'ic_stat_notify',
    );
  }

  /// Schedules notifications for all prayers in today's PrayerData.
  /// Each notification is scheduled based on user timing settings and vibration preferences.
  static Future<void> schedulePrayerNotifications(BuildContext context, AppLocalizations s) async {
    try {
      print('🔔 Scheduling prayer notifications...');
      final prefs = await SharedPreferences.getInstance();
      final prayerEnabled = prefs.getBool('notif_prayer_enabled') ?? true;
      if (!prayerEnabled) {
        print('🔔 Prayer notifications disabled, canceling all');
        await cancelAllPrayerNotifications(context);
        return;
      }
      
      // FIX: Use correct prayer vibration setting
      final prayerVibration = prefs.getBool('notif_prayer_vibration') ?? true;
      final prayerTimeIdx = prefs.getInt('notif_prayer_time') ?? 0;
      final List<Duration> advanceDurations = [
        Duration.zero, // atDeadline
        const Duration(minutes: 5),
        const Duration(minutes: 15),
        const Duration(minutes: 30),
        const Duration(hours: 1),
        const Duration(hours: 2),
        const Duration(hours: 3),
      ];
      final advance = (prayerTimeIdx >= 0 && prayerTimeIdx < advanceDurations.length)
          ? advanceDurations[prayerTimeIdx]
          : Duration.zero;

      final prayerData = await PrayerTimesCache.load();
      if (prayerData == null) {
        print('🔔 No prayer data available for scheduling');
        return;
      }
      
      final now = DateTime.now();
      final plugin = Provider.of<FlutterLocalNotificationsPlugin>(context, listen: false);
      
      // Cancel existing prayer notifications first
      await cancelAllPrayerNotifications(context);
      
      int scheduledCount = 0;
      for (final entry in prayerData.timings.entries) {
        final prayerName = entry.key;
        final timeStr = entry.value;
        final timeParts = timeStr.split(":");
        if (timeParts.length < 2) continue;
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        if (hour == null || minute == null) continue;
        
        // FIX: Correct scheduling logic - subtract advance time from prayer time directly
        final prayerDateTime = DateTime(now.year, now.month, now.day, hour, minute);
        final scheduledDateTime = prayerDateTime.subtract(advance);
        
        // If the scheduled time is in the past, schedule for tomorrow
        DateTime finalScheduledDateTime = scheduledDateTime;
        if (scheduledDateTime.isBefore(now)) {
          finalScheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
        }
        
        final tzScheduleDateTime = tz.TZDateTime.from(finalScheduledDateTime, tz.local);
        final androidDetails = AndroidNotificationDetails(
          'prayer_times_channel',
          'Prayer Times',
          channelDescription: 'Prayer time notifications',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: prayerVibration, // FIX: Use correct setting
          playSound: true,
        );
        final notificationDetails = NotificationDetails(android: androidDetails);
        final notificationId = _prayerNotificationId(prayerName, finalScheduledDateTime);
      
        // Create dynamic notification text based on advance time
        String notificationBody;
        if (advance == Duration.zero) {
          // At prayer time - use original text
          notificationBody = s.prayerNotificationBody(prayerName);
        } else {
          // Calculate time text based on advance duration
          String timeText;
          if (advance.inHours > 0) {
            if (advance.inHours == 1) {
              timeText = s.inOneHour;
            } else {
              timeText = s.inHours(advance.inHours);
            }
          } else {
            if (advance.inMinutes == 1) {
              timeText = s.inOneMinute;
            } else {
              timeText = s.inMinutes(advance.inMinutes);
            }
          }
          notificationBody = s.prayerNotificationBodyAdvance(prayerName, timeText);
        }
        
        await plugin.zonedSchedule(
          notificationId,
          s.appTitle,
          notificationBody,
          tzScheduleDateTime,
          notificationDetails,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'prayer:$prayerName',
        );
        
        scheduledCount++;
        print('🔔 Scheduled $prayerName notification for ${finalScheduledDateTime.toString()}');
      }
      
      print('🔔 Successfully scheduled $scheduledCount prayer notifications');
    } catch (e) {
      print('❌ Error scheduling prayer notifications: $e');
    }
  }

  /// Cancels all prayer notifications for today.
  static Future<void> cancelAllPrayerNotifications(BuildContext context) async {
    final now = DateTime.now();
    final plugin = Provider.of<FlutterLocalNotificationsPlugin>(context, listen: false);
    // Use all possible prayer names
    const prayerNames = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (final name in prayerNames) {
      await plugin.cancel(_prayerNotificationId(name, now));
    }
  }

  /// Reschedules all existing todo notifications with current timing settings
  static Future<void> rescheduleAllTodoNotifications(BuildContext context, AppLocalizations s) async {
    try {
      print('🔔 Rescheduling all todo notifications...');
      final todoProvider = Provider.of<TodoSummaryProvider>(context, listen: false);
      final allTodos = todoProvider.allTodos;
      
      int rescheduledCount = 0;
      for (final todo in allTodos) {
        if (!todo.isCompleted && todo.dueDate != null && todo.dueTime != null) {
          await scheduleTodoNotification(context, todo, s);
          rescheduledCount++;
        }
      }
      
      print('🔔 Rescheduled $rescheduledCount todo notifications');
    } catch (e) {
      print('❌ Error rescheduling todo notifications: $e');
    }
  }

  /// Generates a unique notification ID for a prayer and date.
  static int _prayerNotificationId(String prayerName, DateTime date) {
    return '${prayerName}_${date.year}_${date.month}_${date.day}'.hashCode;
  }
}

