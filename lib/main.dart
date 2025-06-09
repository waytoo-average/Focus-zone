// main.dart - FULL CODE - Final complete version with all features and fixes

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer; // For log
import 'dart:math'; // For pow in formatBytes
import 'package:flutter/services.dart'; // Import for SystemNavigator.pop()

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive; // aliased as drive
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // For jsonDecode and jsonEncode

// Imports for PDF Caching and Downloading
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // For File operations
import 'package:intl/intl.dart'; // For date formatting

// New imports for file_picker, open_filex, permission_handler
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:app/l10n/app_localizations.dart';

// Import for notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


// --- Notification Plugin Instance ---
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();


// --- Helper for File Size Formatting ---
String formatBytesSimplified(int bytes, int decimals, AppLocalizations s) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (log(bytes) / log(1024)).floor();
  if (i >= suffixes.length) i = suffixes.length - 1;
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

// --- Helper for showing SnackBar Messages ---
void showAppSnackBar(BuildContext context, String message, {IconData? icon, Color? iconColor, SnackBarAction? action, Color? backgroundColor}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.white),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor, // Default to primary color
      action: action,
      duration: const Duration(seconds: 3), // Default duration
      behavior: SnackBarBehavior.floating, // Make it float
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
      margin: const EdgeInsets.all(10), // Margin from edges
    ),
  );
}


// --- Helper class for Google Sign-In HTTP Client ---
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(this._headers));
  }
}

// --- Academic Context Class to pass navigation data ---
class AcademicContext {
  final String grade;
  final String? department;
  final String? year;
  final String? semester;
  final String? subjectName;

  AcademicContext({
    required this.grade,
    this.department,
    this.year,
    this.semester,
    this.subjectName,
  });

  AcademicContext copyWith({
    String? grade,
    String? department,
    String? year,
    String? semester,
    String? subjectName,
  }) {
    return AcademicContext(
      grade: grade ?? this.grade,
      department: department ?? this.department,
      year: year ?? this.year,
      semester: semester ?? this.semester,
      subjectName: subjectName ?? this.subjectName,
    );
  }

  String get displayGrade {
    return grade;
  }

  String get titleString {
    List<String> parts = [displayGrade];
    if (department != null) parts.add(department!);
    if (year != null) parts.add(year!);
    if (semester != null) parts.add(semester!);
    if (subjectName != null) parts.add(subjectName!);
    return parts.join(' > ');
  }
}

// --- SignInProvider for app-wide state management ---
class SignInProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      drive.DriveApi.driveReadonlyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  SignInProvider() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      notifyListeners();
    });
    _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      developer.log('Google Sign-In failed: $error', name: 'SignInProvider');
    }
  }

  Future<void> signOut() => _googleSignIn.signOut();

  Future<http.Client?> get authenticatedHttpClient async {
    final GoogleSignInAccount? user = _currentUser;
    if (user == null) {
      return null;
    }
    final Map<String, String> headers = await user.authHeaders;
    return GoogleHttpClient(headers);
  }
}

// --- ThemeProvider for app-wide theme management ---
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() { _loadThemeMode(); }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere((e) => e.toString().split('.').last == themeString, orElse: () => ThemeMode.system);
    developer.log('Loaded theme mode: $_themeMode', name: 'ThemeProvider'); // Log theme loading
    notifyListeners();
  }

  void setThemeMode(ThemeMode newMode) async {
    if (newMode != _themeMode) {
      developer.log('Setting theme mode from $_themeMode to $newMode', name: 'ThemeProvider'); // Log theme change
      _themeMode = newMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', newMode.toString().split('.').last);
      notifyListeners();
    }
  }
}

// --- LanguageProvider for app-wide language management ---
class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  LanguageProvider() { _loadLocale(); }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(langCode);
    notifyListeners();
  }

  void setLocale(Locale newLocale) async {
    if (newLocale != _locale) {
      _locale = newLocale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', newLocale.languageCode);
      notifyListeners();
    }
  }
}

// --- DownloadPathProvider ---
class DownloadPathProvider extends ChangeNotifier {
  String? _customDownloadPath; // Stores the user-chosen direct file path
  String? get customDownloadPathUri => _customDownloadPath; // Renamed to accurately reflect direct path

  DownloadPathProvider() {
    _loadDownloadPath();
  }

  Future<void> _loadDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    _customDownloadPath = prefs.getString('userDownloadPath');
    developer.log("Loaded custom download path: $_customDownloadPath", name: "DownloadPathProvider");
    notifyListeners();
  }

  // This method now saves the chosen path and triggers reload
  Future<void> setDownloadPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null && path.isNotEmpty) {
      _customDownloadPath = path;
      await prefs.setString('userDownloadPath', path);
      developer.log("Set custom download path: $_customDownloadPath", name: "DownloadPathProvider");
    } else {
      _customDownloadPath = null;
      await prefs.remove('userDownloadPath');
      developer.log("Cleared custom download path.", name: "DownloadPathProvider");
    }
    notifyListeners();
  }

  Future<void> clearCustomDownloadPath() async {
    await setDownloadPath(null); // Use existing setter to clear
    developer.log("Clear custom download path requested. Path has been cleared.", name: "DownloadPathProvider");
    notifyListeners();
  }

  // Gets the app-specific internal downloads directory
  Future<String> _getAppSpecificDownloadPath() async {
    final directory = await getExternalStorageDirectory();
    String path = directory?.path ?? (await getApplicationDocumentsDirectory()).path;

    final appDownloadDir = Directory('$path/StudyStationDownloads');
    if (!await appDownloadDir.exists()) {
      await appDownloadDir.create(recursive: true);
    }
    return appDownloadDir.path;
  }

  // This is the primary method to get the path to use for downloads
  Future<String> getEffectiveDownloadPath() async {
    await _loadDownloadPath(); // Ensure latest path is loaded

    // First, try the user-chosen path if available and seems valid
    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      final customDir = Directory(_customDownloadPath!);
      // Attempt to ensure the directory exists and is writable (best effort check)
      try {
        if (!await customDir.exists()) {
          await customDir.create(recursive: true);
          developer.log("Created custom download directory: $_customDownloadPath", name: "DownloadPathProvider");
        }
        // Additional check: try creating a dummy file to test writability.
        // This is not foolproof for SAF, but can catch simple issues.
        final testFile = File('${customDir.path}/.test_write');
        try {
          await testFile.writeAsString('test');
          await testFile.delete();
          developer.log("Custom path $_customDownloadPath is writable (tested).", name: "DownloadPathProvider");
          return _customDownloadPath!;
        } catch (e) {
          developer.log("Custom path $_customDownloadPath is NOT directly writable: $e", name: "DownloadPathProvider");
          // Fall through to app-specific if not writable
        }
      } catch (e) {
        developer.log("Error checking/creating custom path $_customDownloadPath: $e", name: "DownloadPathProvider");
        // Fall through to app-specific if error
      }
    }

    // Fallback to app-specific path
    final fallbackPath = await _getAppSpecificDownloadPath();
    developer.log("Falling back to app-specific download path: $fallbackPath", name: "DownloadPathProvider");
    return fallbackPath;
  }

  // Dummy method to resolve undefined_method errors if any old code still calls it directly
  // This will now get the effective path, not just the app-specific.
  Future<String> getAppSpecificDownloadPath() async {
    return await _getAppSpecificDownloadPath(); // Keep this for now, but its meaning is shifting slightly
  }
}


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
        ChangeNotifierProvider(create: (_) => DownloadPathProvider()), // Add DownloadPathProvider
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
    final Color primaryGreenLight = const Color(0xFF4CAF50); // A fresh green
    final Color accentOrangeLight = const Color(0xFFFFB300); // Warm amber
    final Color backgroundLight = const Color(0xFFF0F4F8); // Soft light grey-blue
    final Color cardLight = Colors.white;

    // Dark Theme Colors
    final Color primaryGreenDark = const Color(0xFF2E7D32); // A deeper green
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

    return Consumer<ThemeProvider>( // Wrap MaterialApp with Consumer
      builder: (context, themeProvider, child) {
        final languageProvider = Provider.of<LanguageProvider>(context); // Get languageProvider here

        return MaterialApp(
          key: ValueKey(themeProvider.themeMode), // Add a ValueKey to force MaterialApp rebuild
          title: 'ECCAT Study Station',
          debugShowCheckedModeBanner: false,

          themeMode: themeProvider.themeMode,
          theme: lightTheme, // Use the defined light theme
          darkTheme: darkTheme, // Use the defined dark theme

          locale: languageProvider.locale, // This line (around 590) will now have languageProvider in scope
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
            '/startScreen': (context) => const StartScreen(),
            '/grades': (context) => const GradeSelectionScreen(),
            '/departments': (context) {
              final args =
              ModalRoute.of(context)?.settings.arguments as AcademicContext?;
              if (args == null) return ErrorScreen(message: AppLocalizations.of(context)?.errorMissingContext ?? "Missing academic context for departments.");
              return DepartmentSelectionScreen(academicContext: args);
            },
            '/years': (context) {
              final args =
              ModalRoute.of(context)?.settings.arguments as AcademicContext?;
              if (args == null) return ErrorScreen(message: AppLocalizations.of(context)?.errorMissingContext ?? "Missing academic context for years.");
              return YearSelectionScreen(academicContext: args);
            },
            '/semesters': (context) {
              final args =
              ModalRoute.of(context)?.settings.arguments as AcademicContext?;
              if (args == null) return ErrorScreen(message: AppLocalizations.of(context)?.errorMissingContext ?? "Missing academic context for semesters.");
              return SemesterSelectionScreen(academicContext: args);
            },
            '/subjects': (context) {
              final arguments = ModalRoute.of(context)?.settings.arguments;
              Map<String, String> subjectsMap = {};
              AcademicContext? academicContext;

              if (arguments is Map && arguments.containsKey('subjects')) {
                final dynamic rawSubjects = arguments['subjects'];
                if (rawSubjects is Map) {
                  rawSubjects.forEach((key, value) {
                    if (key is String && value is String) {
                      subjectsMap[key] = value;
                    }
                  });
                }
                if (arguments.containsKey('context') &&
                    arguments['context'] is AcademicContext) {
                  academicContext = arguments['context'] as AcademicContext;
                }
              }

              if (academicContext == null) {
                final s = AppLocalizations.of(context);
                return ErrorScreen(message: s?.errorMissingSubjectDetails ?? "Unknown error: Missing academic context.");
              }
              return SubjectSelectionScreen(
                subjects: subjectsMap,
                academicContext: academicContext,
              );
            },
            '/subjectContentScreen': (context) {
              final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
              final s = AppLocalizations.of(context);
              if (s == null) {
                return const ErrorScreen(message: 'Error: Localization not available. Missing subject details.');
              }
              if (args == null || !args.containsKey('subjectName') || !args.containsKey('rootFolderId') || !args.containsKey('academicContext')) {
                return ErrorScreen(message: s.errorMissingSubjectDetails);
              }
              final String subjectName = args['subjectName'] as String;
              final String rootFolderId = args['rootFolderId'] as String;
              final AcademicContext academicContext = args['academicContext'] as AcademicContext;

              return SubjectContentScreen(
                subjectName: subjectName,
                rootFolderId: rootFolderId,
                academicContext: academicContext,
              );
            },
            '/settings': (context) => const SettingsScreen(),
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

              if (args == null || args['fileUrl'] == null || args['fileId'] == null) {
                return ErrorScreen(message: s?.errorNoUrlProvided ?? "PDF viewer arguments missing.");
              }
              return PdfViewerScreen(
                fileUrl: args['fileUrl'] as String?,
                fileId: args['fileId'] as String,
                fileName: args['fileName'] as String?,
              );
            },
            '/about': (context) => const AboutScreen(),
            '/collegeInfo': (context) => const CollegeInfoScreen(),
            '/todoList': (context) => const TodoListScreen(),
          },
        );
      },
    );
  }
}

