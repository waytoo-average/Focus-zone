// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for SystemNavigator.pop() and Clipboard
import 'package:provider/provider.dart'; // For MultiProvider
import 'package:flutter_localizations/flutter_localizations.dart'; // For localization delegates
import 'dart:async'; // For async ops related to notifications
import 'dart:developer' as developer; // For notification logging

// For notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Core app components, utilities, and all providers
import 'package:app/app_core.dart';

// Feature screens (these are global routes that cover the entire screen)
// Note: These imports are required because MyApp's routes directly reference
// GoogleDriveViewerScreen, LectureFolderBrowserScreen, and PdfViewerScreen.
import 'package:app/study_features.dart'; // Contains GoogleDriveViewerScreen, LectureFolderBrowserScreen, PdfViewerScreen
import 'package:app/l10n/app_localizations.dart'; // For error screen string


// --- Notification Plugin Instance ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


// --- MyApp and main() function ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones(); // Initialize timezone data

  // FIX: Updated Notification Plugin Initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('app_icon');
  final DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings(
    onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
      _onDidReceiveLocalNotification(id, title, body, payload);
    },
  );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      if (notificationResponse.payload != null) {
        developer.log('notification payload: ${notificationResponse.payload}', name: 'Notifications');
      }
    },
    onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse, // Top-level function
  );


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignInProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => DownloadPathProvider()),
        ChangeNotifierProvider(create: (_) => RecentFilesProvider()), // NEW: Added RecentFilesProvider
        ChangeNotifierProvider(create: (_) => TodoSummaryProvider()),  // NEW: Added TodoSummaryProvider
        // Add this line to make the global notification plugin accessible to TodoListScreen
        Provider<FlutterLocalNotificationsPlugin>.value(value: flutterLocalNotificationsPlugin),
      ],
      child: const MyApp(),
    ),
  );
}

@pragma('vm:entry-point') // Required for background execution
void _onDidReceiveBackgroundNotificationResponse(NotificationResponse notificationResponse) {
  developer.log('onDidReceiveBackgroundNotificationResponse: ${notificationResponse.payload}', name: 'Notifications Background');
}

void _onDidReceiveLocalNotification(
    int id, String? title, String? body, String? payload) async {
  developer.log('Notification received in foreground (legacy iOS): $title, $body, $payload', name: 'Notifications');
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    // Color Scheme: Palette 1: "Deep Ocean & Sunset Glow"
    // Light Theme Colors
    final Color primaryDeepNavy = const Color(0xFF1E3A5F); // Primary
    final Color accentDarkOrange = const Color(0xFFFF8C00); // Secondary
    final Color backgroundLight = const Color(0xFFF5F7FA); // Background
    final Color surfaceLight = const Color(0xFFFFFFFF); // Surface (Cards)

    // Dark Theme Colors
    final Color primaryDarkenedNavy = const Color(0xFF152A4A); // Darkened Primary
    final Color accentLighterOrange = const Color(0xFFFFB300); // Lighter Secondary for contrast
    final Color backgroundDark = const Color(0xFF121212); // Deep Black for background
    final Color surfaceDark = const Color(0xFF1E1E1E); // Darker gray for cards/surfaces

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
        error: const Color(0xFFCF6679), // A softer red for dark theme errors
        onPrimary: Colors.white,
        onSecondary: Colors.black, // Still black for contrast on light accent
        onSurface: Colors.white70,
        onBackground: Colors.white,
        onError: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDarkenedNavy,
        foregroundColor: Colors.white,
        centerTitle: false, // Default to false for modern left-alignment
        titleTextStyle: const TextStyle(
          fontSize: 20, // Slightly larger for better hierarchy
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        toolbarHeight: 64.0, // Standard toolbar height
        elevation: 4.0, // Some elevation for depth
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkenedNavy,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52), // Modern button height
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
        elevation: 6.0, // More prominent elevation for cards
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0), // Standardized margin
        color: surfaceDark,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
        fillColor: surfaceDark.withOpacity(0.8), // Slightly transparent for depth
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1), // Subtle border
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
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22), // Main titles
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18), // Section titles
        titleSmall: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70), // Default text color
        bodySmall: TextStyle(color: Colors.white54), // Secondary text
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
        error: const Color(0xFFB00020), // Standard red for errors
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
        fillColor: backgroundLight.withOpacity(0.8), // Slightly transparent for depth
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
        titleLarge: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: TextStyle(color: Colors.grey[850], fontWeight: FontWeight.w600, fontSize: 18),
        titleSmall: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: TextStyle(color: Colors.grey[800]),
        bodyMedium: TextStyle(color: Colors.grey[700]),
        bodySmall: TextStyle(color: Colors.grey[600]),
        labelLarge: TextStyle(color: Colors.grey[800]),
        labelMedium: TextStyle(color: Colors.grey[700]),
        labelSmall: TextStyle(color: Colors.grey[600]),
      ),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final languageProvider = Provider.of<LanguageProvider>(context);

        return MaterialApp(
          key: ValueKey(themeProvider.themeMode),
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
            // These are the only *global* routes remaining in main.dart
            '/googleDriveViewer': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              return GoogleDriveViewerScreen(
                embedUrl: args?['embedUrl'] as String?,
                fileId: args?['fileId'] as String?,
                fileName: args?['fileName'] as String?,
                mimeType: args?['mimeType'] as String?,
              );
            },
            '/lectureFolderBrowser': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as String?;
              return LectureFolderBrowserScreen(initialFolderId: args);
            },
            '/pdfViewer': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final s = AppLocalizations.of(context);
              if (s == null) {
                return const ErrorScreen(message: 'Error: Localization not available.');
              }
              if (args == null || !args.containsKey('fileUrl') || !args.containsKey('fileId')) {
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