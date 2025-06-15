// main.dart - MINIMAL CODE - Final complete version with all features and fixes

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

    // New Color Scheme - Inspired by calming green/blue and warm accents
    // Light Theme Colors
    final Color primaryGreenLight = const Color(0xFF3043AE); // A fresh green
    final Color accentOrangeLight = const Color(0xFFFFB300); // Warm amber
    final Color backgroundLight = const Color(0xFFF0F4F8); // Soft light grey-blue
    final Color cardLight = Colors.white;

    // Dark Theme Colors
    final Color primaryGreenDark = const Color(0xFF2F41A6); // A deeper green
    final Color accentOrangeDark = const Color(0xFFFFCC80); // Lighter amber for dark theme visibility
    final Color backgroundDark = const Color(0xFF263238); // Deep charcoal
    final Color cardDark = const Color(0xFF37474F); // Darker charcoal for cards

    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryGreenDark, // Explicitly set primary color
      canvasColor: backgroundDark, // Affects bottom sheets, dialogs etc.
      scaffoldBackgroundColor: backgroundDark, // Set Scaffold background back to solid color
      useMaterial3: false, // Ensure consistent Material 2 design if not fully ready for M3
      colorScheme: ColorScheme.dark(
        primary: primaryGreenDark,
        secondary: accentOrangeDark, // Accent color for secondary actions/highlights
        surface: cardDark, // Card background color
        background: backgroundDark, // Scaffold background color
        error: Colors.red[700]!, // Error color
        onPrimary: Colors.white,
        onSecondary: Colors.black, // Still black for contrast on light accent
        onSurface: Colors.white70, // Text on cards/surfaces
        onBackground: Colors.white, // Text on scaffold background
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreenDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        toolbarHeight: 80.0,
        elevation: 0.0, // Flatter design
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenDark, // Dark primary for dark theme buttons
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56), // Slightly smaller, common button height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // More rounded corners
            side: BorderSide(color: primaryGreenDark.withOpacity(0.5), width: 1), // Subtle border
          ),
          elevation: 4.0, // Some elevation
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)), // More rounded cards
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        color: cardDark, // Apply card dark color
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // More vertical padding
        tileColor: cardDark, // Match card color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        titleTextStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white, // Default text color for list tiles
        ),
        subtitleTextStyle: const TextStyle(
          fontSize: 13,
          color: Colors.white70, // Slightly lighter for subtitle
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentOrangeDark; // Use accent color for selected checkbox
          }
          return null;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentOrangeDark, // Use accent orange for FAB
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Match other rounded elements
        elevation: 6.0,
      ),
      // Input field decoration for TextFields like quick add and new task
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark, // Match card background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border by default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent), // No border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreenDark, width: 2), // Corrected: use borderSide
        ),
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white), // Default text color
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge:
        TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), // Larger titles
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17),
        bodySmall: TextStyle(color: Colors.white54),
      ),
    );

    final ThemeData lightTheme = ThemeData(
      primarySwatch: Colors.green, // Base for primary color, will be overridden
      primaryColor: primaryGreenLight, // Explicitly set primary color
      canvasColor: backgroundLight, // Affects bottom sheets, dialogs etc.
      scaffoldBackgroundColor: backgroundLight, // Set Scaffold background back to solid color
      useMaterial3: false, // Ensure consistent Material 2 design if not fully ready for M3
      colorScheme: ColorScheme.light(
        primary: primaryGreenLight,
        secondary: accentOrangeLight, // Accent color
        surface: cardLight, // Card background
        background: backgroundLight, // Scaffold background
        error: Colors.red[700]!,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.grey[800]!,
        onBackground: Colors.grey[800]!,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreenLight,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        toolbarHeight: 80.0,
        elevation: 0.0, // Flatter design
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenLight, // Light primary for light theme buttons
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: primaryGreenLight.withOpacity(0.5), width: 1),
          ),
          elevation: 4.0,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)), // More rounded cards
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        color: cardLight, // Apply card light color
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // More vertical padding
        tileColor: cardLight, // Match card color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800], // Default text color for list tiles
        ),
        subtitleTextStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey[600], // Slightly lighter for subtitle
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return accentOrangeLight; // Use accent color for selected checkbox
          }
          return null;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentOrangeLight, // Use accent orange for FAB
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6.0,
      ),
      // Input field decoration for TextFields like quick add and new task
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundLight, // A light background for input fields
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border by default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent), // No border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryGreenLight, width: 2), // Corrected: use borderSide
        ),
        hintStyle: TextStyle(color: Colors.grey[500]),
        labelStyle: TextStyle(color: Colors.grey[700]),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.grey[800]),
        bodyMedium: TextStyle(color: Colors.grey[700]),
        titleLarge:
        TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: Colors.grey[850], fontWeight: FontWeight.w600, fontSize: 17),
        bodySmall: TextStyle(color: Colors.grey[600]),
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
              final args = ModalRoute.of(context)?.settings.arguments as String?;
              return GoogleDriveViewerScreen(embedUrl: args);
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