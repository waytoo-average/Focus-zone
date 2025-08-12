// lib/app_core.dart

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
import 'package:permission_handler/permission_handler.dart'; // For permissions in provider
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// App-specific feature imports
import 'package:app/l10n/app_localizations.dart';
import 'package:app/study_features.dart';
import 'package:app/todo_features.dart';
import 'package:app/settings_features.dart';
import 'package:app/zikr_features.dart';
import 'package:app/helper.dart';
import 'package:app/update_helper.dart';

// --- Surah Model and Loader ---
class Surah {
  final int number;
  final String name;
  final int ayahs;
  final String type;
  final int page;

  Surah({
    required this.number,
    required this.name,
    required this.ayahs,
    required this.type,
    required this.page,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'],
      name: json['name'],
      ayahs: json['ayahs'],
      type: json['type'],
      page: json['page'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'ayahs': ayahs,
      'type': type,
      'page': page,
    };
  }
}

class SurahLoader {
  static Future<List<Surah>> loadSurahs() async {
    final String jsonString =
        await rootBundle.loadString('lib/assets/surah_list.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => Surah.fromJson(json)).toList();
  }
}

// --- SnackBar Utilities ---
String formatBytesSimplified(int bytes, int decimals, AppLocalizations s) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB"];
  var i = (log(bytes) / log(1024)).floor();
  if (i >= suffixes.length) i = suffixes.length - 1;
  return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
}

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
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      action: action,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
    ),
  );
}

// --- Google API HTTP Client ---
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(this._headers));
  }
}

