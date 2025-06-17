// Imports that will be needed across many core components
import 'dart:convert';
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
import 'package:permission_handler/permission_handler.dart'; // NEW: For permissions in provider

// Imports specific to RootScreen's functionality, now pointing to combined feature files
import 'package:app/study_features.dart'; // For GradeSelectionScreen, DepartmentSelectionScreen, etc.
import 'package:app/todo_features.dart'; // For TodoListScreen, TodoDetailScreen
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
void showAppSnackBar(BuildContext context, String message,
    {IconData? icon,
    Color? iconColor,
    SnackBarAction? action,
    Color? backgroundColor}) {
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
      backgroundColor: backgroundColor ??
          Theme.of(context).primaryColor, // Default to primary color
      action: action,
      duration: const Duration(seconds: 3), // Default duration
      behavior: SnackBarBehavior.floating, // Make it float
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)), // Rounded corners
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

  ThemeProvider() {
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString().split('.').last == themeString,
        orElse: () => ThemeMode.system);
    notifyListeners();
  }

  void setThemeMode(ThemeMode newMode) async {
    if (newMode != _themeMode) {
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

  LanguageProvider() {
    _loadLocale();
  }

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
  static const String _kCustomDownloadPathKey = 'customDownloadPath';
  String? _appSpecificDownloadPath; // Stores the resolved app-specific path
  String? _customDownloadPath; // Stores the user-selected custom path

  DownloadPathProvider() {
    _initPaths();
  }

  // Initialize both app-specific and custom download paths
  Future<void> _initPaths() async {
    await _initAppSpecificDownloadPath();
    await _loadCustomDownloadPath();
    notifyListeners(); // Notify after both paths are potentially loaded
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
        developer.log(
            "Created app-specific download directory: ${appDownloadDir.path}",
            name: "DownloadPathProvider");
      } catch (e) {
        developer.log("Error creating app-specific download directory: $e",
            name: "DownloadPathProvider");
        // Handle error, maybe show a persistent message to the user
      }
    }
    _appSpecificDownloadPath = appDownloadDir.path;
    developer.log(
        "Initialized app-specific download path: $_appSpecificDownloadPath",
        name: "DownloadPathProvider");
  }

  // Load custom download path from SharedPreferences
  Future<void> _loadCustomDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    _customDownloadPath = prefs.getString(_kCustomDownloadPathKey);
    developer.log("Loaded custom download path: $_customDownloadPath",
        name: "DownloadPathProvider");
  }

  // Set and persist a new custom download path
  Future<void> setCustomDownloadPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_kCustomDownloadPathKey, path);
    } else {
      await prefs.remove(_kCustomDownloadPathKey); // Clear custom path
    }
    _customDownloadPath = path;
    developer.log("Set custom download path: $_customDownloadPath",
        name: "DownloadPathProvider");
    notifyListeners();
  }

  // Reset to the app-specific default path
  Future<void> resetDownloadPath() async {
    await setCustomDownloadPath(null); // Clear custom path
  }

  // This is the primary method to get the path to use for downloads
  Future<String> getEffectiveDownloadPath() async {
    if (Platform.isIOS) {
      if (_appSpecificDownloadPath == null) {
        await _initAppSpecificDownloadPath();
      }
      return _appSpecificDownloadPath!;
    }

    // Android: Prioritize custom path if set and valid
    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      final customDir = Directory(_customDownloadPath!);
      if (await customDir.exists()) {
        // Verify write access
        try {
          final testFile = File('${_customDownloadPath}/.test_write');
          await testFile.writeAsString('test');
          await testFile.delete();
          return _customDownloadPath!;
        } catch (e) {
          developer.log("Custom path not writable: $e",
              name: "DownloadPathProvider");
          // Fall back to app-specific path if custom path is not writable
          await resetDownloadPath();
        }
      } else {
        // If custom path no longer exists, clear it and fall back to app-specific
        developer.log(
            "Custom download path $_customDownloadPath does not exist. Resetting.",
            name: "DownloadPathProvider");
        await resetDownloadPath();
      }
    }

    // Fall back to app-specific path
    if (_appSpecificDownloadPath == null) {
      await _initAppSpecificDownloadPath();
    }
    return _appSpecificDownloadPath!;
  }

  // Retain this for legacy calls or specific needs, but it now directly returns the effective path
  Future<String> getAppSpecificDownloadPath() async {
    return await getEffectiveDownloadPath();
  }

  // Modified: Centralized function to request storage permissions
  Future<bool> requestStoragePermissions(
      BuildContext context, AppLocalizations s) async {
    if (Platform.isAndroid) {
      // For Android 11 (API 30) and above, we need MANAGE_EXTERNAL_STORAGE
      if (await Permission.manageExternalStorage.isGranted) {
        developer.log("MANAGE_EXTERNAL_STORAGE permission already granted.",
            name: "Permissions");
        return true;
      }

      // Check if this is first launch and permission dialog hasn't been shown
      final firstLaunchProvider =
          Provider.of<FirstLaunchProvider>(context, listen: false);
      if (!firstLaunchProvider.hasShownPermissionDialog) {
        // For Android 11+, we need to open settings directly for MANAGE_EXTERNAL_STORAGE
        if (context.mounted) {
          await Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext dialogContext) {
                return AlertDialog(
                  title: Text(s.storagePermissionTitle),
                  content: Text(
                    'This app needs storage permission to download and save files.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text(s.cancel),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                    ),
                    TextButton(
                      child: Text(s.settings),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Permission.manageExternalStorage.request();
                      },
                    ),
                  ],
                );
              },
            );
          });
        }
        await firstLaunchProvider.markPermissionDialogShown();
        return false;
      } else {
        // For subsequent launches, check if we have the permission
        if (await Permission.manageExternalStorage.isGranted) {
          return true;
        }

        // If not granted, show a snackbar to open settings
        if (context.mounted) {
          await Future.delayed(Duration.zero, () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.permissionDeniedForever),
                action: SnackBarAction(
                  label: s.settings,
                  onPressed: () {
                    Permission.manageExternalStorage.request();
                  },
                ),
              ),
            );
          });
        }
        return false;
      }
    } else if (Platform.isIOS) {
      // For iOS, we only need photos permission
      PermissionStatus photosStatus = await Permission.photos.request();
      return photosStatus.isGranted;
    }
    return false;
  }
}

