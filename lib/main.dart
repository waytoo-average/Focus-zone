// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';
import 'dart:developer' as developer;

// For notifications and timezone handling
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// Core app components and providers
import 'package:app/app_core.dart';
import 'package:app/helper.dart';
import 'package:app/study_features.dart';
import 'package:app/l10n/app_localizations.dart';

// --- Notification Plugin Instance ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// --- Main Entry Point ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Robust Timezone Initialization ---
  tz.initializeTimeZones();
  final String localTimeZone = await FlutterTimezone.getLocalTimezone();
  try {
    tz.setLocalLocation(tz.getLocation(localTimeZone));
  } catch (e) {
    developer.log('Could not set local timezone: $e', name: 'TimezoneError');
  }

  // --- Notification Plugin Initialization ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
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
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        developer.log(
          'notification payload: ${notificationResponse.payload}',
          name: 'Notifications',
        );
      }
    },
    onDidReceiveBackgroundNotificationResponse:
        _onDidReceiveBackgroundNotificationResponse,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignInProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DownloadPathProvider()),
        ChangeNotifierProvider(create: (_) => RecentFilesProvider()),
        ChangeNotifierProvider(create: (_) => TodoSummaryProvider()),
        ChangeNotifierProvider(create: (_) => FirstLaunchProvider()),
        Provider<FlutterLocalNotificationsPlugin>.value(
            value: flutterLocalNotificationsPlugin),
      ],
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point')
void _onDidReceiveBackgroundNotificationResponse(
    NotificationResponse notificationResponse) {
  developer.log(
      'onDidReceiveBackgroundNotificationResponse: ${notificationResponse.payload}',
      name: 'Notifications Background');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    NotificationService.requestNotificationPermission();

    // --- Theme Color Definitions ---
    final Color primaryDeepNavy = const Color(0xFF1E3A5F);
    final Color accentDarkOrange = const Color(0xFFFF8C00);
    final Color backgroundLight = const Color(0xFFF5F7FA);
    final Color surfaceLight = const Color(0xFFFFFFFF);

    final Color primaryDarkenedNavy = const Color(0xFF152A4A);
    final Color accentLighterOrange = const Color(0xFFFFB300);
    final Color backgroundDark = const Color(0xAE121212);
    final Color surfaceDark = const Color(0xFF1E1E1E);

    // --- ThemeData Definitions ---
    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryDarkenedNavy,
      canvasColor: backgroundDark,
      scaffoldBackgroundColor: backgroundDark,
      useMaterial3: false,
      colorScheme: ColorScheme.dark(
        primary: primaryDarkenedNavy,
        secondary: accentLighterOrange,
        surface: surfaceDark,
        background: backgroundDark,
        error: const Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white70,
        onBackground: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDarkenedNavy,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        toolbarHeight: 64.0,
        elevation: 4.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkenedNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4.0,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        color: surfaceDark,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        tileColor: surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          color: Colors.white70,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentLighterOrange;
          }
          return null;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentLighterOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentLighterOrange, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.white),
        displaySmall: TextStyle(color: Colors.white),
        headlineLarge: TextStyle(color: Colors.white),
        headlineMedium: TextStyle(color: Colors.white),
        headlineSmall: TextStyle(color: Colors.white),
        titleLarge: TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: TextStyle(
            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        titleSmall: TextStyle(
            color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white70),
        labelSmall: TextStyle(color: Colors.white54),
      ),
    );

    final ThemeData lightTheme = ThemeData(
      primaryColor: primaryDeepNavy,
      canvasColor: backgroundLight,
      scaffoldBackgroundColor: backgroundLight,
      useMaterial3: false,
      colorScheme: ColorScheme.light(
        primary: primaryDeepNavy,
        secondary: accentDarkOrange,
        surface: surfaceLight,
        background: backgroundLight,
        error: const Color(0xFFB00020),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.grey[800]!,
        onBackground: Colors.grey[800]!,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDeepNavy,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        toolbarHeight: 64.0,
        elevation: 4.0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDeepNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4.0,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        color: surfaceLight,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        tileColor: surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentDarkOrange;
          }
          return null;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentDarkOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8.0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryDeepNavy, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: Colors.grey[800]),
        displayMedium: TextStyle(color: Colors.grey[800]),
        displaySmall: TextStyle(color: Colors.grey[800]),
        headlineLarge: TextStyle(color: Colors.grey[800]),
        headlineMedium: TextStyle(color: Colors.grey[800]),
        headlineSmall: TextStyle(color: Colors.grey[800]),
        titleLarge: TextStyle(
            color: Colors.grey[900], fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: TextStyle(
            color: Colors.grey[850], fontWeight: FontWeight.w600, fontSize: 18),
        titleSmall: TextStyle(
            color: Colors.grey[600], fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: Colors.grey[800]),
        bodyMedium: TextStyle(color: Colors.grey[700]),
        bodySmall: TextStyle(color: Colors.grey[600]),
        labelLarge: TextStyle(color: Colors.grey[800]),
        labelMedium: TextStyle(color: Colors.grey[700]),
        labelSmall: TextStyle(color: Colors.grey[600]),
      ),
    );

    // Use Consumer2 to efficiently listen to both ThemeProvider and LanguageProvider
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: 'ECCAT Study Station',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
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
          routes: {
            '/': (context) => const SplashScreen(),
            '/rootScreen': (context) => RootScreen(key: rootScreenKey),
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
              if (args == null ||
                  !args.containsKey('fileUrl') ||
                  !args.containsKey('fileId')) {
                return ErrorScreen(message: s.errorNoUrlProvided);
              }
              return PdfViewerScreen(
                fileUrl: args['fileUrl'] as String?,
                fileId: args['fileId'] as String,
                fileName: args['fileName'] as String?,
              );
            },
          },
        );
      },
    );
  }
}