// --- Academic Context for Navigation ---
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

  String get displayGrade => grade;

  String get titleString {
    List<String> parts = [displayGrade];
    if (department != null) parts.add(department!);
    if (year != null) parts.add(year!);
    if (semester != null) parts.add(semester!);
    if (subjectName != null) parts.add(subjectName!);
    return parts.join(' > ');
  }

  String? getCanonicalGrade(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    if (grade == s.firstGrade) return 'First Grade';
    if (grade == s.secondGrade) return 'Second Grade';
    if (grade == s.thirdGrade) return 'Third Grade';
    if (grade == s.fourthGrade) return 'Fourth Grade';
    return null;
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

// --- Google Sign-In Provider ---
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
  }

  Future<void> initiateSilentSignIn() async {
    try {
      final wasSignedIn = await _googleSignIn.isSignedIn();
      if (wasSignedIn) {
        final account = await _googleSignIn.signInSilently();
        _currentUser = account;
      } else {
        _currentUser = null;
      }
    } catch (e, stack) {
      developer.log('Silent sign-in failed', error: e, stackTrace: stack);
      _currentUser = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        developer.log('User cancelled sign-in', name: 'SignInProvider');
      } else {
        developer.log('Signed in as ${account.displayName}',
            name: 'SignInProvider');
      }
    } catch (error, stack) {
      developer.log('Google Sign-In failed: $error',
          name: 'SignInProvider', error: error, stackTrace: stack);
    }
  }

  Future<void> signInWithErrorHandling(BuildContext context) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        developer.log('User cancelled sign-in', name: 'SignInProvider');
      } else {
        developer.log('Signed in as ${account.displayName}',
            name: 'SignInProvider');
      }
    } catch (error, stack) {
      developer.log('Google Sign-In failed: $error',
          name: 'SignInProvider', error: error, stackTrace: stack);

      // Check if the error is related to user limit or quota
      final errorString = error.toString().toLowerCase();
      if (errorString.contains('quota') ||
          errorString.contains('limit') ||
          errorString.contains('exceeded') ||
          errorString.contains('maximum') ||
          errorString.contains('user limit') ||
          errorString.contains('oauth') ||
          errorString.contains('403') ||
          errorString.contains('forbidden') ||
          errorString.contains('access denied') ||
          errorString.contains('too many requests') ||
          errorString.contains('rate limit')) {
        // Show maximum user limit error message
        if (context.mounted) {
          final s = AppLocalizations.of(context);
          if (s != null) {
            showAppSnackBar(
              context,
              s.maxUserLimitReached,
              icon: Icons.info_outline,
              iconColor: Colors.orange,
              backgroundColor: Colors.orange.shade700,
            );
          }
        }
      }
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
  String? _appSpecificDownloadPath;
  String? _customDownloadPath;
  bool _isRequestingPermission = false;

  DownloadPathProvider() {
    _initPaths();
  }

  Future<void> _initPaths() async {
    await _initAppSpecificDownloadPath();
    await _loadCustomDownloadPath();
    notifyListeners();
  }

  Future<void> _initAppSpecificDownloadPath() async {
    final directory = await getApplicationDocumentsDirectory();
    String baseDir = directory.path;
    final appDownloadDir = Directory('$baseDir/StudyStationDownloads');

    if (!await appDownloadDir.exists()) {
      try {
        await appDownloadDir.create(recursive: true);
        developer.log(
            "Created app-specific download directory: ${appDownloadDir.path}",
            name: "DownloadPathProvider");
      } catch (e) {
        developer.log("Error creating app-specific download directory: $e",
            name: "DownloadPathProvider");
      }
    }
    _appSpecificDownloadPath = appDownloadDir.path;
    developer.log(
        "Initialized app-specific download path: $_appSpecificDownloadPath",
        name: "DownloadPathProvider");
  }

  Future<void> _loadCustomDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    _customDownloadPath = prefs.getString(_kCustomDownloadPathKey);
    developer.log("Loaded custom download path: $_customDownloadPath",
        name: "DownloadPathProvider");
  }

  Future<void> setCustomDownloadPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_kCustomDownloadPathKey, path);
    } else {
      await prefs.remove(_kCustomDownloadPathKey);
    }
    _customDownloadPath = path;
    developer.log("Set custom download path: $_customDownloadPath",
        name: "DownloadPathProvider");
    notifyListeners();
  }

  Future<void> resetDownloadPath() async {
    await setCustomDownloadPath(null);
  }

  Future<String> getEffectiveDownloadPath() async {
    if (Platform.isIOS) {
      if (_appSpecificDownloadPath == null) {
        await _initAppSpecificDownloadPath();
      }
      return _appSpecificDownloadPath!;
    }

    if (_customDownloadPath != null && _customDownloadPath!.isNotEmpty) {
      final customDir = Directory(_customDownloadPath!);
      if (await customDir.exists()) {
        try {
          final testFile = File('${_customDownloadPath}/.test_write');
          await testFile.writeAsString('test');
          await testFile.delete();
          return _customDownloadPath!;
        } catch (e) {
          developer.log("Custom path not writable: $e",
              name: "DownloadPathProvider");
          await resetDownloadPath();
        }
      } else {
        developer.log(
            "Custom download path $_customDownloadPath does not exist. Resetting.",
            name: "DownloadPathProvider");
        await resetDownloadPath();
      }
    }

    if (_appSpecificDownloadPath == null) {
      await _initAppSpecificDownloadPath();
    }
    return _appSpecificDownloadPath!;
  }

  Future<bool> requestStoragePermissions(
      BuildContext context, AppLocalizations s) async {
    if (_isRequestingPermission) {
      return false;
    }
    _isRequestingPermission = true;

    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isGranted) {
          developer.log("MANAGE_EXTERNAL_STORAGE permission already granted.",
              name: "Permissions");
          return true;
        }

        final firstLaunchProvider =
            Provider.of<FirstLaunchProvider>(context, listen: false);
        if (!firstLaunchProvider.hasShownPermissionDialog) {
          if (context.mounted) {
            await showDialog(
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
                      onPressed: () => Navigator.of(dialogContext).pop(),
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
          }
          await firstLaunchProvider.markPermissionDialogShown();
          return false;
        } else {
          if (await Permission.manageExternalStorage.isGranted) {
            return true;
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.permissionDeniedForever),
                action: SnackBarAction(
                  label: s.settings,
                  onPressed: () => Permission.manageExternalStorage.request(),
                ),
              ),
            );
          }
          return false;
        }
      } else if (Platform.isIOS) {
        PermissionStatus photosStatus = await Permission.photos.request();
        return photosStatus.isGranted;
      }
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }
}