// --- RecentFile Model for Dashboard ---
class RecentFile {
  final String id;
  final String name;
  final String? url; // Can be a webViewLink or direct download link
  final String mimeType;
  final DateTime accessTime;

  RecentFile({
    required this.id,
    required this.name,
    this.url,
    required this.mimeType,
    required this.accessTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
        'mimeType': mimeType,
        'accessTime': accessTime.toIso8601String(),
      };

  factory RecentFile.fromJson(Map<String, dynamic> json) => RecentFile(
        id: json['id'] as String,
        name: json['name'] as String,
        url: json['url'] as String?,
        mimeType: json['mimeType'] as String,
        accessTime: DateTime.parse(json['accessTime'] as String),
      );
}

// --- RecentFilesProvider ---
class RecentFilesProvider extends ChangeNotifier {
  static const _kRecentFilesKey = 'recentFiles';
  List<RecentFile> _recentFiles = [];
  List<RecentFile> get recentFiles => _recentFiles;

  RecentFilesProvider() {
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? recentFilesString = prefs.getString(_kRecentFilesKey);
    if (recentFilesString != null) {
      final List<dynamic> jsonList =
          jsonDecode(recentFilesString) as List<dynamic>;
      _recentFiles = jsonList
          .map((json) => RecentFile.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _saveRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString =
        jsonEncode(_recentFiles.map((file) => file.toJson()).toList());
    await prefs.setString(_kRecentFilesKey, jsonString);
  }

  void addRecentFile(RecentFile file) {
    // Remove if already exists to move it to the top
    _recentFiles.removeWhere((f) => f.id == file.id);
    _recentFiles.insert(0, file); // Add to the beginning
    // Keep only the latest N files (e.g., 5)
    if (_recentFiles.length > 5) {
      _recentFiles = _recentFiles.sublist(0, 5);
    }
    _saveRecentFiles();
    notifyListeners();
  }
}

// --- TodoSummaryProvider (now handles persistence as well) ---
class TodoSummaryProvider extends ChangeNotifier {
  static const _kTodosKey = 'todos'; // Key for SharedPreferences

  List<TodoItem> _allTodos = []; // Master list of all todos

  int _totalTasks = 0;
  int _completedToday = 0;
  int _overdueTasks = 0;
  TodoItem? _nextUpcomingTask; // New: for the next upcoming task

  List<TodoItem> get allTodos => _allTodos; // Expose the full list
  int get totalTasks => _totalTasks;
  int get completedToday => _completedToday;
  int get overdueTasks => _overdueTasks;
  TodoItem? get nextUpcomingTask => _nextUpcomingTask; // New getter

  TodoSummaryProvider() {
    _loadTodosAndSummary();
  }

  // Combined method to load all todos and update summary stats
  Future<void> _loadTodosAndSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosString = prefs.getString(_kTodosKey);
      List<dynamic> todoListJson = [];
      if (todosString != null) {
        todoListJson = jsonDecode(todosString);
      }

      _allTodos = todoListJson.map((json) => TodoItem.fromJson(json)).toList();

      _updateSummaryStats(); // Calculate stats from _allTodos
    } catch (e) {
      developer.log("TodoSummaryProvider Error loading todos: $e",
          name: "TodoSummaryProvider");
    } finally {
      notifyListeners();
    }
  }