// --- Basic Error Screen ---
class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.error ?? "Error")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      ),
    );
  }
}


// --- Screen Widgets ---

// 1. Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pushReplacementNamed(context, '/startScreen');
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Text('ECCAT', style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0)),
      ),
    );
  }
}

// Start Screen
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final signInProvider = Provider.of<SignInProvider>(context);
    final user = signInProvider.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Set Scaffold background back to solid background color
      body: Column( // Removed Container with gradient
        children: [
          AppBar( // AppBar remains at the top
            title: Text(s.appTitle),
            automaticallyImplyLeading: false, // No back button on initial screen
            actions: [
              if (user == null)
                TextButton(
                  onPressed: signInProvider.signIn,
                  style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16.0)),
                  child: Text(s.signIn, style: const TextStyle(fontSize: 16)),
                )
              else
                GestureDetector(
                  onTap: () => showAppSnackBar(context, s.signedInAs(user.displayName ?? user.email ?? s.unknownUser), action: SnackBarAction(label: s.signOut, onPressed: signInProvider.signOut), icon: Icons.person_outline),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null ? Text(user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : (user.email.isNotEmpty == true ? user.email[0].toUpperCase() : '?'), style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14)) : null,
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Haptic feedback
                      Navigator.pushNamed(context, '/grades');
                    },
                    child: Text(s.studyButton),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Haptic feedback
                      Navigator.pushNamed(context, '/todoList');
                    },
                    child: Text(s.todoListButton),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Haptic feedback
                      Navigator.pushNamed(context, '/settings');
                    },
                    child: Text(s.settings),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Haptic feedback
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    child: Text(s.exitButton),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// GradeSelectionScreen
class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        leading: IconButton( // Only Home button in leading
          icon: const Icon(Icons.home),
          onPressed: () => Navigator.pushReplacementNamed(context, '/startScreen'),
          tooltip: s.studyButton, // Using studyButton for tooltip. Could add a 'homeButtonTooltip' key if needed.
        ),
        actions: [
          // Only settings button in actions (Google user info moved to StartScreen)
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings'), tooltip: s.settings),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/departments', arguments: AcademicContext(grade: s.firstGrade)), child: Text(s.firstGrade)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/departments', arguments: AcademicContext(grade: s.secondGrade)), child: Text(s.secondGrade)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/departments', arguments: AcademicContext(grade: s.thirdGrade)), child: Text(s.thirdGrade)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/departments', arguments: AcademicContext(grade: s.fourthGrade)), child: Text(s.fourthGrade)),
          ],
        ),
      ),
    );
  }
}

// DepartmentSelectionScreen
class DepartmentSelectionScreen extends StatelessWidget {
  final AcademicContext academicContext;
  const DepartmentSelectionScreen({super.key, required this.academicContext});
  List<String> _getDepartmentStrings(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return [s.communication, s.electronics, s.mechatronics];
  }
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final List<String> departmentOptions = _getDepartmentStrings(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings'), tooltip: s.settings)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(departmentOptions.length, (index) {
            final String localizedDepartment = departmentOptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/years', arguments: academicContext.copyWith(department: localizedDepartment)), child: Text(localizedDepartment)),
            );
          }),
        ),
      ),
    );
  }
}

// YearSelectionScreen
class YearSelectionScreen extends StatelessWidget {
  final AcademicContext academicContext;
  const YearSelectionScreen({super.key, required this.academicContext});
  List<String> _getYearStrings(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return [s.currentYear, s.lastYear];
  }
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final List<String> yearOptions = _getYearStrings(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings'), tooltip: s.settings)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(yearOptions.length, (index) {
            final String localizedYear = yearOptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/semesters', arguments: academicContext.copyWith(year: localizedYear)), child: Text(localizedYear)),
            );
          }),
        ),
      ),
    );
  }
}

// SemesterSelectionScreen
class SemesterSelectionScreen extends StatelessWidget {
  final AcademicContext academicContext;
  const SemesterSelectionScreen({super.key, required this.academicContext});
  final Map<String, String> authorizedSemester2Subjects = const { 'قضايا مجتمعية': '1wyuL_okkhbtFHNcSkKzXvc-wK7G420wj', 'علوم حاسب': '14VYnkax5I9hXgaExRXYWQaz6mWlg59l3', 'تصميم دوائر الاتصالات': '1mFSHV7BPzUoaf7Au8FssGFL6mtNIzz4s', 'اساسيات تكنولوجيا الشبكات': '1-y8Wk3Aa5G_WyyHCdIY_GP2XGDNbNTGi', 'Math': '1VDUIJn4xGIGZ8TYluSHNG6k3GMXEGJm_', 'English': '1D0Ps6mw5qY21jRuGVm5a_s1UZJwvPK8', 'Communication Circuit Technology': '1ZyeUwHOoxAw2DisIFc5pGFJJ57Gy49hv', 'Chinese': '14tYcv7b3zfvohazvVDElaJrcJafldeg4' };
  final Map<String, String> authorizedSemester1Subjects = const { 'علم جودة': '1-ESboU85nTtO2FYMbiZZeNn3Anv6aH0', 'تدريب تقني كهرباء': '1psr8ylukgFsqhW9v1CZkLpWaPaE-8MnL', 'physics': '11LAt7VWyJB_NJtR-Q6u6btUfNY6uEpEx', 'math': '11ag3IGjyezZouQO1tOyhaCeEbQLGND2t', 'English': '11Kn1lg8qTyFFBa4ZQStnQYzzdLeAJYjl', 'circuit': '11ZIekUHxVXriF1w2lC5dYSf3u8yCmeIt', 'chinese': '12v8ywEq9-RMVhOvORwc3DGpkswRsBlLb', 'it': '11cD7TV1sHuaK1QRYRrU8UB62Zye_i3mQ' };
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final bool isFirstGradeCommCurrentYear = academicContext.grade == s.firstGrade && academicContext.department == s.communication && academicContext.year == s.currentYear;
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings'), tooltip: s.settings)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Map<String, String> subjectsToPass = isFirstGradeCommCurrentYear ? authorizedSemester1Subjects : {};
                Navigator.pushNamed(context, '/subjects', arguments: {'subjects': subjectsToPass, 'context': academicContext.copyWith(semester: s.semester1)});
              },
              child: Text(s.semester1),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Map<String, String> subjectsToPass = isFirstGradeCommCurrentYear ? authorizedSemester2Subjects : {};
                Navigator.pushNamed(context, '/subjects', arguments: {'subjects': subjectsToPass, 'context': academicContext.copyWith(semester: s.semester2)});
              },
              child: Text(s.semester2),
            ),
            const Spacer(),
            Align(alignment: Alignment.bottomRight, child: Text('V 0.1.3', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}

// 6. SubjectSelectionScreen
class SubjectSelectionScreen extends StatelessWidget {
  final Map<String, String> subjects;
  final AcademicContext academicContext;
  const SubjectSelectionScreen({super.key, required this.subjects, required this.academicContext});
  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> subjectsList = subjects.entries.toList();
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.pushNamed(context, '/settings'), tooltip: s.settings)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (subjectsList.isEmpty) Expanded(child: Center(child: Text(s.notAvailableNow, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, color: Theme.of(context).textTheme.bodySmall?.color))))
            else Expanded(
              child: ListView.separated(
                itemCount: subjectsList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final subjectName = subjectsList[index].key;
                  final rootFolderId = subjectsList[index].value;
                  return ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/subjectContentScreen', arguments: {'subjectName': subjectName, 'rootFolderId': rootFolderId, 'academicContext': academicContext.copyWith(subjectName: subjectName)}), child: Text(subjectName));
                },
              ),
            ),
            Align(alignment: Alignment.bottomRight, child: Text('V 0.1.3', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}

// 7. SubjectContentScreen
class SubjectContentScreen extends StatelessWidget {
  final String subjectName;
  final String rootFolderId;
  final AcademicContext academicContext;
  const SubjectContentScreen({super.key, required this.subjectName, required this.rootFolderId, required this.academicContext});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                onPressed: () {
                  // Navigate to the LectureFolderBrowserScreen with the rootFolderId
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LectureFolderBrowserScreen(
                        initialFolderId: rootFolderId,
                      ),
                    ),
                  );
                },
                child: Text(s.lectures)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => showAppSnackBar(context, s.explanationContentNotAvailable(subjectName), icon: Icons.info_outline), child: Text(s.explanation)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () => showAppSnackBar(context, s.summariesContentNotAvailable(subjectName), icon: Icons.info_outline), child: Text(s.summaries)),
          ],
        ),
      ),
    );
  }
}