// --- RecentFile Model for Dashboard ---
class RecentFile {
  final String id;
  final String name;
  final String? url;
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
    _recentFiles.removeWhere((f) => f.id == file.id);
    _recentFiles.insert(0, file);
    if (_recentFiles.length > 5) {
      _recentFiles = _recentFiles.sublist(0, 5);
    }
    _saveRecentFiles();
    notifyListeners();
  }
}

// --- TodoSummaryProvider ---
class TodoSummaryProvider extends ChangeNotifier {
  static const _kTodosKey = 'todos';

  List<TodoItem> _allTodos = [];
  int _totalTasks = 0;
  int _completedToday = 0;
  int _overdueTasks = 0;
  TodoItem? _nextUpcomingTask;

  List<TodoItem> get allTodos => _allTodos;
  int get totalTasks => _totalTasks;
  int get completedToday => _completedToday;
  int get overdueTasks => _overdueTasks;
  TodoItem? get nextUpcomingTask => _nextUpcomingTask;

  TodoSummaryProvider() {
    _loadTodosAndSummary();
  }

  Future<void> _loadTodosAndSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosString = prefs.getString(_kTodosKey);
      if (todosString != null) {
        final List<dynamic> todoListJson = jsonDecode(todosString);
        _allTodos =
            todoListJson.map((json) => TodoItem.fromJson(json)).toList();
      } else {
        _allTodos = [];
      }
      _updateSummaryStats();
    } catch (e) {
      developer.log("TodoSummaryProvider Error loading todos: $e",
          name: "TodoSummaryProvider");
    } finally {
      notifyListeners();
    }
  }

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
    _nextUpcomingTask = null;
    DateTime? closestDueDate;
    for (var todo in _allTodos) {
      if (!todo.isCompleted && todo.dueDate != null) {
        DateTime taskDateTime;
        if (todo.dueTime != null) {
          taskDateTime = DateTime(todo.dueDate!.year, todo.dueDate!.month,
              todo.dueDate!.day, todo.dueTime!.hour, todo.dueTime!.minute);
        } else {
          taskDateTime = DateTime(
              todo.dueDate!.year, todo.dueDate!.month, todo.dueDate!.day);
        }
        if (taskDateTime.isAfter(now)) {
          if (closestDueDate == null || taskDateTime.isBefore(closestDueDate)) {
            closestDueDate = taskDateTime;
            _nextUpcomingTask = todo;
          }
        }
      }
    }
  }

  Future<void> saveTodo(TodoItem todoItem) async {
    int existingIndex =
        _allTodos.indexWhere((t) => t.creationDate == todoItem.creationDate);
    if (existingIndex != -1) {
      _allTodos[existingIndex] = todoItem;
    } else {
      _allTodos.add(todoItem);
    }
    await _persistTodos();
    notifyListeners();
  }

  Future<void> deleteTodo(TodoItem todoItem) async {
    _allTodos.removeWhere((t) => t.creationDate == todoItem.creationDate);
    await _persistTodos();
    notifyListeners();
  }

  Future<void> _persistTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String todosString =
          jsonEncode(_allTodos.map((todo) => todo.toJson()).toList());
      await prefs.setString(_kTodosKey, todosString);
      _updateSummaryStats();
    } catch (e) {
      developer.log("TodoSummaryProvider Error saving todos: $e",
          name: "TodoSummaryProvider");
    }
  }

  void refreshSummary() {
    _loadTodosAndSummary();
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
    _handleStartupLogic();
  }

  Future<void> _handleStartupLogic() async {
    final signInProvider = Provider.of<SignInProvider>(context, listen: false);
    await signInProvider.initiateSilentSignIn();

    // --- In-app update check ---
    final updateInfo = await UpdateHelper.checkForUpdate();
    if (updateInfo != null) {
      bool proceed = false;
      await showDialog(
        context: context,
        barrierDismissible: !updateInfo.mandatory,
        builder: (context) {
          double progress = 0;
          bool downloading = false;
          bool downloadComplete = false;
          String? downloadedPath;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Update Available'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'A new version (${updateInfo.latestVersion}) is available.'),
                    const SizedBox(height: 8),
                    Text(updateInfo.changelog),
                    if (downloading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 8),
                      Text(
                          'Downloading: ${(progress * 100).toStringAsFixed(0)}%'),
                    ],
                  ],
                ),
                actions: [
                  if (!downloading && !downloadComplete)
                    TextButton(
                      onPressed: updateInfo.mandatory
                          ? null
                          : () {
                              proceed = false;
                              Navigator.of(context).pop();
                            },
                      child: const Text('Skip'),
                    ),
                  if (!downloading && !downloadComplete)
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          downloading = true;
                        });
                        final path = await UpdateHelper.downloadApk(
                          updateInfo.apkUrl,
                          (p) => setState(() => progress = p),
                        );
                        if (path != null) {
                          setState(() {
                            downloadComplete = true;
                            downloadedPath = path;
                          });
                        } else {
                          setState(() {
                            downloading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Download failed. Please try again.')),
                          );
                        }
                      },
                      child: const Text('Update Now'),
                    ),
                  if (downloadComplete && downloadedPath != null)
                    ElevatedButton(
                      onPressed: () async {
                        await UpdateHelper.installApk(downloadedPath!);
                        proceed = true;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Install'),
                    ),
                ],
              );
            },
          );
        },
      );
      if (!proceed && updateInfo.mandatory) {
        // If update is mandatory and user didn't update, exit app
        SystemNavigator.pop();
        return;
      }
    }

    if (!mounted) return;
    await Navigator.pushReplacementNamed(context, '/rootScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: const Center(
        child: Text('Focus Zone',
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

// New RootScreen for Bottom Navigation Bar
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => RootScreenState();
}

class RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(), // Dashboard
    1: GlobalKey<NavigatorState>(), // Study
    2: GlobalKey<NavigatorState>(), // To-Do list
    3: GlobalKey<NavigatorState>(), // Zikr
    4: GlobalKey<NavigatorState>(), // Settings
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final downloadPathProvider =
        Provider.of<DownloadPathProvider>(context, listen: false);
    final firstLaunchProvider =
        Provider.of<FirstLaunchProvider>(context, listen: false);
    final s = AppLocalizations.of(context);
    if (s != null) {
      if (!firstLaunchProvider.hasShownPermissionDialog) {
        downloadPathProvider.requestStoragePermissions(context, s);
      }
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      Future.microtask(() {
        _navigatorKeys[index]?.currentState?.popUntil((route) => route.isFirst);
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildOffstageNavigator(int index, Widget initialRouteWidget) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          if (routeSettings.name == '/') {
            return MaterialPageRoute(builder: (context) => initialRouteWidget);
          }
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
                              "Missing context."));
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
                              "Missing context."));
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
                              "Missing context."));
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
                            "Missing subject details."));
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
    Provider.of<LanguageProvider>(context);
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
            _buildOffstageNavigator(3, const ZikrScreen()),
            _buildOffstageNavigator(4, const SettingsScreen()),
          ],
        ),
        bottomNavigationBar: Directionality(
          textDirection: TextDirection.ltr,
          child: BottomNavigationBar(
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
                icon: const Icon(Icons.mosque_outlined),
                activeIcon: const Icon(Icons.mosque),
                label: s.zikr,
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
      ),
    );
  }
}