  // Internal method to calculate summary stats from _allTodos
  void _updateSummaryStats() {
    _totalTasks = _allTodos.length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _completedToday = _allTodos
        .where((todo) =>
            todo.isCompleted &&
            todo.dueDate != null &&
            DateTime(todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day)
                .isAtSameMomentAs(today))
        .length;

    _overdueTasks =
        _allTodos.where((todo) => todo.isOverdue && !todo.isCompleted).length;

    // Calculate next upcoming task
    _nextUpcomingTask = null;
    DateTime? closestDueDate;

    for (var todo in _allTodos) {
      if (!todo.isCompleted && todo.dueDate != null) {
        DateTime taskDateTime;
        if (todo.dueTime != null) {
          taskDateTime = DateTime(todo.dueDate!.year, todo.dueDate!.month,
              todo.dueDate!.day, todo.dueTime!.hour, todo.dueTime!.minute);
        } else {
          // If no time, consider beginning of day for comparison
          taskDateTime = DateTime(
              todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
        }

        if (taskDateTime.isAfter(now)) {
          // Only consider future tasks
          if (closestDueDate == null || taskDateTime.isBefore(closestDueDate)) {
            closestDueDate = taskDateTime;
            _nextUpcomingTask = todo;
          }
        }
      }
    }
  }

  // Public method to trigger a refresh of stats
  void refreshSummary() {
    _loadTodosAndSummary(); // Reloads all, then updates summary
  }

  // Method to save a new or updated todo item
  Future<void> saveTodo(TodoItem todoItem) async {
    int existingIndex =
        _allTodos.indexWhere((t) => t.creationDate == todoItem.creationDate);

    if (existingIndex != -1) {
      // Update existing item
      _allTodos[existingIndex] = todoItem;
    } else {
      // Add new item
      _allTodos.add(todoItem);
    }
    await _persistTodos();
    notifyListeners(); // Notify after changes are persisted
  }

  // Method to delete a todo item
  Future<void> deleteTodo(TodoItem todoItem) async {
    _allTodos.removeWhere((t) => t.creationDate == todoItem.creationDate);
    await _persistTodos();
    notifyListeners(); // Notify after changes are persisted
  }

  // Private method to persist the current _allTodos list to SharedPreferences
  Future<void> _persistTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String todosString =
          jsonEncode(_allTodos.map((todo) => todo.toJson()).toList());
      await prefs.setString(_kTodosKey, todosString);
      _updateSummaryStats(); // Recalculate summary after persistence
    } catch (e) {
      developer.log("TodoSummaryProvider Error saving todos: $e",
          name: "TodoSummaryProvider");
    }
  }
}

// --- Basic Error Screen ---
class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context)?.error ?? "Error")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16)),
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
      if (mounted)
        Navigator.pushReplacementNamed(
            context, '/rootScreen'); // Navigate to RootScreen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Text('ECCAT',
            style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0)),
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
  State<RootScreen> createState() =>
      RootScreenState(); // Changed to public RootScreenState
}