// 8. PDF Viewer Screen
class PdfViewerScreen extends StatefulWidget {
  final String? fileUrl;
  final String fileId;
  final String? fileName;

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileId,
    this.fileName,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoadingFromServer = false;
  bool _isCheckingCache = true;
  double _downloadProgress = 0.0;
  String? _localFilePath;
  String? _loadingError;
  CancelToken _cancelToken = CancelToken();


  @override
  void initState() {
    super.initState();
    developer.log("PdfViewerScreen initState: fileId='${widget.fileId}', fileUrl='${widget.fileUrl}'", name: 'PdfViewerScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted) {
        _checkAndLoadPdf();
      }
    });
  }

  @override
  void dispose() {
    developer.log("PdfViewerScreen dispose: Cancelling download if active for ${widget.fileId}", name: 'PdfViewerScreen');
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel("PDF viewer disposed for ${widget.fileId}");
    }
    super.dispose();
  }


  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String fileId) async {
    final path = await _localPath;
    final filename = 'pdf_cache_$fileId.pdf';
    return File('$path/$filename');
  }

  Future<void> _checkAndLoadPdf() async {
    if (!mounted) {
      developer.log("_checkAndLoadPdf (${widget.fileId}): Unmounted, exiting.", name: 'PdfViewerScreen');
      return;
    }
    _cancelToken = CancelToken();
    developer.log("_checkAndLoadPdf (${widget.fileId}): Starting.", name: 'PdfViewerScreen');

    if(!_isLoadingFromServer && mounted){
      setState(() {
        _isCheckingCache = true;
        _loadingError = null;
        _localFilePath = null;
      });
    }

    final s = AppLocalizations.of(context);
    if (s == null) {
      developer.log("_checkAndLoadPdf (${widget.fileId}): Localizations not available yet.", name: 'PdfViewerScreen');
      if (mounted) {
        setState(() {
          _loadingError = "Error: Localizations not ready.";
          _isCheckingCache = false;
        });
      }
      return;
    }

    if (widget.fileUrl == null || widget.fileUrl!.isEmpty || widget.fileId.isEmpty) {
      developer.log("_checkAndLoadPdf (${widget.fileId}): Missing fileUrl or fileId.", name: 'PdfViewerScreen');
      if (mounted) {
        setState(() {
          _loadingError = s.errorNoUrlProvided;
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
      return;
    }

    final localFile = await _getLocalFile(widget.fileId);

    try {
      if (await localFile.exists()) {
        developer.log("_checkAndLoadPdf (${widget.fileId}): File found in cache at ${localFile.path}", name: 'PdfViewerScreen');
        if (mounted) {
          setState(() {
            _localFilePath = localFile.path;
            _isCheckingCache = false;
            _isLoadingFromServer = false;
            _loadingError = null;
          });
        }
      } else {
        developer.log("_checkAndLoadPdf (${widget.fileId}): File not in cache. Preparing to download.", name: 'PdfViewerScreen');
        if (mounted) {
          setState(() {
            _isCheckingCache = false;
            _isLoadingFromServer = true;
            _downloadProgress = 0.0;
            _loadingError = null;
          });
        }
        await _downloadPdf(localFile, s);
      }
    } catch (e) {
      developer.log("_checkAndLoadPdf (${widget.fileId}): Error during cache check or initiating download: $e", name: 'PdfViewerScreen');
      if (mounted) {
        setState(() {
          _loadingError = s.failedToLoadPdf(e.toString());
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
    }
  }

  Future<void> _downloadPdf(File localFile, AppLocalizations s) async {
    if (!mounted) {
      developer.log("_downloadPdf (${widget.fileId}): Unmounted, exiting.", name: 'PdfViewerScreen');
      return;
    }
    developer.log("_downloadPdf (${widget.fileId}): Starting Dio download from ${widget.fileUrl} to ${localFile.path}", name: 'PdfViewerScreen');

    final dio = Dio();
    try {
      await dio.download(
        widget.fileUrl!,
        localFile.path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            final progress = received / total;
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );
      developer.log("_downloadPdf (${widget.fileId}): Download complete.", name: 'PdfViewerScreen');
      if (mounted) {
        setState(() {
          _localFilePath = localFile.path;
          _isLoadingFromServer = false;
          _loadingError = null;
        });
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        developer.log('_downloadPdf (${widget.fileId}): Download cancelled: ${e.message}', name: 'PdfViewerScreen');
        if (mounted) {
          setState(() {
            _isLoadingFromServer = false;
            if (_loadingError == null && _localFilePath == null) {
              _loadingError = s.errorDownloadCancelled;
            }
          });
        }
      } else {
        developer.log('_downloadPdf (${widget.fileId}): Download error: $e', name: 'PdfViewerScreen');
        if (mounted) {
          if (await localFile.exists()) {
            try {
              await localFile.delete();
              developer.log("_downloadPdf (${widget.fileId}): Error deleting partial file: $e", name: 'PdfViewerScreen');
            } catch (delErr) {
              developer.log("_downloadPdf (${widget.fileId}): Error deleting partial file during exception handling: $delErr", name: 'PdfViewerScreen');
            }
          }
          setState(() {
            _loadingError = s.failedToLoadPdf(e.toString());
            _isLoadingFromServer = false;
          });
        }
      }
    }
  }

  Future<void> _deleteAndRetry() async {
    if (!mounted) {
      developer.log("_deleteAndRetry (${widget.fileId}): Unmounted.", name: 'PdfViewerScreen');
      return;
    }
    developer.log("_deleteAndRetry (${widget.fileId}): Initiated.", name: 'PdfViewerScreen');

    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel("Retrying download for ${widget.fileId}");
    }

    final s = AppLocalizations.of(context);
    if (s == null) {
      developer.log("_deleteAndRetry (${widget.fileId}): Localizations null, cannot proceed.", name: 'PdfViewerScreen');
      if (mounted) {
        setState(() {
          _loadingError = "Localization error during retry.";
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
      return;
    }

    if (widget.fileId.isNotEmpty) {
      final localFile = await _getLocalFile(widget.fileId);
      if (await localFile.exists()) {
        try {
          await localFile.delete();
          developer.log("_deleteAndRetry (${widget.fileId}): Deleted cached PDF: ${localFile.path}", name: 'PdfViewerScreen');
        } catch (e) {
          developer.log("_deleteAndRetry (${widget.fileId}): Error deleting cached PDF: $e", name: 'PdfViewerScreen');
        }
      }
      if (mounted) {
        setState(() {
          _isCheckingCache = true;
          _localFilePath = null;
          _loadingError = null;
          _isLoadingFromServer = false;
          _downloadProgress = 0.0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAndLoadPdf();
          }
        });
      }
    } else {
      developer.log("_deleteAndRetry (${widget.fileId}): fileId is empty, cannot retry.", name: 'PdfViewerScreen');
      if (mounted) {
        setState(() {
          _loadingError = s.errorFileIdMissing;
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final String appBarTitle = widget.fileName ?? s?.lectureContent ?? "PDF Viewer";

    if (s == null && _isCheckingCache) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: Center(child: Text(AppLocalizations.of(context)?.loadingLocalizations ?? "Loading localizations...")),
      );
    }

    if (_isCheckingCache) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadingError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height:10),
                Text(_loadingError!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (s!= null && _loadingError != s.errorNoUrlProvided && _loadingError != s.errorDownloadCancelled)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    onPressed: _deleteAndRetry,
                    label: Text(s.retry),
                  )
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingFromServer) {
      final String downloadingText = s?.downloading ?? "Downloading";
      final String statusText = _downloadProgress > 0.001
          ? "$downloadingText (${(_downloadProgress * 100).toStringAsFixed(0)}%)"
          : "$downloadingText...";

      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(value: _downloadProgress > 0.001 ? _downloadProgress : null),
                const SizedBox(height: 20),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_localFilePath != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
        ),
        body: SfPdfViewer.file(
          File(_localFilePath!),
          key: _pdfViewerKey,
          onDocumentLoadFailed: (details) {
            developer.log('Local PDF load failed for $_localFilePath (${widget.fileId}): ${details.description}', name: 'PdfViewerScreen');
            if (mounted && s != null) {
              _deleteAndRetry();
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Center(child: Text(s?.notAvailableNow ?? "Content not available.")),
    );
  }
}


// 9. Google Drive Viewer Screen (Unchanged from previous provided code)
class GoogleDriveViewerScreen extends StatefulWidget {
  final String? embedUrl;
  const GoogleDriveViewerScreen({super.key, this.embedUrl});
  @override
  State<GoogleDriveViewerScreen> createState() => _GoogleDriveViewerScreenState();
}
class _GoogleDriveViewerScreenState extends State<GoogleDriveViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true, mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{});
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) { if (mounted) setState(() => _isLoading = true); },
          onPageFinished: (String url) { if (mounted) setState(() => _isLoading = false); },
          onWebResourceError: (WebResourceError error) {
            developer.log('Page resource error in WebView: URL: ${error.url}, code: ${error.errorCode}, description: ${error.description}', name: 'GoogleDriveViewer');
            if (mounted) {
              final s = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s?.errorLoadingContent(error.description) ?? "Error loading content: ${error.description}")));
            }
          },
          onNavigationRequest: (NavigationRequest request) => NavigationDecision.navigate,
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setTextZoom(100);
    }
    _controller = controller;
    if (widget.embedUrl != null && widget.embedUrl!.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.embedUrl!));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final s = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s?.errorNoUrlProvided ?? "Error: No URL provided")));
          setState(() => _isLoading = false);
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final String appBarTitle = s?.lectureContent ?? "Content Viewer";
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Stack(
        children: [
          if (widget.embedUrl != null && widget.embedUrl!.isNotEmpty) WebViewWidget(controller: _controller)
          else if (!_isLoading && s != null) Center(child: Text(s.errorNoUrlProvided)),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// 10. Lecture Folder Browser Screen (MODIFIED FOR SELECTION, DOWNLOAD, DETAILS)
class LectureFolderBrowserScreen extends StatefulWidget {
  final String? initialFolderId;

  const LectureFolderBrowserScreen({super.key, this.initialFolderId});

  @override
  State<LectureFolderBrowserScreen> createState() => _LectureFolderBrowserScreenState();
}

class _LectureFolderBrowserScreenState extends State<LectureFolderBrowserScreen> {
  List<drive.File>? _files;
  bool _isLoading = true;
  String? _error;
  String? _currentFolderId;
  AppLocalizations? s;

  bool _isSelectionMode = false;
  final Set<drive.File> _selectedFiles = <drive.File>{}; // Store full File objects for details

  Map<String, double> _downloadProgressMap = {}; // fileId -> progress (0.0 to 1.0)
  Map<String, CancelToken> _cancelTokens = {};   // fileId -> CancelToken
  bool _isDownloadingMultiple = false;


  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.initialFolderId;
  }

  @override
  void dispose() {
    // Cancel all ongoing downloads when the screen is disposed
    _cancelTokens.forEach((fileId, token) {
      if (!token.isCancelled) {
        token.cancel("Folder browser disposed");
      }
    });
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    s = AppLocalizations.of(context);
    if (s == null) {
      developer.log("Localizations not ready in LectureFolderBrowserScreen.didChangeDependencies", name: 'LectureFolderBrowser');
    }

    final signInProvider = Provider.of<SignInProvider>(context, listen: false);

    // Only fetch files if not already loading, no error, and user is signed in.
    // Or if there was a sign-in error that might now be resolved.
    if (signInProvider.currentUser != null &&
        (_files == null && _error == null || (_error != null && _error == s!.notSignedInClientNotAvailable))) {
      _fetchDriveFiles();
    } else if (signInProvider.currentUser == null && mounted && s != null) {
      // If user is not signed in, set error and stop loading.
      if(_isLoading) { // Only update state if currently loading
        setState(() {
          _error = s!.notSignedInClientNotAvailable;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    final signInProvider = Provider.of<SignInProvider>(context, listen: false);
    if(mounted){
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    await signInProvider.signIn();
    if (signInProvider.currentUser != null && mounted) {
      _fetchDriveFiles();
    } else if (signInProvider.currentUser == null && mounted && s != null) {
      setState(() {
        _error = s!.notSignedInClientNotAvailable;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDriveFiles() async {
    if (!mounted) return;

    if (s == null) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)?.error ?? "Localization service not available.";
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isSelectionMode = false; // Reset selection on refresh/navigation
      _selectedFiles.clear();
    });

    final signInProvider = Provider.of<SignInProvider>(context, listen: false);
    final http.Client? authenticatedClient =
    await signInProvider.authenticatedHttpClient;

    if (authenticatedClient == null) {
      if(mounted){
        setState(() {
          _error = s!.notSignedInClientNotAvailable;
          _isLoading = false;
        });
      }
      return;
    }

    if (_currentFolderId == null) {
      if(mounted){
        setState(() {
          _error = s!.errorMissingFolderId;
          _isLoading = false;
        });
      }
      return;
    }

    final driveApi = drive.DriveApi(authenticatedClient);

    try {
      final result = await driveApi.files.list(
        q: "'$_currentFolderId' in parents and trashed = false",
        $fields: 'files(id, name, mimeType, webViewLink, iconLink, size, modifiedTime, webContentLink)', // Added webContentLink for direct download
        orderBy: 'folder,name',
      );

      if(mounted){
        setState(() {
          _files = result.files;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if(mounted){
        setState(() {
          _error = s!.failedToLoadFiles(e.toString());
          _isLoading = false;
        });
      }
      developer.log('Error fetching Drive files: $e', name: 'LectureFolderBrowser');
    }
  }

  bool _isFolder(drive.File file) {
    return file.mimeType == 'application/vnd.google-apps.folder';
  }

  void _toggleSelection(drive.File file) {
    if (!mounted) return;
    setState(() {
      if (_selectedFiles.any((selectedFile) => selectedFile.id == file.id)) {
        _selectedFiles.removeWhere((selectedFile) => selectedFile.id == file.id);
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFiles.add(file);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelectionMode() {
    if (!mounted) return;
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });
  }

  void _onItemTap(drive.File file) {
    if (!mounted || s == null) return;
    if (_isSelectionMode) {
      _toggleSelection(file);
    } else {
      if (_isFolder(file)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LectureFolderBrowserScreen(
              initialFolderId: file.id!,
            ),
          ),
        );
      } else {
        if (file.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s!.errorFileIdMissing)),
          );
          return;
        }

        if (file.mimeType == 'application/pdf') {
          final String directPdfUrl = 'https://drive.google.com/uc?export=download&id=${file.id!}';
          Navigator.pushNamed(
            context,
            '/pdfViewer',
            arguments: {
              'fileUrl': directPdfUrl,
              'fileId': file.id!,
              'fileName': file.name,
            },
          );
        } else if (file.webViewLink != null) {
          Navigator.pushNamed(
            context,
            '/googleDriveViewer',
            arguments: file.webViewLink,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s!.cannotOpenFileType)),
          );
        }
      }
    }
  }

  void _onItemLongPress(drive.File file) {
    if (!mounted) return;
    if (file.id != null) { // Only allow selection of items with IDs
      setState(() {
        _isSelectionMode = true;
        _toggleSelection(file);
      });
    }
  }

  Future<void> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    if (!status.isGranted) {
      // For Android 11+ if writing to shared storage, MANAGE_EXTERNAL_STORAGE might be needed
      // but it's a sensitive permission. Using file_picker for directory selection is preferred.
      if (Platform.isAndroid) {
        var manageStatus = await Permission.manageExternalStorage.status;
        if(!manageStatus.isGranted){
          manageStatus = await Permission.manageExternalStorage.request();
        }
        if (!manageStatus.isGranted && mounted) {
          showAppSnackBar(context, s!.permissionDenied);
        }
      } else if (mounted) {
        showAppSnackBar(context, s!.permissionDenied);
      }
    }
  }


  Future<void> _downloadSelectedFiles() async {
    if (!mounted || s == null || _selectedFiles.isEmpty) return;

    // Request permissions (still good practice)
    await _requestStoragePermission();

    final downloadPathProvider = Provider.of<DownloadPathProvider>(context, listen: false);

    // Always get the app-specific path as the target for Dio.
    String effectiveDownloadPath = await downloadPathProvider.getEffectiveDownloadPath(); // Guaranteed non-nullable String

    // Ensure the app-specific download directory exists
    final targetDirectory = Directory(effectiveDownloadPath);
    if (!await targetDirectory.exists()) {
      try {
        await targetDirectory.create(recursive: true);
        developer.log("Created app-specific download directory: $effectiveDownloadPath", name: "DownloadFiles");
      } catch (e) {
        developer.log("Failed to create app-specific directory $effectiveDownloadPath: $e", name: "DownloadFiles");
        if(mounted) {
          showAppSnackBar(context, s!.failedToCreateDirectory(e.toString()));
        }
        return;
      }
    }

    setState(() {
      _isDownloadingMultiple = true;
    });

    showAppSnackBar(context, s!.downloadStarted(_selectedFiles.length));

    int successCount = 0;
    final dio = Dio();

    for (var fileToDownload in _selectedFiles) {
      if (fileToDownload.id == null || _isFolder(fileToDownload)) continue;

      final fileName = fileToDownload.name ?? 'downloaded_file';
      final filePath = '$effectiveDownloadPath/$fileName';
      final fileId = fileToDownload.id!;

      final String downloadUrl = fileToDownload.webContentLink ?? 'https://drive.google.com/uc?export=download&id=${fileToDownload.id!}';

      final cancelToken = CancelToken();
      _cancelTokens[fileId] = cancelToken;

      try {
        if (mounted) {
          setState(() { _downloadProgressMap[fileId] = 0.0; });
        }

        developer.log("Starting download for ${fileToDownload.name} to $filePath (app-specific) from $downloadUrl", name: "DownloadFiles");

        await dio.download(
          downloadUrl,
          filePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1 && mounted) {
              setState(() {
                _downloadProgressMap[fileId] = received / total;
              });
            }
          },
          options: Options(headers: await Provider.of<SignInProvider>(context, listen: false).currentUser?.authHeaders),
        );

        if (mounted) {
          setState(() { _downloadProgressMap[fileId] = 1.0; });
          showAppSnackBar(
            context,
            s!.downloadCompleted(fileName),
            action: SnackBarAction(label: s!.openFile, onPressed: () => OpenFilex.open(filePath)),
          );
        }
        successCount++;

      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          developer.log("Download cancelled for $fileName", name: "DownloadFiles");
          if (mounted) showAppSnackBar(context, s!.downloadCancelled(fileName));
        } else {
          developer.log("Dio download failed for $fileName (app-specific): $e", name: "DownloadFiles");
          if (mounted) showAppSnackBar(context, s!.downloadFailed(fileName, e.message ?? e.toString()));
        }
        if (mounted) setState(() { _downloadProgressMap.remove(fileId); });

      } catch (e) {
        developer.log("Generic download error for $fileName (app-specific): $e", name: "DownloadFiles");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s!.downloadFailed(fileName, e.toString()))));
          setState(() { _downloadProgressMap.remove(fileId); });
        }
      } finally {
        _cancelTokens.remove(fileId);
      }
    }

    if(mounted){
      setState(() {
        _isDownloadingMultiple = false;
        _cancelSelectionMode();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s!.allDownloadsCompleted),
          action: successCount > 0 ? SnackBarAction(label: s!.openFolder, onPressed: () async {
            if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
              try {
                await OpenFilex.open(effectiveDownloadPath);
              } catch (e) {
                developer.log("Could not open download folder: $e", name: "DownloadFiles");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s!.couldNotOpenFolder(e.toString()))));
              }
            }
          }) : null,
        ),
      );
    }
  }

  void _viewSelectedFileDetails() {
    if (!mounted || s == null) return;

    if (_selectedFiles.length == 1) {
      final file = _selectedFiles.first;
      showDialog(
        context: context,
        builder: (context) => FileDetailsDialog(file: file, s: s!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s!.noItemSelectedForDetails)),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final signInProvider = Provider.of<SignInProvider>(context);
    final user = signInProvider.currentUser;

    if (s == null) {
      return Scaffold(
          appBar: AppBar(title: Text(AppLocalizations.of(context)?.lectures ?? "Lectures")),
          body: Center(child: Text(AppLocalizations.of(context)?.loadingLocalizations ?? "Loading localizations..."))
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Set Scaffold background back to solid background color
      body: Column( // Removed Container with gradient
        children: [
          AppBar( // AppBar remains at the top
            title: Text(s!.lectures),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_isDownloadingMultiple) {
                  showAppSnackBar(context, s!.downloadInProgressPleaseWait);
                  return;
                }
                Navigator.pop(context);
              },
            ),
            actions: [
              // Show selection mode actions if active
              if (_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _selectedFiles.isNotEmpty && !_isDownloadingMultiple
                      ? _downloadSelectedFiles
                      : null,
                  tooltip: s!.downloadSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _selectedFiles.length == 1 && !_isDownloadingMultiple
                      ? _viewSelectedFileDetails
                      : null,
                  tooltip: s!.viewDetails,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: _isDownloadingMultiple ? null : _cancelSelectionMode,
                  tooltip: s!.cancelSelection,
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isDownloadingMultiple ? null : (user != null ? _fetchDriveFiles : _handleSignIn),
                  tooltip: s!.refresh,
                ),
                if (user != null)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _isDownloadingMultiple ? null : signInProvider.signOut,
                    tooltip: s!.signOut,
                  )
                else
                  TextButton(
                    onPressed: _handleSignIn,
                    style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16.0)),
                    child: Text(s!.signIn, style: const TextStyle(fontSize: 16)),
                  ),
              ],
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (user == null) // Show sign-in button if not signed in
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        onPressed: _handleSignIn,
                        label: Text(s!.signInWithGoogle),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchDriveFiles, // Retry button even if not signed in (might help after sign-in)
                      label: Text(s!.retry),
                    ),
                  ],
                ),
              ),
            ) // Keep your existing error display
                : _files == null || _files!.isEmpty
                ? _buildEmptyState(Icons.folder_open_outlined, s!.noFilesIllustrationText) // Empty state
                : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _files!.length,
              itemBuilder: (context, index) {
                final file = _files![index];
                final bool isSelected = _selectedFiles.any((sf) => sf.id == file.id);
                final double? progress = _downloadProgressMap[file.id];

                return Card(
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
                  margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Stack( // Use Stack for progress overlay
                    children: [
                      ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (file.id != null) _toggleSelection(file);
                          },
                        )
                            : Icon(
                          _isFolder(file)
                              ? Icons.folder_open_outlined
                              : _getIconForMimeType(file.mimeType),
                          color: _isFolder(file)
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          size: 28,
                        ),
                        title: Text(
                          file.name ?? s!.unnamedItem,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w500),
                        ),
                        subtitle: (progress != null && progress > 0 && progress < 1)
                            ? Text("${s!.downloading} (${(progress * 100).toStringAsFixed(0)}%)")
                            : null,
                        trailing: !_isSelectionMode && !_isFolder(file)
                            ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
                            : null,
                        onTap: () => _onItemTap(file),
                        onLongPress: () => _onItemLongPress(file),
                      ),
                      if (progress != null && progress > 0 && progress < 1)
                        Positioned.fill(
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor.withOpacity(0.3)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForMimeType(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    if (mimeType.startsWith('image/')) return Icons.image_outlined;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) return Icons.slideshow_outlined;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel')) return Icons.table_chart_outlined;
    if (mimeType.contains('document') || mimeType.contains('word')) return Icons.article_outlined;
    if (mimeType.startsWith('video/')) return Icons.video_library_outlined;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack_outlined;
    return Icons.insert_drive_file_outlined;
  }

  // Moved _buildEmptyState into _LectureFolderBrowserScreenState
  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// --- File Details Dialog ---