// Dashboard Screen
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
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            snap: false,
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 16.0),
              child: Opacity(
                opacity: user != null ? 1.0 : 0.0,
                child: CircleAvatar(
                  radius: 20,
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
              titlePadding: const EdgeInsets.only(bottom: 16.0),
              centerTitle: true,
              title: Text(
                'Focus Zone',
                style: Theme.of(context)
                    .appBarTheme
                    .titleTextStyle
                    ?.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
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
              ),
            ),
            actions: [
              if (user == null)
                TextButton(
                  onPressed: () =>
                      signInProvider.signInWithErrorHandling(context),
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
                                recentFilesProvider.recentFiles.length)),
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
                                    rootScreenKey.currentState
                                        ?._onItemTapped(2);
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
                                    rootScreenKey.currentState
                                        ?._onItemTapped(2);
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
                              rootScreenKey.currentState?._onItemTapped(1);
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
      elevation: 6,
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

// Provider to handle first launch permission check
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

// --- UserInfoProvider for feedback user info state ---
class UserInfoProvider with ChangeNotifier {
  static const String _hasSeenUserInfoScreenKey = 'has_seen_user_info_screen';
  static const String _userNameKey = 'user_info_name';
  static const String _userPhoneKey = 'user_info_phone';

  bool _hasSeenUserInfoScreen = false;
  String? _userName;
  String? _userPhone;

  UserInfoProvider() {
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenUserInfoScreen = prefs.getBool(_hasSeenUserInfoScreenKey) ?? false;
    _userName = prefs.getString(_userNameKey);
    _userPhone = prefs.getString(_userPhoneKey);
    notifyListeners();
  }

  Future<void> setUserInfo({String? name, String? phone}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString(_userNameKey, name);
      _userName = name;
    }
    if (phone != null) {
      await prefs.setString(_userPhoneKey, phone);
      _userPhone = phone;
    }
    notifyListeners();
  }

  Future<void> markUserInfoScreenSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenUserInfoScreenKey, true);
    _hasSeenUserInfoScreen = true;
    notifyListeners();
  }

  bool get hasSeenUserInfoScreen => _hasSeenUserInfoScreen;
  String? get userName => _userName;
  String? get userPhone => _userPhone;

  Future<void> resetUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userNameKey);
    await prefs.remove(_userPhoneKey);
    _userName = null;
    _userPhone = null;
    notifyListeners();
  }
}

