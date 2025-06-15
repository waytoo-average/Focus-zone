// Imports that will be needed across many core components
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // For all providers
import 'package:shared_preferences/shared_preferences.dart'; // For Theme/Lang/Download providers
import 'package:path_provider/path_provider.dart'; // For DownloadPathProvider
import 'dart:async'; // For providers async operations
import 'dart:developer' as developer; // For logging in providers/helpers
import 'dart:math'; // For pow in formatBytes
import 'package:google_sign_in/google_sign_in.dart'; // For SignInProvider
import 'package:googleapis/drive/v3.dart' as drive; // For SignInProvider
import 'package:http/http.dart' as http; // For GoogleHttpClient
import 'package:app/l10n/app_localizations.dart'; // For localization

// Imports specific to RootScreen's functionality, now pointing to combined feature files
import 'package:app/study_features.dart'; // For GradeSelectionScreen, DepartmentSelectionScreen, etc.
import 'package:app/todo_features.dart';   // For TodoListScreen, TodoDetailScreen
import 'package:app/settings_features.dart'; // For SettingsScreen, AboutScreen, CollegeInfoScreen


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

  // --- NEW: Helper to get the canonical (English) string for map lookup ---
  // This is crucial for matching the hardcoded keys in _allAcademicContentFolders.
  String? getCanonicalGrade(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    if (grade == s.firstGrade) return 'First Grade';
    if (grade == s.secondGrade) return 'Second Grade';
    if (grade == s.thirdGrade) return 'Third Grade';
    if (grade == s.fourthGrade) return 'Fourth Grade';
    return null; // Should not happen if localization is consistent
  }

  String? getCanonicalDepartment(BuildContext context) {
    if (department == null) return null;
    final s = AppLocalizations.of(context)!;
    if (department == s.communication) return 'Communication';
    if (department == s.electronics) return 'Electronics';
    if (department == s.mechatronics) return 'Mechatronics';
    return null;
  }

  String? getCanonicalYear(BuildContext context) {
    if (year == null) return null;
    final s = AppLocalizations.of(context)!;
    if (year == s.currentYear) return 'Current Year';
    if (year == s.lastYear) return 'Last Year';
    return null;
  }

  String? getCanonicalSemester(BuildContext context) {
    if (semester == null) return null;
    final s = AppLocalizations.of(context)!;
    if (semester == s.semester1) return 'Semester 1';
    if (semester == s.semester2) return 'Semester 2';
    return null;
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
      await prefs.setString('languageCode', newLocale.languageCode); // FIX: Corrected this line
      notifyListeners();
    }
  }
}

// --- DownloadPathProvider ---
class DownloadPathProvider extends ChangeNotifier {
  String? _appSpecificDownloadPath; // Stores the resolved app-specific path

  DownloadPathProvider() {
    _initAppSpecificDownloadPath();
  }

  // Initialize and store the app-specific download path
  Future<void> _initAppSpecificDownloadPath() async {
    // Get the external storage directory for Android, or application documents for iOS/others
    final directory = await getApplicationDocumentsDirectory();
    String baseDir = directory.path;

    // Define the specific sub-directory for downloads
    final appDownloadDir = Directory('$baseDir/StudyStationDownloads');

    // Ensure the directory exists
    if (!await appDownloadDir.exists()) {
      try {
        await appDownloadDir.create(recursive: true);
        developer.log("Created app-specific download directory: ${appDownloadDir.path}", name: "DownloadPathProvider");
      } catch (e) {
        developer.log("Error creating app-specific download directory: $e", name: "DownloadPathProvider");
        // Handle error, maybe show a persistent message to the user
      }
    }
    _appSpecificDownloadPath = appDownloadDir.path;
    developer.log("Initialized app-specific download path: $_appSpecificDownloadPath", name: "DownloadPathProvider");
    notifyListeners(); // Notify listeners that the path is now available
  }

  // This is the primary method to get the path to use for downloads
  // It always returns the fixed app-specific path.
  Future<String> getEffectiveDownloadPath() async {
    // Ensure the path is initialized before returning
    if (_appSpecificDownloadPath == null) {
      await _initAppSpecificDownloadPath();
    }
    return _appSpecificDownloadPath!;
  }

  // Retain this for legacy calls or specific needs, but it now directly returns the effective path
  Future<String> getAppSpecificDownloadPath() async {
    return await getEffectiveDownloadPath();
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

// --- Splash Screen ---
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
      if (mounted) Navigator.pushReplacementNamed(context, '/rootScreen'); // Navigate to RootScreen
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

// GlobalKey for RootScreenState to access its methods from children
final GlobalKey<RootScreenState> rootScreenKey = GlobalKey<RootScreenState>();

// New RootScreen for Bottom Navigation Bar (Now contains references to all features)
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => RootScreenState(); // Changed to public RootScreenState
}

class RootScreenState extends State<RootScreen> { // Made public
  int _selectedIndex = 0;