class FileDetailsDialog extends StatelessWidget {
  final drive.File file;
  final AppLocalizations s;

  const FileDetailsDialog({super.key, required this.file, required this.s});

  @override
  Widget build(BuildContext context) {
    String formattedDate = s.notAvailableNow; // Default
    if (file.modifiedTime != null) {
      try {
        // Ensure locale is available for DateFormat
        final currentLocale = Localizations.localeOf(context).toString();
        formattedDate = DateFormat.yMMMd(currentLocale).add_jm().format(file.modifiedTime!.toLocal());
      } catch (e) {
        developer.log("Error formatting date: $e", name: "FileDetailsDialog");
        formattedDate = file.modifiedTime!.toLocal().toString().substring(0,16); // Fallback
      }
    }

    String fileSize = file.size != null
        ? formatBytesSimplified(int.tryParse(file.size!) ?? 0, 2, s)
        : s.notAvailableNow;

    return AlertDialog(
      title: Text(s.fileDetails),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            _buildDetailRow(s.fileNameField, file.name ?? s.unnamedItem),
            _buildDetailRow(s.fileTypeField, file.mimeType ?? s.notAvailableNow),
            _buildDetailRow(s.fileSizeField, fileSize),
            _buildDetailRow(s.lastModifiedField, formattedDate),
            // You can add more details here if needed
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(s.ok), // Add "ok" key: "OK"
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}


// 11. Settings Screen (MODIFIED FOR DOWNLOAD PATH & CLEAR CACHE)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearInternalPdfCache(BuildContext context, AppLocalizations s) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      int count = 0;
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        for (FileSystemEntity entity in entities) {
          // Make sure filename check is robust
          if (entity is File && entity.path.endsWith('.pdf') && entity.path.split('/').last.startsWith('pdf_cache_')) {
            await entity.delete();
            count++;
            developer.log("Deleted cached PDF: ${entity.path}", name: "SettingsScreen");
          }
        }
      }
      if (context.mounted) {
        showAppSnackBar(context, s.cacheClearedItems(count), icon: Icons.check_circle_outline, iconColor: Colors.green);
      }
    } catch (e) {
      developer.log("Error clearing cache: $e", name: "SettingsScreen");
      if (context.mounted) {
        showAppSnackBar(context, s.cacheClearFailed(e.toString()), icon: Icons.error_outline, iconColor: Colors.red);
      }
    }
  }

  // Modified function to open app-specific download path directly
  Future<void> _openAppDownloadPath(BuildContext context, AppLocalizations s, DownloadPathProvider pathProvider) async {
    final String currentDownloadPath = await pathProvider.getEffectiveDownloadPath();
    try {
      final result = await OpenFilex.open(currentDownloadPath);
      if (result.type != ResultType.done) {
        developer.log("Failed to open folder: ${result.message}", name: "SettingsScreen");
        if (context.mounted) {
          showAppSnackBar(context, s.couldNotOpenFolder(result.message ?? 'Unknown error'), icon: Icons.folder_off_outlined, iconColor: Colors.red);
        }
      }
    } catch (e) {
      developer.log("Could not open download folder: $e", name: "SettingsScreen");
      if (context.mounted) {
        showAppSnackBar(context, s.couldNotOpenFolder(e.toString()), icon: Icons.folder_off_outlined, iconColor: Colors.red);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final signInProvider = Provider.of<SignInProvider>(context);
    final user = signInProvider.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final downloadPathProvider = Provider.of<DownloadPathProvider>(context);
    final s = AppLocalizations.of(context);
    if (s == null) {
      return Scaffold(appBar: AppBar(title: const Text("Settings")), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            if (user != null) ...[
              Center(
                child: CircleAvatar(
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  radius: 40,
                  child: user.photoUrl == null
                      ? Text(
                    user.displayName?.isNotEmpty == true
                        ? user.displayName![0].toUpperCase()
                        : (user.email.isNotEmpty == true ? user.email[0].toUpperCase() : '?'),
                    style: const TextStyle(fontSize: 30),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  user.displayName ?? user.email ?? s.unknownUser,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 30),
            // CORRECTED ElevatedButton
            ElevatedButton(
              onPressed: user == null ? signInProvider.signIn : signInProvider.signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: user == null ? Theme.of(context).primaryColor : Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              child: Text(user == null ? s.signInWithGoogle : s.signOut),
            ),
            const SizedBox(height: 20),

            // CORRECTED _buildSettingsItem calls
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.info_outline,
              text: s.aboutCollege,
              onTap: () {
                Navigator.pushNamed(context, '/collegeInfo');
              },
            ),
            _buildSettingsItem(
                context,
                s: s,
                icon: Icons.language,
                text: s.chooseLanguage,
                trailing: Text(
                    languageProvider.locale.languageCode == 'en' ? s.english : s.arabic,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                ),
                onTap: () {
                  showDialog(context: context, builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(s.chooseLanguage),
                      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        RadioListTile<Locale>(title: Text(s.english), value: const Locale('en'), groupValue: languageProvider.locale, onChanged: (Locale? value) { if (value != null) { languageProvider.setLocale(value); Navigator.of(dialogContext).pop(); } }),
                        RadioListTile<Locale>(title: Text(s.arabic), value: const Locale('ar'), groupValue: languageProvider.locale, onChanged: (Locale? value) { if (value != null) { languageProvider.setLocale(value); Navigator.of(dialogContext).pop(); } }),
                      ],
                      ),
                    );
                  },
                  );
                }
            ),
            _buildSettingsItem(
                context,
                s: s,
                icon: Icons.brightness_6_outlined,
                text: s.chooseTheme,
                trailing: Text(
                    themeProvider.themeMode == ThemeMode.light ? s.lightTheme :
                    themeProvider.themeMode == ThemeMode.dark ? s.darkTheme :
                    s.systemDefault,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                ),
                onTap: () {
                  showDialog(context: context, builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(s.chooseTheme),
                      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        RadioListTile<ThemeMode>(title: Text(s.lightTheme), value: ThemeMode.light, groupValue: themeProvider.themeMode, onChanged: (ThemeMode? value) { if (value != null) { themeProvider.setThemeMode(value); Navigator.of(dialogContext).pop(); } }),
                        RadioListTile<ThemeMode>(title: Text(s.darkTheme), value: ThemeMode.dark, groupValue: themeProvider.themeMode, onChanged: (ThemeMode? value) { if (value != null) { themeProvider.setThemeMode(value); Navigator.of(dialogContext).pop(); } }),
                        RadioListTile<ThemeMode>(title: Text(s.systemDefault), value: ThemeMode.system, groupValue: themeProvider.themeMode, onChanged: (ThemeMode? value) { if (value != null) { themeProvider.setThemeMode(value); Navigator.of(dialogContext).pop(); } }),
                      ],
                      ),
                    );
                  },
                  );
                }
            ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.folder_open_outlined,
              text: s.downloadLocation, // Changed text to reflect info, not selection
              trailing: FutureBuilder<String>(
                  future: downloadPathProvider.getEffectiveDownloadPath(),
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.isNotEmpty){
                      String path = snapshot.data!;
                      if(path.length > 30) path = "...${path.substring(path.length - 27)}"; // Truncate for display
                      return Text(path, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12), overflow: TextOverflow.ellipsis);
                    }
                    return Text(s.notSet, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12));
                  }
              ),
              onTap: () {
                _openAppDownloadPath(context, s, downloadPathProvider); // Directly open path
              },
            ),
            // Removed "Clear Custom Download Path" option completely
            // _buildSettingsItem(
            //   context,
            //   s: s,
            //   icon: Icons.folder_delete_outlined, // New icon
            //   text: s.clearCustomDownloadPathOption, // New key
            //   onTap: () {
            //     _clearCustomDownloadPath(context, s, downloadPathProvider);
            //   },
            // ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.delete_sweep_outlined,
              text: s.clearPdfCache,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(s.confirmAction),
                      content: Text(s.confirmClearCache),
                      actions: <Widget>[
                        TextButton(
                          child: Text(s.cancel),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          child: Text(s.clear, style: const TextStyle(color: Colors.red)),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _clearInternalPdfCache(context, s);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.help_outline,
              text: s.about,
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
          ].map((item) => Padding(padding: const EdgeInsets.only(bottom: 0), child: item)).toList(),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required AppLocalizations s, required IconData icon, required String text, Widget? trailing, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(text, style: const TextStyle(fontSize: 16)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// 12. AboutScreen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  Future<void> _launchUrl(BuildContext context, String url) async {
    final s = AppLocalizations.of(context);
    if (s == null) return;
    try { if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) { if (context.mounted) showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red); }
    } catch (e) { if (context.mounted) showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red); }
  }
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    const String phoneNumber = '01027658156';
    const String emailAddress = 'belalmohamedelnemr0@gmail.com';
    const String appCurrentVersion = '0.1.3'; // Updated for Phase 2
    return Scaffold(
      appBar: AppBar(title: Text(s.about), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(Icons.code_outlined, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(s.appTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text('${s.appVersion}: $appCurrentVersion', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(s.appDescription, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall))
          ]),
          const Divider(height: 40, thickness: 1),
          Text(s.madeBy, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8.0), Text(s.developerName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)), Text(s.developerDetails, style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 40, thickness: 1),
          Text(s.contactInfo, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8.0),
          ListTile(
            leading: const Icon(Icons.phone_android_outlined),
            title: Text(s.phoneNumber),
            subtitle: const Text(phoneNumber),
            onTap: () => _launchUrl(context,'tel:$phoneNumber'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(s.email),
            subtitle: const Text(emailAddress),
            onTap: () => _launchUrl(context,'mailto:$emailAddress'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
          const Divider(height: 40, thickness: 1),
        ],
      ),
    );
  }
}

