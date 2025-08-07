// lib/notification_manager.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/todo_features.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/src/utils/download_manager_v3.dart' as download_manager;

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

    if (scheduleDateTime.isBefore(now)) {
      await plugin.cancel(task.hashCode);
      return;
    }

    final tz.TZDateTime tzScheduleDateTime =
        tz.TZDateTime.from(scheduleDateTime, tz.local);
    const androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'Reminders for your tasks',
      importance: Importance.max,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

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
    try {
      print('🔔 Showing Quran download notification');

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
          enableVibration: false,
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
    try {
      print(
          '🔔 Updating Quran download notification: $title - $body (Progress: $progress%)');

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
          enableVibration: false,
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
}
