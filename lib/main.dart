// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:developer' as developer;

// For notifications only
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Core app components and providers
import 'package:app/app_core.dart';
import 'package:app/study_features.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/src/utils/app_theme.dart';
import 'package:app/src/utils/app_animations.dart';
import 'package:app/src/utils/download_manager_v3.dart' as new_dm;

// --- App Initialization ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global download manager instance for notification actions
new_dm.FullQuranDownloadManager? globalDownloadManager;

// --- Main Entry Point ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global download manager
  globalDownloadManager = new_dm.FullQuranDownloadManager();

  // Ensure the manager is properly initialized
  await globalDownloadManager!.loadState();

  // Timezone and notification setup
  tz.initializeTimeZones();
  final String localTimeZone = await FlutterTimezone.getLocalTimezone();
  try {
    tz.setLocalLocation(tz.getLocation(localTimeZone));
  } catch (e) {
    developer.log('Could not set local timezone: $e', name: 'TimezoneError');
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_stat_notify');
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // No action handling needed - notifications are read-only
      print('🔔 Notification tapped: ${response.payload}');
    },
    onDidReceiveBackgroundNotificationResponse:
        _onDidReceiveBackgroundNotificationResponse,
  );

  // Create notification channels
  const AndroidNotificationChannel prayerChannel = AndroidNotificationChannel(
    'prayer_times_channel',
    'Prayer Times',
    description: 'Prayer time notifications',
    importance: Importance.max,
  );

  const AndroidNotificationChannel todoChannel = AndroidNotificationChannel(
    'task_reminders_channel',
    'Task Reminders',
    description: 'Reminders for your tasks',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(prayerChannel);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(todoChannel);

  // --- Providers ---
  final dynamicFolderProvider = DynamicFolderProvider();
  // Preload cached folders for offline access
  dynamicFolderProvider.preloadCache();
  
  runApp(
    MultiProvider(
      providers: [
        // SignInProvider removed - authentication no longer needed
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DownloadPathProvider()),
        ChangeNotifierProvider(create: (_) => RecentFilesProvider()),
        ChangeNotifierProvider(create: (_) => TodoSummaryProvider()),
        ChangeNotifierProvider(create: (_) => FirstLaunchProvider()),
        ChangeNotifierProvider(create: (_) => UserInfoProvider()),
        ChangeNotifierProvider(create: (_) => UserFeedbackProvider()),
        ChangeNotifierProvider(create: (_) => DeveloperSuggestionsProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = LeaderModeProvider();
          provider.initialize(); // Initialize authentication state on app start
          return provider;
        }),
        ChangeNotifierProvider.value(value: dynamicFolderProvider),
        ChangeNotifierProvider(create: (_) => globalDownloadManager!),
        Provider<FlutterLocalNotificationsPlugin>.value(
            value: flutterLocalNotificationsPlugin),
      ],
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse) async {
  // Handle background notification actions
  // No action handling needed - notifications are read-only
}

// --- App Widget Tree ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer2 to efficiently listen to both ThemeProvider and LanguageProvider
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: MaterialApp(
            title: 'Focus Zone',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            // --- Routing ---
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return AppPageRouteBuilder(
                    child: const SplashScreen(),
                    transitionType: PageTransitionType.slideFromBottom,
                  );
                case '/rootScreen':
                  return AppPageRouteBuilder(
                    child: RootScreen(key: rootScreenKey),
                    transitionType: PageTransitionType.fadeIn,
                  );
                default:
                  return null;
              }
            },
            routes: {
              '/googleDriveViewer': (context) {
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                return GoogleDriveViewerScreen(
                  embedUrl: args?['embedUrl'] as String?,
                  fileId: args?['fileId'] as String?,
                  fileName: args?['fileName'] as String?,
                  mimeType: args?['mimeType'] as String?,
                );
              },
              '/lectureFolderBrowser': (context) {
                final args =
                    ModalRoute.of(context)?.settings.arguments as String?;
                return LectureFolderBrowserScreen(initialFolderId: args);
              },
              '/pdfViewer': (context) {
                final args = ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
                final s = AppLocalizations.of(context);
                if (s == null) {
                  return const ErrorScreen(
                      message: 'Error: Localization not available.');
                }
                if (args == null) {
                  return ErrorScreen(message: s.errorNoUrlProvided);
                }
                final String? localPath = args['localPath'] as String?;
                final String? fileUrl = args['fileUrl'] as String?;
                final String? fileId = args['fileId'] as String?;
                final String? fileName = args['fileName'] as String?;
                // Allow either localPath or (fileUrl + fileId)
                if ((localPath == null || localPath.isEmpty) &&
                    (fileUrl == null ||
                        fileUrl.isEmpty ||
                        fileId == null ||
                        fileId.isEmpty)) {
                  return ErrorScreen(message: s.errorNoUrlProvided);
                }
                return PdfViewerScreen(
                  fileUrl: fileUrl,
                  fileId: (fileId ?? ''),
                  fileName: fileName,
                  localPath: localPath,
                );
              },
            },
          ),
        );
      },
    );
  }
}