// 13. CollegeInfoScreen
class CollegeInfoScreen extends StatelessWidget {
  const CollegeInfoScreen({super.key});
  Future<void> _launchUrl(BuildContext context, String url) async {
    final s = AppLocalizations.of(context);
    if (s == null) return;
    try { if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) { if (context.mounted) showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red); }
    } catch (e) { if (context.mounted) showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red); }
  }
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    const String facebookUrl = 'https://www.facebook.com/2018ECCAT';
    const String googleMapsUrl = 'https://maps.app.goo.gl/MTtsxuok1c5gteMw8';
    return Scaffold(
      appBar: AppBar(title: Text(s.aboutCollege), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Hero(tag: 'collegeIcon', child: Icon(Icons.school_outlined, size: 80, color: Colors.indigo)),
            const SizedBox(height: 10),
            Text(s.collegeName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(s.eccatIntro, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium))
          ]),
          const Divider(height: 40, thickness: 1),
          Text(s.connectWithUs, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
          Card(child: ListTile(
            leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
            title: Text(s.facebookPage),
            trailing: const Icon(Icons.open_in_new_outlined, size: 20),
            onTap: () => _launchUrl(context, facebookUrl),
          )),
          const SizedBox(height:10),
          Card(child: ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Color(0xFFDB4437)),
            title: Text(s.collegeLocation),
            trailing: const Icon(Icons.open_in_new_outlined, size: 20),
            onTap: () => _launchUrl(context, googleMapsUrl),
          )),
          const Divider(height: 40, thickness: 1),
        ],
      ),
    );
  }
}