  // GlobalKey for each nested Navigator to manage their respective stacks.
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(), // Dashboard
    1: GlobalKey<NavigatorState>(), // Study
    2: GlobalKey<NavigatorState>(), // To-Do list
    3: GlobalKey<NavigatorState>(), // Up-coming
    4: GlobalKey<NavigatorState>(), // Settings
  };

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index]?.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // A helper function to build an Offstage widget containing a Navigator for each tab.
  Widget _buildOffstageNavigator(int index, Widget initialRouteWidget) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          if (routeSettings.name == '/') {
            return MaterialPageRoute(builder: (context) => initialRouteWidget);
          }
          // --- ALL NESTED TAB ROUTES ARE HANDLED HERE ---
          // This keeps MaterialApp's routes cleaner in main.dart
          switch (routeSettings.name) {
          // Study Features
            case '/departments':
              final academicContext = routeSettings.arguments;
              if (academicContext is AcademicContext) {
                return MaterialPageRoute(builder: (context) => DepartmentSelectionScreen(academicContext: academicContext));
              }
              return MaterialPageRoute(builder: (context) => ErrorScreen(message: AppLocalizations.of(context)?.errorMissingContext ?? "Missing academic context for departments."));
            case '/years':
              final academicContext = routeSettings.arguments;
              if (academicContext is AcademicContext) {
                return MaterialPageRoute(builder: (context) => YearSelectionScreen(academicContext: academicContext));
              }
              return MaterialPageRoute(builder: (context) => ErrorScreen(message: AppLocalizations.of(context)?.errorMissingContext ?? "Missing academic context for years."));
            case '/semesters':
              final academicContext = routeSettings.arguments;
              if (academicContext is AcademicContext) {
                return MaterialPageRoute(builder: (context) => SemesterSelectionScreen(academicContext: academicContext));
              }
              return MaterialPageRoute(builder: (context) => ErrorScreen(message: AppLocalizations.of(context)?.errorMissingContext ?? "Missing academic context for semesters."));
            case '/subjects':
              final arguments = routeSettings.arguments;
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
                return MaterialPageRoute(builder: (context) => ErrorScreen(message: s?.errorMissingSubjectDetails ?? "Unknown error: Missing academic context."));
              }
              return MaterialPageRoute(builder: (context) => SubjectSelectionScreen(
                subjects: subjectsMap,
                academicContext: academicContext!,
              ));
            case '/subjectContentScreen':
              final args = routeSettings.arguments;
              if (args is! Map<String, dynamic> || !args.containsKey('subjectName') || !args.containsKey('rootFolderId') || !args.containsKey('academicContext')) {
                return MaterialPageRoute(builder: (context) => ErrorScreen(message: AppLocalizations.of(context)?.errorMissingSubjectDetails ?? "Missing subject details."));
              }
              return MaterialPageRoute(builder: (context) => SubjectContentScreen(
                subjectName: args['subjectName'] as String,
                rootFolderId: args['rootFolderId'] as String,
                academicContext: args['academicContext'] as AcademicContext,
              ));

          // To-Do Features
            case '/todoDetailScreen':
              final args = routeSettings.arguments;
              return MaterialPageRoute(builder: (context) => TodoDetailScreen(todoItem: args is TodoItem ? args : null));

          // Settings Features
            case '/about':
              return MaterialPageRoute(builder: (context) => const AboutScreen());
            case '/collegeInfo':
              return MaterialPageRoute(builder: (context) => const CollegeInfoScreen());

          // --- Global routes that should NOT be nested. This handles accidental pushes ---
            case '/pdfViewer':
            case '/googleDriveViewer':
            case '/lectureFolderBrowser':
              return MaterialPageRoute(builder: (context) => ErrorScreen(message: AppLocalizations.of(context)?.errorAttemptedGlobalPush ?? "Attempted to push a global route on a nested navigator."));

            default:
              return MaterialPageRoute(builder: (context) => ErrorScreen(message: AppLocalizations.of(context)?.errorPageNotFound(routeSettings.name ?? 'Unknown') ?? "Page not found: ${routeSettings.name}"));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final NavigatorState? currentNavigator = _navigatorKeys[_selectedIndex]?.currentState;

        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else if (_selectedIndex != 0) {
          _onItemTapped(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildOffstageNavigator(0, const DashboardScreen()),
            _buildOffstageNavigator(1, const GradeSelectionScreen()),
            _buildOffstageNavigator(2, const TodoListScreen()),
            _buildOffstageNavigator(3, Scaffold(appBar: AppBar(title: Text(s.upComing)), body: Center(child: Text(s.upComingContent, style: Theme.of(context).textTheme.titleLarge)))),
            _buildOffstageNavigator(4, const SettingsScreen()),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.star_outline),
              activeIcon: const Icon(Icons.star),
              label: s.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.school_outlined),
              activeIcon: const Icon(Icons.school),
              label: s.studyButton,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.task_alt_outlined),
              activeIcon: const Icon(Icons.task_alt),
              label: s.todoListButton,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.upcoming_outlined),
              activeIcon: const Icon(Icons.upcoming),
              label: s.upComing,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: s.settings,
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.secondary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardTheme.color,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 10,
        ),
      ),
    );
  }
}

// Dashboard Screen - NO LONGER HAS ITS OWN SCAFFOLD OR APPBAR
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final signInProvider = Provider.of<SignInProvider>(context);
    final user = signInProvider.currentUser;

    return Column(
      children: [
        AppBar(
          title: Text(s.appTitle),
          automaticallyImplyLeading: false,
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_outlined, size: 80, color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
                  const SizedBox(height: 20),
                  Text(
                    s.dashboardPlaceholder,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.dashboardComingSoon,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}