class RootScreenState extends State<RootScreen> {
  // Made public
  int _selectedIndex = 0;

  // GlobalKey for each nested Navigator to manage their respective stacks.
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(), // Dashboard
    1: GlobalKey<NavigatorState>(), // Study
    2: GlobalKey<NavigatorState>(), // To-Do list
    3: GlobalKey<NavigatorState>(), // Up-coming
    4: GlobalKey<NavigatorState>(), // Settings
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Request permissions when the root screen loads and localizations are available
    final downloadPathProvider =
        Provider.of<DownloadPathProvider>(context, listen: false);
    final firstLaunchProvider =
        Provider.of<FirstLaunchProvider>(context, listen: false);
    final s = AppLocalizations.of(context);
    if (s != null) {
      // Only show the native permission dialog on first launch
      if (!firstLaunchProvider.hasShownPermissionDialog) {
        downloadPathProvider.requestStoragePermissions(context, s);
      }
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // Use Future.microtask to ensure navigation happens after current frame
      Future.microtask(() {
        _navigatorKeys[index]?.currentState?.popUntil((route) => route.isFirst);
      });
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
                return MaterialPageRoute(
                    builder: (context) => DepartmentSelectionScreen(
                        academicContext: academicContext));
              }
              return MaterialPageRoute(
                  builder: (context) => ErrorScreen(
                      message:
                          AppLocalizations.of(context)?.errorMissingContext ??
                              "Missing academic context for departments."));
            case '/years':
              final academicContext = routeSettings.arguments;
              if (academicContext is AcademicContext) {
                return MaterialPageRoute(
                    builder: (context) =>
                        YearSelectionScreen(academicContext: academicContext));
              }
              return MaterialPageRoute(
                  builder: (context) => ErrorScreen(
                      message:
                          AppLocalizations.of(context)?.errorMissingContext ??
                              "Missing academic context for years."));
            case '/semesters':
              final academicContext = routeSettings.arguments;
              if (academicContext is AcademicContext) {
                return MaterialPageRoute(
                    builder: (context) => SemesterSelectionScreen(
                        academicContext: academicContext));
              }
              return MaterialPageRoute(
                  builder: (context) => ErrorScreen(
                      message:
                          AppLocalizations.of(context)?.errorMissingContext ??
                              "Missing academic context for semesters."));
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
                return MaterialPageRoute(
                    builder: (context) => ErrorScreen(
                        message: s?.errorMissingSubjectDetails ??
                            "Unknown error: Missing academic context."));
              }
              return MaterialPageRoute(
                  builder: (context) => SubjectSelectionScreen(
                        subjects: subjectsMap,
                        academicContext: academicContext!,
                      ));
            case '/subjectContentScreen':
              final args = routeSettings.arguments;
              if (args is! Map<String, dynamic> ||
                  !args.containsKey('subjectName') ||
                  !args.containsKey('rootFolderId') ||
                  !args.containsKey('academicContext')) {
                return MaterialPageRoute(
                    builder: (context) => ErrorScreen(
                        message: AppLocalizations.of(context)
                                ?.errorMissingSubjectDetails ??
                            "Missing subject details."));
              }
              return MaterialPageRoute(
                  builder: (context) => SubjectContentScreen(
                        subjectName: args['subjectName'] as String,
                        rootFolderId: args['rootFolderId'] as String,
                        academicContext:
                            args['academicContext'] as AcademicContext,
                      ));

            // To-Do Features
            case '/todoDetailScreen':
              final args = routeSettings.arguments;
              return MaterialPageRoute(
                  builder: (context) => TodoDetailScreen(
                      todoItem: args is TodoItem ? args : null));

            // Settings Features
            case '/about':
              return MaterialPageRoute(
                  builder: (context) => const AboutScreen());
            case '/collegeInfo':
              return MaterialPageRoute(
                  builder: (context) => const CollegeInfoScreen());

            // --- Global routes that should NOT be nested. This handles accidental pushes ---
            case '/pdfViewer':
            case '/googleDriveViewer':
            case '/lectureFolderBrowser':
              return MaterialPageRoute(
                  builder: (context) => ErrorScreen(
                      message: AppLocalizations.of(context)
                              ?.errorAttemptedGlobalPush ??
                          "Attempted to push a global route on a nested navigator."));

            default:
              return MaterialPageRoute(
                  builder: (context) => ErrorScreen(
                      message: AppLocalizations.of(context)?.errorPageNotFound(
                              routeSettings.name ?? 'Unknown') ??
                          "Page not found: ${routeSettings.name}"));
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

        final NavigatorState? currentNavigator =
            _navigatorKeys[_selectedIndex]?.currentState;

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
            _buildOffstageNavigator(
                3,
                Scaffold(
                    appBar: AppBar(title: Text(s.upComing)),
                    body: Center(
                        child: Text(s.upComingContent,
                            style: Theme.of(context).textTheme.titleLarge)))),
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
          unselectedItemColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).cardTheme.color,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 10,
        ),
      ),
    );
  }
}