// TodoItem class for persistence and enhanced fields
class TodoItem {
  String title;
  bool isCompleted;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  bool isRepeating;
  String? repeatInterval;
  String? listName;
  DateTime creationDate; // New field for creation date

  TodoItem({
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    this.dueTime,
    this.isRepeating = false,
    this.repeatInterval,
    this.listName,
    DateTime? creationDate, // Make it optional in constructor
  }) : creationDate = creationDate ?? DateTime.now(); // Initialize if null

  Map<String, dynamic> toJson() => {
    'title': title,
    'isCompleted': isCompleted,
    'dueDate': dueDate?.toIso8601String(),
    'dueTimeHour': dueTime?.hour,
    'dueTimeMinute': dueTime?.minute,
    'isRepeating': isRepeating,
    'repeatInterval': repeatInterval,
    'listName': listName,
    'creationDate': creationDate.toIso8601String(), // Save creation date
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      dueTime: (json['dueTimeHour'] != null && json['dueTimeMinute'] != null)
          ? TimeOfDay(hour: json['dueTimeHour'] as int, minute: json['dueTimeMinute'] as int)
          : null,
      isRepeating: json['isRepeating'] as bool? ?? false,
      repeatInterval: json['repeatInterval'] as String?,
      listName: json['listName'] as String?,
      creationDate: json['creationDate'] != null ? DateTime.parse(json['creationDate'] as String) : DateTime(2000, 1, 1), // Default for old tasks to a very early date
    );
  }

  // Helper to check if a task is overdue based on current time
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (taskDate.isBefore(today)) {
      return true;
    }
    // If it's today, check time
    if (taskDate.isAtSameMomentAs(today) && dueTime != null) {
      final taskDateTime = DateTime(now.year, now.month, now.day, dueTime!.hour, dueTime!.minute);
      return taskDateTime.isBefore(now);
    }
    return false;
  }

  // Helper to check if a task is for today
  bool get isToday {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isAtSameMomentAs(today);
  }

  // Helper to check if a task is for tomorrow
  bool get isTomorrow {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isAtSameMomentAs(tomorrow);
  }

  // Helper to check if a task is for this week (excluding today/tomorrow)
  bool get isThisWeek {
    if (dueDate == null || isCompleted) return false;
    if (isToday || isTomorrow) return false; // Exclude today and tomorrow
    final now = DateTime.now();
    // Monday is the first day of the week (weekday 1). Dart's weekday starts with 1 (Monday).
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Check if taskDate is within the current week (inclusive of startOfWeek, exclusive of endOfWeek+1)
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1))) && taskDate.isBefore(endOfWeek.add(const Duration(days: 1)));
  }


  String formatDueDate(BuildContext context, AppLocalizations s) { // MODIFIED: Added BuildContext
    if (dueDate == null) return s.notSet; // Or a specific "No Date" key

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    String dateText;
    if (taskDate.isAtSameMomentAs(today)) {
      dateText = s.todayTasks;
    } else if (taskDate.isAtSameMomentAs(tomorrow)) {
      dateText = s.tomorrowTasks;
    } else if (isThisWeek) {
      // Use EEEE for full weekday name, for example: "Monday"
      dateText = DateFormat.EEEE(Localizations.localeOf(context).toLanguageTag()).format(dueDate!); // MODIFIED: Use context for locale
    } else {
      // Example: "Mar 3, 2021"
      dateText = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(dueDate!); // MODIFIED: Use context for locale
    }

    String timeText = '';
    if (dueTime != null) {
      final materialLocalizations = MaterialLocalizations.of(context); // MODIFIED: Use context for MaterialLocalizations
      timeText = materialLocalizations.formatTimeOfDay(dueTime!, alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat); // MODIFIED: Use context for MediaQuery
    }

    if (timeText.isNotEmpty) {
      return '$dateText, $timeText';
    }
    return dateText;
  }
}