// --- User feedback local storage ---
class UserFeedbackItem {
  final String content;
  final DateTime submittedAt;

  UserFeedbackItem({required this.content, required this.submittedAt});

  Map<String, dynamic> toJson() => {
        'content': content,
        'submittedAt': submittedAt.toIso8601String(),
      };

  factory UserFeedbackItem.fromJson(Map<String, dynamic> json) =>
      UserFeedbackItem(
        content: json['content'] as String,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );
}

class UserFeedbackProvider with ChangeNotifier {
  static const String _kUserFeedbackListKey = 'user_feedback_list';

  List<UserFeedbackItem> _feedbackItems = [];
  List<UserFeedbackItem> get feedbackItems => List.unmodifiable(_feedbackItems);

  UserFeedbackProvider() {
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserFeedbackListKey);
    if (raw != null) {
      final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
      _feedbackItems = jsonList
          .map((e) => UserFeedbackItem.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    }
    notifyListeners();
  }

  Future<void> _persistFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        jsonEncode(_feedbackItems.map((e) => e.toJson()).toList());
    await prefs.setString(_kUserFeedbackListKey, jsonString);
  }

  Future<void> addFeedback(String content) async {
    final item =
        UserFeedbackItem(content: content, submittedAt: DateTime.now());
    _feedbackItems.insert(0, item);
    await _persistFeedback();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _feedbackItems.clear();
    await _persistFeedback();
    notifyListeners();
  }
}