// Dashboard Screen with modern UI and activity states
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final signInProvider = Provider.of<SignInProvider>(context);
    final todoSummary = Provider.of<TodoSummaryProvider>(context);
    final recentFilesProvider = Provider.of<RecentFilesProvider>(context);

    final user = signInProvider.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0, // This is the height when fully expanded
            floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            automaticallyImplyLeading: false, // Control leading widget manually
            leading: Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, top: 16.0), // Adjust padding as needed
              child: Opacity(
                opacity: user != null ? 1.0 : 0.0, // Fade out if not signed in
                child: CircleAvatar(
                  radius: 20, // Smaller radius for app bar icon
                  backgroundColor: Colors.white,
                  backgroundImage: user?.photoUrl != null
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl == null
                      ? Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : (user?.email?.isNotEmpty == true
                                  ? user!.email![0].toUpperCase()
                                  : '?'),
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 18))
                      : null,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              // Re-introduced FlexibleSpaceBar for title animation
              // Adjusted titlePadding to be more left-aligned with a gap from leading widget
              titlePadding: const EdgeInsets.only(left: 72.0, bottom: 16.0),
              centerTitle: false, // Title aligns to the start
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.appTitle,
                      style: Theme.of(context)
                          .appBarTheme
                          .titleTextStyle
                          ?.copyWith(fontSize: 18)),
                  if (user != null)
                    Text(
                      s.welcomeUser(user.displayName ?? user.email!),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.white70, fontSize: 14),
                    ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).colorScheme.primary.withOpacity(0.7)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                // Removed the CircleAvatar from here as it's now in 'leading'
              ),
            ),
            actions: [
              if (user == null)
                TextButton(
                  onPressed: signInProvider.signIn,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0)),
                  child: Text(s.signIn, style: const TextStyle(fontSize: 16)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: signInProvider.signOut,
                  tooltip: s.signOut,
                ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Your Study Activity Card
                      _buildDashboardCard(
                        context,
                        title: s.yourStudyActivity,
                        icon: Icons.school_outlined,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.history_toggle_off),
                            title: Text(s.lastOpened),
                            subtitle: recentFilesProvider.recentFiles.isNotEmpty
                                ? Text(
                                    recentFilesProvider.recentFiles.first.name)
                                : Text(s.noRecentFiles),
                            trailing: recentFilesProvider.recentFiles.isNotEmpty
                                ? Icon(Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6))
                                : null,
                            onTap: recentFilesProvider.recentFiles.isNotEmpty
                                ? () {
                                    final file =
                                        recentFilesProvider.recentFiles.first;
                                    if (file.mimeType.contains('pdf')) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pushNamed(
                                        '/pdfViewer',
                                        arguments: {
                                          'fileUrl': file.url,
                                          'fileId': file.id,
                                          'fileName': file.name
                                        },
                                      );
                                    } else if (file.url != null) {
                                      Navigator.of(context, rootNavigator: true)
                                          .pushNamed(
                                        '/googleDriveViewer',
                                        arguments: {
                                          'embedUrl': file.url,
                                          'fileId': file.id,
                                          'fileName': file.name,
                                          'mimeType': file.mimeType
                                        },
                                      );
                                    } else {
                                      showAppSnackBar(
                                          context, s.cannotOpenFileType);
                                    }
                                  }
                                : null,
                          ),
                          Divider(
                              indent: 16,
                              endIndent: 16,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.2)),
                          ListTile(
                            leading: const Icon(Icons.view_carousel_outlined),
                            title: Text(s.documentsViewedThisWeek(
                                recentFilesProvider.recentFiles
                                    .length)), // Simple count of recent files
                            subtitle: Text(s.keepLearning),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // To-Do Snapshot Card
                      _buildDashboardCard(
                        context,
                        title: s.todoSnapshot,
                        icon: Icons.task_alt_outlined,
                        children: [
                          ListTile(
                            leading: Icon(Icons.event_note,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7)),
                            title: Text(s.nextDeadline),
                            subtitle: todoSummary.nextUpcomingTask != null
                                ? Text(
                                    '${todoSummary.nextUpcomingTask!.title} (${todoSummary.nextUpcomingTask!.formatDueDate(context, s)})')
                                : Text(s.noUpcomingTasks),
                            trailing: todoSummary.nextUpcomingTask != null
                                ? Icon(Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6))
                                : null,
                            onTap: todoSummary.nextUpcomingTask != null
                                ? () {
                                    rootScreenKey.currentState?.setState(() =>
                                        rootScreenKey
                                                .currentState?._selectedIndex =
                                            2); // Go to To-Do List
                                  }
                                : null,
                          ),
                          Divider(
                              indent: 16,
                              endIndent: 16,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.2)),
                          ListTile(
                            leading: Icon(Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.secondary),
                            title: Text(s.dailyTaskProgress(
                                todoSummary.completedToday,
                                todoSummary.totalTasks)),
                            subtitle: LinearProgressIndicator(
                              value: todoSummary.totalTasks > 0
                                  ? todoSummary.completedToday /
                                      todoSummary.totalTasks
                                  : 0.0,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.secondary),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          if (todoSummary.overdueTasks > 0)
                            Column(
                              children: [
                                Divider(
                                    indent: 16,
                                    endIndent: 16,
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.2)),
                                ListTile(
                                  leading: const Icon(Icons.error_outline,
                                      color: Colors.red),
                                  title: Text(s.overdueTasksDashboard(
                                      todoSummary.overdueTasks)),
                                  onTap: () {
                                    rootScreenKey.currentState?.setState(() =>
                                        rootScreenKey
                                                .currentState?._selectedIndex =
                                            2); // Go to To-Do List
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 15),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                HapticFeedback.lightImpact();
                                await Navigator.of(context, rootNavigator: true)
                                    .push(
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const TodoDetailScreen();
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_task),
                              label: Text(s.addTask),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(120, 40),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Your Study Zone Card
                      _buildDashboardCard(
                        context,
                        title: s.yourStudyZone,
                        icon: Icons.lightbulb_outline,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.explore_outlined),
                            title: Text(s.exploreSubjects),
                            subtitle: Text(s.findNewMaterials),
                            trailing: Icon(Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                            onTap: () {
                              rootScreenKey.currentState?.setState(() =>
                                  rootScreenKey.currentState?._selectedIndex =
                                      1); // Go to Study tab
                            },
                          ),
                          Divider(
                              indent: 16,
                              endIndent: 16,
                              color: Theme.of(context)
                                  .dividerColor
                                  .withOpacity(0.2)),
                          ListTile(
                            leading: const Icon(Icons.add_circle_outline),
                            title: Text(s.createStudyGoal),
                            subtitle: Text(s.planYourNextTask),
                            trailing: Icon(Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6)),
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await Navigator.of(context, rootNavigator: true)
                                  .push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return const TodoDetailScreen();
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build consistent looking cards
  Widget _buildDashboardCard(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6, // Slightly higher elevation for modern look
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: 24, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

// NEW: Provider to handle first launch permission check
class FirstLaunchProvider with ChangeNotifier {
  static const String _hasShownPermissionKey = 'has_shown_permission_dialog';
  bool _hasShownPermissionDialog = false;

  FirstLaunchProvider() {
    _loadPermissionDialogState();
  }

  Future<void> _loadPermissionDialogState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasShownPermissionDialog = prefs.getBool(_hasShownPermissionKey) ?? false;
    notifyListeners();
  }

  Future<void> markPermissionDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasShownPermissionKey, true);
    _hasShownPermissionDialog = true;
    notifyListeners();
  }

  bool get hasShownPermissionDialog => _hasShownPermissionDialog;
}