// TodoListScreen
class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _taskController = TextEditingController();
  List<TodoItem> _todos = [];
  bool _isLoading = true;
  bool _isSearching = false; // Declared _isSearching here

  String _currentList = 'INITIAL_PLACEHOLDER'; // Initialize with a non-localized placeholder
  String _searchQuery = ''; // FIX: Re-declared _searchQuery

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>(); // Key for AnimatedList

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppLocalizations.of(context);

    // Only attempt to set _currentList if localizations are available
    if (s != null) {
      // If _currentList is still the placeholder or if it holds a value
      // that no longer maps to a localized list (e.g., after language change),
      // reset it to the localized "All Lists"
      if (_currentList == 'INITIAL_PLACEHOLDER' || !_isLocalizedList(_currentList, s)) {
        _currentList = s.allListsTitle;
      }
      // Re-apply filters whenever dependencies change (including localization changes)
      _applyFilters();
    }
  }

  // Helper to check if a list name is one of the localized options
  bool _isLocalizedList(String listName, AppLocalizations s) {
    return listName == s.allListsTitle ||
        listName == s.personal ||
        listName == s.work ||
        listName == s.shopping ||
        listName == s.defaultList;
  }


  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosString = prefs.getString('todos');
      if (todosString != null) {
        final List<dynamic> todoListJson = jsonDecode(todosString);
        _todos = todoListJson.map((json) => TodoItem.fromJson(json)).toList();
      }
    } catch (e) {
      developer.log("TodoListScreen Error loading todos: $e", name: "TodoListScreen");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // After loading, ensure the displayed list is updated correctly
          _applyFilters();
        });
      }
    }
  }

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String todosString = jsonEncode(_todos.map((todo) => todo.toJson()).toList());
      await prefs.setString('todos', todosString);
    } catch (e) {
      developer.log("TodoListScreen Error saving todos: $e", name: "TodoListScreen");
    }
  }

  void _addTodo(AppLocalizations s) {
    final String newTaskTitle = _taskController.text.trim();
    if (newTaskTitle.isNotEmpty) {
      final newItem = TodoItem(
        title: newTaskTitle,
        listName: _currentList == s.allListsTitle ? null : (_currentList == s.defaultList ? s.defaultList : _currentList),
      );
      setState(() {
        _todos.add(newItem);
        _applyFilters(); // Re-apply filtering after adding
        // Check if the item is visible in the current filter before animating
        if (_getFilteredTodos().contains(newItem)) {
          _listKey.currentState?.insertItem(_getFilteredTodos().indexOf(newItem), duration: const Duration(milliseconds: 300));
        }
      });
      _taskController.clear();
      _saveTodos();
      HapticFeedback.lightImpact(); // Haptic feedback on add
      showAppSnackBar(context, s.taskAdded, icon: Icons.task_alt, iconColor: Colors.green);

      // Schedule notification for the new task
      _scheduleNotification(newItem, s);
    } else {
      showAppSnackBar(context, s.emptyTaskError, icon: Icons.warning_amber_outlined, iconColor: Colors.orange);
    }
  }

  void _toggleTodoCompletion(int index) {
    final s = AppLocalizations.of(context)!;
    final TodoItem itemToToggle = _getFilteredTodos()[index];
    final int originalIndex = _todos.indexWhere(
            (todo) => todo.title == itemToToggle.title && todo.creationDate == itemToToggle.creationDate
    );

    if (originalIndex != -1) {
      final bool oldCompletedStatus = _todos[originalIndex].isCompleted;
      setState(() {
        _todos[originalIndex].isCompleted = !_todos[originalIndex].isCompleted;
        // Re-calculate visible tasks and animate removal/addition
        _applyFilters();
      });
      _saveTodos();
      HapticFeedback.lightImpact(); // Haptic feedback on toggle
      if (_todos[originalIndex].isCompleted) {
        showAppSnackBar(context, s.taskCompleted, icon: Icons.check_circle_outline, iconColor: Colors.green);
        flutterLocalNotificationsPlugin.cancel(itemToToggle.hashCode); // Cancel notification
      } else {
        showAppSnackBar(context, s.taskReactivated, icon: Icons.refresh, iconColor: Colors.blue);
        _scheduleNotification(itemToToggle, s); // Reschedule notification
      }
    }
  }

  void _deleteTodo(int index) {
    final s = AppLocalizations.of(context)!;
    final TodoItem itemToDelete = _getFilteredTodos()[index];
    final int originalIndexInFullList = _todos.indexWhere((todo) => todo.title == itemToDelete.title && todo.creationDate == itemToDelete.creationDate);

    if (originalIndexInFullList != -1) {
      _listKey.currentState?.removeItem(
        index, // Index in the currently displayed (filtered) list
            (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: _buildTodoCard(context, itemToDelete, index, s), // The card being removed
        ),
        duration: const Duration(milliseconds: 300),
      );

      setState(() {
        _todos.removeAt(originalIndexInFullList); // Remove from the actual data list
        _applyFilters(); // Re-apply filters to update display indices
      });
      _saveTodos();
      HapticFeedback.lightImpact(); // Haptic feedback on delete
      showAppSnackBar(context, s.taskDeleted, icon: Icons.delete_outline, iconColor: Colors.red);
      flutterLocalNotificationsPlugin.cancel(itemToDelete.hashCode); // Cancel notification
    }
  }


  // Simplified to only filter
  List<TodoItem> _getFilteredTodos() {
    final s = AppLocalizations.of(context)!; // Get 's' here for defaultList
    List<TodoItem> filteredTodos = _todos.where((todo) {
      // Apply list filter
      if (_currentList != s.allListsTitle) {
        // If "Default List" is selected, show tasks with null listName or defaultList
        if (_currentList == s.defaultList) {
          if (todo.listName != null && todo.listName != s.defaultList) return false;
        } else {
          // For other specific lists, show tasks with matching listName
          if (todo.listName != _currentList) return false;
        }
      }

      // Apply search query
      if (_searchQuery.isNotEmpty && !todo.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    // Default sort by completionDate (incomplete first), then due date (ascending, nulls last), then creation date (ascending)
    filteredTodos.sort((a, b) {
      // Completed tasks always go to the end
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;

      // Then by due date (nulls last)
      if (a.dueDate == null && b.dueDate == null) {
        return a.creationDate.compareTo(b.creationDate); // Fallback to creation date if both due dates are null
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      int dueDateComparison = a.dueDate!.compareTo(b.dueDate!);
      if (dueDateComparison != 0) return dueDateComparison;

      // If due dates are same, sort by creation date
      return a.creationDate.compareTo(b.creationDate);
    });

    return filteredTodos;
  }

  void _applyFilters() { // Renamed from _applyFilterAndSort
    if(mounted) {
      setState(() {
        // The getter _getFilteredTodos() will be called in the builder
        // so we just need to trigger a rebuild.
      });
    }
  }


  Map<String, List<TodoItem>> _groupTodos(List<TodoItem> todos, AppLocalizations s) {
    final Map<String, List<TodoItem>> grouped = {
      s.overdueTasks: [],
      s.todayTasks: [],
      s.tomorrowTasks: [],
      s.thisWeekTasks: [],
      s.laterTasks: [], // New key for "Later"
      s.noDateTasks: [], // New key for "No Date"
    };

    for (var todo in todos) {
      if (todo.isCompleted) continue; // Don't group completed tasks

      if (todo.isOverdue) {
        grouped[s.overdueTasks]!.add(todo);
      } else if (todo.isToday) {
        grouped[s.todayTasks]!.add(todo);
      } else if (todo.isTomorrow) {
        grouped[s.tomorrowTasks]!.add(todo);
      } else if (todo.isThisWeek) {
        grouped[s.thisWeekTasks]!.add(todo);
      } else if (todo.dueDate == null) {
        grouped[s.noDateTasks]!.add(todo);
      } else {
        grouped[s.laterTasks]!.add(todo);
      }
    }

    // Remove empty groups for display
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  Future<void> _scheduleNotification(TodoItem task, AppLocalizations s) async {
    if (task.dueDate == null || task.dueTime == null || task.isCompleted) {
      flutterLocalNotificationsPlugin.cancel(task.hashCode); // Cancel if criteria not met
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

    // Ensure notification is in the future
    if (scheduleDateTime.isBefore(now)) {
      developer.log("Notification not scheduled: Task time is in the past.", name: "Notifications");
      return;
    }

    // Convert scheduleDateTime to a timezone-aware DateTime for `zonedSchedule`
    final tz.TZDateTime tzScheduleDateTime = tz.TZDateTime.from(
      scheduleDateTime,
      tz.local,
    );


    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'task_reminders_channel', // Channel ID
      'Task Reminders', // Channel name
      channelDescription: 'Reminders for your ECCAT Study Station tasks',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(); // Use const
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    DateTimeComponents? dateTimeComponents;
    if (task.isRepeating) {
      if (task.repeatInterval == s.daily) {
        dateTimeComponents = DateTimeComponents.time;
      } else if (task.repeatInterval == s.weekly) {
        dateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
      } else if (task.repeatInterval == s.monthly) {
        dateTimeComponents = DateTimeComponents.dayOfMonthAndTime;
      } else if (task.repeatInterval == s.everyXDays(2)) { // This one won't repeat with DateTimeComponents
        dateTimeComponents = null; // Default to one-time for complex repeats unless specified
      } else if (task.repeatInterval == s.weekdays) {
        dateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
      } else if (task.repeatInterval == s.weekends) {
        dateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
      }
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.hashCode, // Use task hash code as unique ID for the notification
      s.appTitle, // Notification title
      '${s.notificationReminderBody} ${task.title}', // Notification body (fixed string interpolation)
      tzScheduleDateTime, // Scheduled time
      notificationDetails, // Correctly pass notificationDetails
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Corrected: Add androidScheduleMode
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, // Required parameter
      matchDateTimeComponents: dateTimeComponents, // Set recurrence based on repeatInterval
      payload: 'task_id:${task.hashCode}', // Custom payload for handling taps
    );

    developer.log("Notification scheduled for task '${task.title}' at $scheduleDateTime. Repeat: ${task.repeatInterval}", name: "Notifications");
  }


  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final List<TodoItem> displayedTodos = _getFilteredTodos(); // Changed to _getFilteredTodos
    final Map<String, List<TodoItem>> groupedTodos = _groupTodos(displayedTodos, s);

    // Order of groups for display
    final List<String> groupDisplayOrder = [
      s.overdueTasks,
      s.todayTasks,
      s.tomorrowTasks,
      s.thisWeekTasks,
      s.laterTasks,
      s.noDateTasks,
    ];

    final List<String> activeGroups = groupDisplayOrder.where((key) => groupedTodos.containsKey(key)).toList();

    // Available lists for the dropdown (use localized strings)
    final List<String> availableLists = [
      s.allListsTitle,
      s.personal,
      s.work,
      s.shopping,
      s.defaultList,
    ];

    // Calculate today's task progress
    final DateTime today = DateTime.now();
    final List<TodoItem> todayTasks = _todos.where((todo) =>
    todo.dueDate != null &&
        todo.dueDate!.year == today.year &&
        todo.dueDate!.month == today.month &&
        todo.dueDate!.day == today.day
    ).toList();
    final int totalTodayTasks = todayTasks.length;
    final int completedTodayTasks = todayTasks.where((todo) => todo.isCompleted).length;
    final double todayProgress = totalTodayTasks > 0 ? completedTodayTasks / totalTodayTasks : 0.0;


    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background, // Set Scaffold background back to solid background color
      body: Column( // Removed Container with gradient
        children: [
          AppBar(
            title: _isSearching
                ? TextField(
              decoration: InputDecoration(
                hintText: s.searchTasksHint,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _isSearching = false;
                      _taskController.clear(); // Clear quick add task controller too
                      _applyFilters(); // Changed to _applyFilters
                    });
                  },
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 17),
              autofocus: true,
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _applyFilters(); // Changed to _applyFilters
                });
              },
            )
                : DropdownButtonHideUnderline( // Wrap DropdownButton with this to hide underline
              child: DropdownButton<String>(
                value: _currentList,
                dropdownColor: Theme.of(context).appBarTheme.backgroundColor, // Use app bar color for dropdown
                style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary, // Ensure text is white
                ),
                icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onPrimary), // White dropdown icon
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _currentList = newValue;
                      _applyFilters(); // Re-apply filters for new list
                    });
                  }
                },
                items: availableLists.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: _isSearching ? const Icon(Icons.search_off) : const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    _searchQuery = ''; // Clear search when toggling
                    if (!_isSearching) {
                      _applyFilters(); // Re-apply filters if search is turned off
                    }
                  });
                },
                tooltip: s.searchTooltip,
              ),
            ],
          ),
          // Today's Task Progress Tracker
          if (totalTodayTasks > 0 && _currentList == s.allListsTitle && !_isSearching) // Only show for "All Lists" and no search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.todayTasksProgress(completedTodayTasks, totalTodayTasks), // New localization key needed
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: todayProgress,
                    backgroundColor: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedTodos.isEmpty
                ? _buildEmptyState(Icons.task_alt_outlined, _searchQuery.isNotEmpty ? s.noMatchingTasks : s.noTasksIllustrationText) // Empty state
                : AnimatedList( // Changed to AnimatedList
              key: _listKey,
              initialItemCount: displayedTodos.length,
              itemBuilder: (context, index, animation) {
                final todo = displayedTodos[index];
                return SizeTransition( // Animation for adding/removing items
                  sizeFactor: animation,
                  child: _buildTodoCard(context, todo, index, s),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: s.enterQuickTaskHint, // Changed hint text
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                    onSubmitted: (_) => _addTodo(s), // Allow adding on submit
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact(); // Haptic feedback on quick add button
                    _addTodo(s);
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(60, 60), // Fixed size for button
                    padding: EdgeInsets.zero, // Remove default padding
                    backgroundColor: Theme.of(context).colorScheme.secondary, // Use accent for quick add button
                    foregroundColor: Theme.of(context).colorScheme.onSecondary, // Ensure contrasting icon color
                  ),
                  child: const Icon(Icons.add, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton( // Re-added FAB as per screenshot for "New Task"
        onPressed: () async {
          HapticFeedback.lightImpact(); // Haptic feedback on FAB tap
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return const TodoDetailScreen();
              },
            ),
          );
          if (result != null && result is TodoItem) {
            setState(() {
              _todos.add(result);
              _applyFilters();
              _saveTodos();
            });
            showAppSnackBar(context, s.taskSaved, icon: Icons.check, iconColor: Colors.green);
            _scheduleNotification(result, s); // Schedule notification for the saved task
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Position as in screenshot
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoCard(BuildContext context, TodoItem todo, int index, AppLocalizations s) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (bool? value) {
            HapticFeedback.lightImpact();
            _toggleTodoCompletion(index);
          },
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return Theme.of(context).colorScheme.secondary;
            }
            return null;
          }),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 16,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Theme.of(context).textTheme.bodySmall?.color : Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        subtitle: (todo.dueDate != null || todo.dueTime != null) && !todo.isCompleted
            ? Text(
          todo.formatDueDate(context, s),
          style: TextStyle(
            fontSize: 12,
            color: todo.isOverdue ? Colors.red : Theme.of(context).textTheme.bodySmall?.color,
          ),
        )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (todo.isRepeating && !todo.isCompleted)
              Icon(Icons.repeat, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            if (todo.isRepeating && !todo.isCompleted) const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red[400],
              onPressed: () {
                HapticFeedback.lightImpact();
                _deleteTodo(index);
              },
            ),
          ],
        ),
        onTap: () async {
          HapticFeedback.lightImpact();
          final editedTodo = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return TodoDetailScreen(
                  todoItem: TodoItem(
                    title: todo.title,
                    isCompleted: todo.isCompleted,
                    dueDate: todo.dueDate,
                    dueTime: todo.dueTime,
                    isRepeating: todo.isRepeating,
                    repeatInterval: todo.repeatInterval,
                    listName: todo.listName,
                    creationDate: todo.creationDate,
                  ),
                );
              },
            ),
          );

          if (editedTodo != null && editedTodo is TodoItem) {
            final int originalIndex = _todos.indexWhere(
                    (t) => t.title == todo.title && t.creationDate == todo.creationDate
            );
            if (originalIndex != -1) {
              setState(() {
                _todos[originalIndex] = editedTodo;
                _applyFilters();
                _saveTodos();
              });
              _scheduleNotification(editedTodo, s);
            }
          }
        },
      ),
    );
  }
}

