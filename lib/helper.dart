// lib/helper.dart

import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static bool isAnyPermissionBeingRequested = false;

  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> requestNotificationPermission() async {
    while (isAnyPermissionBeingRequested) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    isAnyPermissionBeingRequested = true;
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }

      if (!await AndroidUtils.canScheduleExactAlarms()) {
        await AndroidUtils.openExactAlarmSettingsIfRequired();
      }
    } finally {
      isAnyPermissionBeingRequested = false;
    }
  }

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();

    try {
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (e) {
      // print(e.toString());
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'due_day_channel',
      'Due Day Notifications',
      importance: Importance.high,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

class AndroidUtils {
  static Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final canSchedule = await NotificationService.notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    return true;
  }

  static Future<void> openExactAlarmSettingsIfRequired() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 31) {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        );
        await intent.launch();
      }
    }
  }
}