class DeveloperSuggestionComment {
  final String id;
  String content;
  DateTime createdAt;
  DateTime? updatedAt;

  DeveloperSuggestionComment({
    required this.id,
    required this.content,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory DeveloperSuggestionComment.fromJson(Map<String, dynamic> json) =>
      DeveloperSuggestionComment(
        id: json['id'] as String,
        content: json['content'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: (json['updatedAt'] as String?) != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}

class DeveloperSuggestionState {
  // vote: -1 = dislike, 0 = neutral, 1 = like
  int vote;
  List<DeveloperSuggestionComment> comments;

  DeveloperSuggestionState(
      {this.vote = 0, List<DeveloperSuggestionComment>? comments})
      : comments = comments ?? [];

  Map<String, dynamic> toJson() => {
        'vote': vote,
        'comments': comments.map((c) => c.toJson()).toList(),
      };

  factory DeveloperSuggestionState.fromJson(Map<String, dynamic> json) {
    final rawComments = json['comments'];
    List<DeveloperSuggestionComment> parsedComments = [];
    if (rawComments is List) {
      // Migration support: either list of objects or list of strings
      if (rawComments.isNotEmpty && rawComments.first is Map) {
        parsedComments = rawComments
            .map((e) => DeveloperSuggestionComment.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList();
      } else {
        // Legacy strings
        parsedComments = rawComments
            .map((e) => DeveloperSuggestionComment(
                  id: UniqueKey().toString(),
                  content: e.toString(),
                ))
            .toList();
      }
    }
    return DeveloperSuggestionState(
      vote: (json['vote'] as int?) ?? 0,
      comments: parsedComments,
    );
  }
}

class DeveloperSuggestionsProvider with ChangeNotifier {
  static const String _kSuggestionsStateKey = 'developer_suggestions_state';

  // suggestionId -> state
  Map<String, DeveloperSuggestionState> _stateById = {};

  DeveloperSuggestionState stateFor(String id) {
    return _stateById[id] ?? DeveloperSuggestionState();
  }

  DeveloperSuggestionsProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSuggestionsStateKey);
    if (raw != null) {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      _stateById = map.map(
        (key, value) => MapEntry(
          key,
          DeveloperSuggestionState.fromJson(value as Map<String, dynamic>),
        ),
      );
    }
    notifyListeners();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _stateById.map((k, v) => MapEntry(k, v.toJson())),
    );
    await prefs.setString(_kSuggestionsStateKey, jsonString);
  }

  Future<void> setVote(String id, int vote) async {
    final current = stateFor(id);
    // Toggle off if same vote clicked again
    if (current.vote == vote) {
      current.vote = 0;
    } else {
      current.vote = vote.clamp(-1, 1);
    }
    _stateById[id] = current;
    await _persistState();
    notifyListeners();
  }

  Future<void> addComment(String id, String comment) async {
    if (comment.trim().isEmpty) return;
    final current = stateFor(id);
    current.comments.insert(
      0,
      DeveloperSuggestionComment(
        id: UniqueKey().toString(),
        content: comment.trim(),
      ),
    );
    _stateById[id] = current;
    await _persistState();
    notifyListeners();
  }

  Future<void> editComment(
      String id, String commentId, String newContent) async {
    final current = stateFor(id);
    final idx = current.comments.indexWhere((c) => c.id == commentId);
    if (idx != -1) {
      current.comments[idx].content = newContent.trim();
      current.comments[idx].updatedAt = DateTime.now();
      _stateById[id] = current;
      await _persistState();
      notifyListeners();
    }
  }

  Future<void> deleteComment(String id, String commentId) async {
    final current = stateFor(id);
    current.comments.removeWhere((c) => c.id == commentId);
    _stateById[id] = current;
    await _persistState();
    notifyListeners();
  }
}