class TodoDetailScreen extends StatefulWidget {
  final TodoItem? todoItem;

  const TodoDetailScreen({super.key, this.todoItem});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRepeatInterval;
  String? _selectedListName;
  bool _isEditing = false;
  late DateTime _creationDate;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.todoItem != null) {
      _isEditing = true;
      _titleController.text = widget.todoItem!.title;
      _selectedDate = widget.todoItem!.dueDate;
      _selectedTime = widget.todoItem!.dueTime;
      _selectedRepeatInterval = widget.todoItem!.repeatInterval;
      _selectedListName = widget.todoItem!.listName;
      _creationDate = widget.todoItem!.creationDate;
      // Initialize notificationsEnabled based on whether due date/time are set
      _notificationsEnabled = (widget.todoItem!.dueDate != null && widget.todoItem!.dueTime != null);
    } else {
      _creationDate = DateTime.now();
      _notificationsEnabled = false; // Default to off for new tasks unless a date/time is set
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(AppLocalizations s) async {
    HapticFeedback.lightImpact();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      locale: Localizations.localeOf(context),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        if (_selectedTime == null) {
          _selectedTime = TimeOfDay.now(); // Set a default time if date is picked but time is not
        }
        _notificationsEnabled = true; // Enable notifications if date is set
      });
    }
  }

  Future<void> _pickTime(AppLocalizations s) async {
    HapticFeedback.lightImpact();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        if (_selectedDate == null) {
          _selectedDate = DateTime.now(); // Set a default date if time is picked but date is not
        }
        _notificationsEnabled = true; // Enable notifications if time is set
      });
    }
  }

  void _saveTask(AppLocalizations s) {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      showAppSnackBar(context, s.emptyTaskError, icon: Icons.warning_amber_outlined, iconColor: Colors.orange);
      return;
    }
    HapticFeedback.lightImpact();

    // If notifications are disabled, clear date/time and repeat interval
    DateTime? finalDueDate = _selectedDate;
    TimeOfDay? finalDueTime = _selectedTime;
    String? finalRepeatInterval = _selectedRepeatInterval;

    if (!_notificationsEnabled) {
      finalDueDate = null;
      finalDueTime = null;
      finalRepeatInterval = null; // Also clear repeat interval if notifications are off
    }


    final newTodoItem = TodoItem(
      title: title,
      isCompleted: widget.todoItem?.isCompleted ?? false,
      dueDate: finalDueDate,
      dueTime: finalDueTime,
      isRepeating: finalRepeatInterval != null && finalRepeatInterval != s.noRepeat,
      repeatInterval: finalRepeatInterval == s.noRepeat ? null : finalRepeatInterval,
      listName: _selectedListName == s.defaultList ? null : _selectedListName,
      creationDate: _creationDate,
    );

    // Notification scheduling is handled in TodoListScreen after pop returns the item
    Navigator.pop(context, newTodoItem);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final List<String> repeatOptions = [
      s.noRepeat,
      s.daily,
      s.weekly,
      s.monthly,
      s.everyXDays(2), // Requires custom localization key
      s.weekdays, // Requires custom localization key
      s.weekends, // Requires custom localization key
    ];
    final List<String> listOptions = [s.defaultList, s.personal, s.work, s.shopping];

    _selectedRepeatInterval ??= s.noRepeat;
    _selectedListName ??= s.defaultList;


    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.editTaskTitle : s.newTaskTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _saveTask(s),
            tooltip: s.saveTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.whatIsToBeDone, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: s.enterYourTaskHere,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: Theme.of(context).textTheme.bodyLarge,
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            Text(s.dueDate, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.calendar_today_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              title: Text(_selectedDate == null ? s.notSet : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(_selectedDate!)),
              trailing: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                onPressed: () { setState(() { _selectedDate = null; if (_selectedTime == null) _notificationsEnabled = false; }); },
              ),
              onTap: () => _pickDate(s),
              tileColor: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            const SizedBox(height: 10),

            Text(s.dueTime, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              title: Text(_selectedTime == null ? s.notSet : MaterialLocalizations.of(context).formatTimeOfDay(_selectedTime!, alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat)),
              trailing: IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                onPressed: () { setState(() { _selectedTime = null; if (_selectedDate == null) _notificationsEnabled = false; }); },
              ),
              onTap: () => _pickTime(s),
              tileColor: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            const SizedBox(height: 20),

            // Notifications Toggle
            Text(s.notifications, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(s.enableNotifications), // Added a specific localization key for clarity
              value: _notificationsEnabled,
              onChanged: (_selectedDate != null || _selectedTime != null) ? (bool value) { // Only allow toggle if date/time is set
                setState(() {
                  _notificationsEnabled = value;
                  if (!value) {
                    // If disabling, clear repeat interval as it's tied to notifications
                    _selectedRepeatInterval = s.noRepeat;
                  }
                });
              } : null, // Disable if no date/time is set
              tileColor: Theme.of(context).cardTheme.color,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
            const SizedBox(height: 20),

            Text(s.repeat, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRepeatInterval ?? s.noRepeat,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: repeatOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
                );
              }).toList(),
              onChanged: _notificationsEnabled ? (String? newValue) { // Only allow change if notifications enabled
                setState(() {
                  _selectedRepeatInterval = newValue;
                });
              } : null, // Disable if notifications are off
            ),
            const SizedBox(height: 20),

            Text(s.addToLlist, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedListName ?? s.defaultList,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: listOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedListName = newValue;
                });
              },
            ),
            const SizedBox(height: 40),

            Center(
              child: ElevatedButton.icon(
                onPressed: () => _saveTask(s),
                icon: const Icon(Icons.check),
                label: Text(s.saveTask),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
