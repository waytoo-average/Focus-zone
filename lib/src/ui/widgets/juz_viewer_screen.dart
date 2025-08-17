import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'surah_list_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import '../../utils/download_manager_v3.dart' as new_dm;
import '../../utils/app_animations.dart';

enum ScrollDirection { horizontal, vertical }

// Advanced per-page visit tracking
class PageVisit {
  final int pageNumber;
  final DateTime enterTime;
  DateTime? leaveTime;

  PageVisit(
      {required this.pageNumber, required this.enterTime, this.leaveTime});

  Duration get duration => (leaveTime ?? DateTime.now()).difference(enterTime);
}

class JuzViewerScreen extends StatefulWidget {
  final int juzNumber;
  final bool isWholeQuran;
  final bool isDownloadedJuzsOnly;
  final int? initialPage;
  final int? initialGlobalPage;
  const JuzViewerScreen({
    Key? key,
    required this.juzNumber,
    this.isWholeQuran = false,
    this.isDownloadedJuzsOnly = false,
    this.initialPage,
    this.initialGlobalPage,
  }) : super(key: key);

  @override
  State<JuzViewerScreen> createState() => _JuzViewerScreenState();
}

class _JuzViewerScreenState extends State<JuzViewerScreen> {
  List<File> _images = [];
  bool _loading = true;
  late final PageController _pageController;
  int _currentPage = 0;
  bool _initialPageSet = false;
  Set<int> _bookmarks = {};

  // Reading settings
  bool _isNightMode = false;
  bool _isTimerRunning = false;
  bool _isAutoScrollEnabled = false;
  int _autoScrollSpeed = 5; // seconds per page
  int _readingTimeSeconds = 0;
  Timer? _timer;
  Timer? _autoScrollTimer;

  // Reading analytics
  DateTime? _sessionStartTime;
  int _sessionStartPage = 0;
  int _dailyGoalMinutes = 30;
  int _weeklyGoalPages = 50;
  List<ReadingSession> _readingSessions = [];
  Map<String, int> _dailyReadingMinutes = {};
  Map<String, int> _dailyReadingPages = {};

  // Advanced analytics: track all page visits in the current session
  List<PageVisit> _pageVisits = [];

  ScrollDirection _scrollDirection = ScrollDirection.horizontal;

  // Minimum time (seconds) to count a page as 'read' (user-configurable)
  int _minPageReadSeconds = 60;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage ?? 0);
    _pageController.addListener(_onPageChanged);
    _loadImages();
    _loadBookmarks();
    _loadReadingSettings();
    _loadReadingAnalytics();
    _pageVisits = [];
  }

  String get _prefsKey => widget.isWholeQuran
      ? 'quran_last_page_full'
      : 'quran_last_page_juz_${widget.juzNumber}';
  String get _bookmarksKey => widget.isWholeQuran
      ? 'quran_bookmarks_full'
      : 'quran_bookmarks_juz_${widget.juzNumber}';
  String get _settingsKey => widget.isWholeQuran
      ? 'quran_settings_full'
      : 'quran_settings_juz_${widget.juzNumber}';
  String get _analyticsKey => widget.isWholeQuran
      ? 'quran_analytics_full'
      : 'quran_analytics_juz_${widget.juzNumber}';

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_bookmarksKey) ?? [];
    setState(() {
      _bookmarks =
          list.map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0).toSet();
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final isBookmarked = _bookmarks.contains(_currentPage);
    setState(() {
      if (isBookmarked) {
        _bookmarks.remove(_currentPage);
      } else {
        _bookmarks.add(_currentPage);
      }
    });
    await prefs.setStringList(
        _bookmarksKey, _bookmarks.map((e) => e.toString()).toList());
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final sortedBookmarks = _bookmarks.toList()..sort();
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bookmarks (${_bookmarks.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (sortedBookmarks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'No bookmarks yet. Tap the bookmark icon to add one.'),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedBookmarks.length,
                    itemBuilder: (context, index) {
                      final pageIndex = sortedBookmarks[index];
                      final pageNumber = pageIndex + 1;
                      final isCurrentPage = pageIndex == _currentPage;
                      return ListTile(
                        leading: Icon(
                          Icons.bookmark,
                          color: isCurrentPage
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        title: Text('Page $pageNumber'),
                        subtitle:
                            isCurrentPage ? const Text('Current page') : null,
                        trailing:
                            isCurrentPage ? const Icon(Icons.check) : null,
                        onTap: () {
                          Navigator.of(context).pop();
                          _jumpToPage(pageIndex);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool get _isCurrentPageBookmarked => _bookmarks.contains(_currentPage);

  Future<void> _setInitialPage() async {
    if (_initialPageSet || _images.isEmpty) return;
    int page = 0;
    if (widget.initialGlobalPage != null) {
      // Find the index in _images whose filename matches the global page number
      final idx = _images.indexWhere(
          (f) => _extractPageNumber(f.path) == widget.initialGlobalPage);
      if (idx != -1) {
        page = idx;
      }
    } else if (widget.initialPage != null &&
        widget.initialPage! >= 0 &&
        widget.initialPage! < _images.length) {
      page = widget.initialPage!;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final savedPage = prefs.getInt(_prefsKey) ?? 0;
      page = (savedPage >= 0 && savedPage < _images.length) ? savedPage : 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageController.hasClients) {
        _pageController.jumpToPage(page);
      }
    });
    setState(() {
      _currentPage = page;
      _initialPageSet = true;
    });
  }

  Future<void> _saveCurrentPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, page);
  }

  void _onPageChanged() {
    if (!_isTimerRunning) return; // Only track if timer/session is running
    final newPage =
        _pageController.hasClients ? _pageController.page?.round() ?? 0 : 0;
    if (newPage != _currentPage) {
      // Advanced analytics: finalize previous PageVisit
      if (_pageVisits.isNotEmpty && _pageVisits.last.leaveTime == null) {
        _pageVisits.last.leaveTime = DateTime.now();
      }
      // Start a new PageVisit for the new page
      _pageVisits
          .add(PageVisit(pageNumber: newPage, enterTime: DateTime.now()));
      setState(() {
        _currentPage = newPage;
      });
      _saveCurrentPage(newPage);
    }
  }

  @override
  void dispose() {
    // Advanced analytics: finalize last PageVisit if needed
    if (_pageVisits.isNotEmpty && _pageVisits.last.leaveTime == null) {
      _pageVisits.last.leaveTime = DateTime.now();
    }
    _endReadingSession();
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    _timer?.cancel();
    _stopAutoScroll();
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    final dir = await getApplicationDocumentsDirectory();
    if (widget.isWholeQuran) {
      // Aggregate images from all Juz folders
      List<File> allImages = [];
      for (int juz = 1; juz <= 30; juz++) {
        final juzDir = Directory('${dir.path}/quran_juz_$juz');
        if (juzDir.existsSync()) {
          final files = juzDir
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.endsWith('.jpg') ||
                  f.path.endsWith('.jpeg') ||
                  f.path.endsWith('.png'))
              .toList();
          allImages.addAll(files);
        }
      }
      // Sort all images by page number
      allImages.sort((a, b) {
        final aPage = _extractPageNumber(a.path);
        final bPage = _extractPageNumber(b.path);
        return aPage.compareTo(bPage);
      });
      setState(() {
        _images = allImages;
        _loading = false;
        _initialPageSet = false;
      });
      await _setInitialPage();
    } else if (widget.isDownloadedJuzsOnly) {
      // Aggregate images from all downloaded Juz folders in order
      List<File> allImages = [];

      // Get downloaded Juzs in order (1, 2, 3, etc.)
      List<int> downloadedJuzs = [];
      for (int juz = 1; juz <= 30; juz++) {
        // Check if Juz is downloaded by looking at the directory
        final juzDir = Directory('${dir.path}/quran_juz_$juz');
        if (juzDir.existsSync()) {
          final files = juzDir.listSync().whereType<File>().toList();
          if (files.isNotEmpty) {
            downloadedJuzs.add(juz);
          }
        }
      }

      // Load images from each Juz in order
      for (int juz in downloadedJuzs) {
        final juzDir = Directory('${dir.path}/quran_juz_$juz');
        if (juzDir.existsSync()) {
          final files = juzDir
              .listSync()
              .whereType<File>()
              .where((f) =>
                  f.path.endsWith('.jpg') ||
                  f.path.endsWith('.jpeg') ||
                  f.path.endsWith('.png'))
              .toList();
          // Sort files within this Juz by page number
          files.sort((a, b) {
            final aPage = _extractPageNumber(a.path);
            final bPage = _extractPageNumber(b.path);
            return aPage.compareTo(bPage);
          });
          allImages.addAll(files);
        }
      }

      setState(() {
        _images = allImages;
        _loading = false;
        _initialPageSet = false;
      });
      await _setInitialPage();
    } else {
      // Single Juz
      final targetDir = Directory('${dir.path}/quran_juz_${widget.juzNumber}');
      if (targetDir.existsSync()) {
        final files = targetDir
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.path.endsWith('.jpg') ||
                f.path.endsWith('.jpeg') ||
                f.path.endsWith('.png'))
            .toList();
        files.sort((a, b) {
          final aPage = _extractPageNumber(a.path);
          final bPage = _extractPageNumber(b.path);
          return aPage.compareTo(bPage);
        });
        setState(() {
          _images = files;
          _loading = false;
          _initialPageSet = false;
        });
        await _setInitialPage();
      } else {
        setState(() {
          _images = [];
          _loading = false;
        });
      }
    }
  }

  // Extract page number from filename
  int _extractPageNumber(String filePath) {
    final fileName = filePath.split('/').last;
    final nameWithoutExt = fileName.split('.').first;

    // Handle the specific format: big-quran_Page_001
    final pageMatch =
        RegExp(r'Page_(\d+)', caseSensitive: false).firstMatch(nameWithoutExt);
    if (pageMatch != null) {
      return int.tryParse(pageMatch.group(1) ?? '0') ?? 0;
    }

    // Fallback: try to extract any numbers from the filename
    final numbers = RegExp(r'\d+').allMatches(nameWithoutExt);
    if (numbers.isNotEmpty) {
      // Use the first number found as page number
      return int.tryParse(numbers.first.group(0) ?? '0') ?? 0;
    }

    // Final fallback to alphabetical sorting if no numbers found
    return 0;
  }

  Future<void> _loadReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNightMode = prefs.getBool('${_settingsKey}_night_mode') ?? false;
      _autoScrollSpeed = prefs.getInt('${_settingsKey}_auto_scroll_speed') ?? 5;
      final dir = prefs.getString('${_settingsKey}_scroll_direction');
      if (dir == 'vertical') {
        _scrollDirection = ScrollDirection.vertical;
      } else {
        _scrollDirection = ScrollDirection.horizontal;
      }
      _minPageReadSeconds =
          prefs.getInt('${_settingsKey}_min_page_read_seconds') ?? 60;
    });
  }

  Future<void> _saveReadingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_settingsKey}_night_mode', _isNightMode);
    await prefs.setInt('${_settingsKey}_auto_scroll_speed', _autoScrollSpeed);
    await prefs.setString(
        '${_settingsKey}_scroll_direction',
        _scrollDirection == ScrollDirection.vertical
            ? 'vertical'
            : 'horizontal');
    await prefs.setInt(
        '${_settingsKey}_min_page_read_seconds', _minPageReadSeconds);
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
    _saveReadingSettings();
  }

  void _toggleTimer() {
    setState(() {
      _isTimerRunning = !_isTimerRunning;
    });

    if (_isTimerRunning) {
      _startReadingSession();
      _pageVisits = [];
      // Start tracking the current page as the first visit
      _pageVisits
          .add(PageVisit(pageNumber: _currentPage, enterTime: DateTime.now()));
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _readingTimeSeconds++;
        });
      });
    } else {
      _endReadingSession();
      _timer?.cancel();
      _timer = null;
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isTimerRunning = false;
      _readingTimeSeconds = 0;
    });
  }

  void _toggleAutoScroll([bool? value]) {
    setState(() {
      _isAutoScrollEnabled = value ?? !_isAutoScrollEnabled;
    });
    if (_isAutoScrollEnabled) {
      _stopAutoScroll();
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
  }

  void _setAutoScrollSpeed(int speed) {
    setState(() {
      _autoScrollSpeed = speed;
    });
    _saveReadingSettings();
    if (_isAutoScrollEnabled) {
      _stopAutoScroll();
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer =
        Timer.periodic(Duration(seconds: _autoScrollSpeed), (timer) {
      if (_currentPage < _images.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _stopAutoScroll();
        setState(() {
          _isAutoScrollEnabled = false;
        });
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showReadingSettings() {
    final s = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.readingSettings,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Night Mode
                  SwitchListTile(
                    title: Text(s.nightMode),
                    subtitle: Text(s.nightModeSubtitle),
                    value: _isNightMode,
                    onChanged: (value) {
                      _toggleNightMode();
                      setSheetState(() {});
                    },
                  ),
                  // Scroll Direction
                  ListTile(
                    title: Text(s.scrollDirection),
                    subtitle: Row(
                      children: [
                        Radio<ScrollDirection>(
                          value: ScrollDirection.horizontal,
                          groupValue: _scrollDirection,
                          onChanged: (val) {
                            setState(() => _scrollDirection = val!);
                            setSheetState(() {});
                            _saveReadingSettings();
                          },
                        ),
                        Text(s.horizontal),
                        const SizedBox(width: 16),
                        Radio<ScrollDirection>(
                          value: ScrollDirection.vertical,
                          groupValue: _scrollDirection,
                          onChanged: (val) {
                            setState(() => _scrollDirection = val!);
                            setSheetState(() {});
                            _saveReadingSettings();
                          },
                        ),
                        Text(s.vertical),
                      ],
                    ),
                  ),
                  // Reading Timer
                  ListTile(
                    title: Text(s.readingTimer),
                    subtitle:
                        Text('Running: ${_formatTime(_readingTimeSeconds)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                              _isTimerRunning ? Icons.pause : Icons.play_arrow),
                          onPressed: () {
                            _toggleTimer();
                            setSheetState(() {});
                          },
                        ),
                        if (_readingTimeSeconds > 0)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () {
                              _resetTimer();
                              setSheetState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  // Auto Scroll
                  SwitchListTile(
                    title: Text(s.autoScroll),
                    subtitle: Text('Enabled (${_autoScrollSpeed}s/page)'),
                    value: _isAutoScrollEnabled,
                    onChanged: (value) {
                      _toggleAutoScroll(value);
                      setSheetState(() {});
                    },
                  ),
                  if (_isAutoScrollEnabled) ...[
                    ListTile(
                      title: Text(s.scrollSpeed),
                      subtitle: Text('${_autoScrollSpeed} seconds per page'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _autoScrollSpeed > 1
                                ? () {
                                    _setAutoScrollSpeed(_autoScrollSpeed - 1);
                                    setSheetState(() {});
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _autoScrollSpeed < 30
                                ? () {
                                    _setAutoScrollSpeed(_autoScrollSpeed + 1);
                                    setSheetState(() {});
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Minimum Page Read Time
                  ListTile(
                    title: Text(s.minTimeToCountPage),
                    subtitle: Text('${_minPageReadSeconds} seconds'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _minPageReadSeconds > 5
                              ? () {
                                  setState(() => _minPageReadSeconds -= 5);
                                  setSheetState(() {});
                                  _saveReadingSettings();
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _minPageReadSeconds < 600
                              ? () {
                                  setState(() => _minPageReadSeconds += 5);
                                  setSheetState(() {});
                                  _saveReadingSettings();
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadReadingAnalytics() async {
    final prefs = await SharedPreferences.getInstance();

    // Load reading sessions
    final sessionsJson = prefs.getString('${_analyticsKey}_sessions') ?? '[]';
    final sessionsList = json.decode(sessionsJson) as List;
    _readingSessions =
        sessionsList.map((json) => ReadingSession.fromJson(json)).toList();

    // Load daily statistics
    final dailyMinutesJson =
        prefs.getString('${_analyticsKey}_daily_minutes') ?? '{}';
    final dailyPagesJson =
        prefs.getString('${_analyticsKey}_daily_pages') ?? '{}';
    _dailyReadingMinutes = Map<String, int>.from(json.decode(dailyMinutesJson));
    _dailyReadingPages = Map<String, int>.from(json.decode(dailyPagesJson));

    // Load goals
    _dailyGoalMinutes =
        prefs.getInt('${_analyticsKey}_daily_goal_minutes') ?? 30;
    _weeklyGoalPages = prefs.getInt('${_analyticsKey}_weekly_goal_pages') ?? 50;
  }

  Future<void> _saveReadingAnalytics() async {
    final prefs = await SharedPreferences.getInstance();

    // Save reading sessions
    final sessionsJson = json
        .encode(_readingSessions.map((session) => session.toJson()).toList());
    await prefs.setString('${_analyticsKey}_sessions', sessionsJson);

    // Save daily statistics
    await prefs.setString(
        '${_analyticsKey}_daily_minutes', json.encode(_dailyReadingMinutes));
    await prefs.setString(
        '${_analyticsKey}_daily_pages', json.encode(_dailyReadingPages));

    // Save goals
    await prefs.setInt(
        '${_analyticsKey}_daily_goal_minutes', _dailyGoalMinutes);
    await prefs.setInt('${_analyticsKey}_weekly_goal_pages', _weeklyGoalPages);
  }

  void _startReadingSession() {
    _sessionStartTime = DateTime.now();
    _sessionStartPage = _currentPage;
  }

  void _endReadingSession() {
    // Advanced analytics: finalize last PageVisit if needed
    if (_pageVisits.isNotEmpty && _pageVisits.last.leaveTime == null) {
      _pageVisits.last.leaveTime = DateTime.now();
    }
    // Advanced analytics: count pages read using threshold
    final pagesRead = _pageVisits
        .where((visit) => visit.duration.inSeconds >= _minPageReadSeconds)
        .map((visit) => visit.pageNumber)
        .toSet()
        .length;
    final sessionDuration = _pageVisits
        .fold<Duration>(
          Duration.zero,
          (sum, visit) => sum + visit.duration,
        )
        .inSeconds;
    if (_sessionStartTime != null) {
      // Use new pagesRead and sessionDuration for analytics
      final session = ReadingSession(
        date: DateTime.now(),
        durationMinutes: (sessionDuration / 60).round(),
        pagesRead: pagesRead,
        juzNumber: widget.juzNumber,
        isWholeQuran: widget.isWholeQuran,
      );
      _readingSessions.add(session);
      _updateDailyStatistics(session);
      _saveReadingAnalytics();
    }
    _sessionStartTime = null;
    _sessionStartPage = 0;
    _pageVisits = [];
  }

  void _updateDailyStatistics(ReadingSession session) {
    final dateKey = DateFormat('yyyy-MM-dd').format(session.date);

    _dailyReadingMinutes[dateKey] =
        (_dailyReadingMinutes[dateKey] ?? 0) + session.durationMinutes;
    _dailyReadingPages[dateKey] =
        (_dailyReadingPages[dateKey] ?? 0) + session.pagesRead;
  }

  int _getCurrentStreak() {
    if (_dailyReadingMinutes.isEmpty) return 0;

    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      if (_dailyReadingMinutes.containsKey(dateKey) &&
          _dailyReadingMinutes[dateKey]! > 0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int _getTodayReadingMinutes() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _dailyReadingMinutes[today] ?? 0;
  }

  int _getTodayReadingPages() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _dailyReadingPages[today] ?? 0;
  }

  int _getWeeklyReadingPages() {
    final today = DateTime.now();
    int weeklyPages = 0;

    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      weeklyPages += _dailyReadingPages[dateKey] ?? 0;
    }

    return weeklyPages;
  }

  double _getDailyGoalProgress() {
    final todayMinutes = _getTodayReadingMinutes();
    return todayMinutes / _dailyGoalMinutes;
  }

  double _getWeeklyGoalProgress() {
    final weeklyPages = _getWeeklyReadingPages();
    return weeklyPages / _weeklyGoalPages;
  }

  void _showReadingAnalytics() {
    final s = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final currentStreak = _getCurrentStreak();
        final todayMinutes = _getTodayReadingMinutes();
        final todayPages = _getTodayReadingPages();
        final weeklyPages = _getWeeklyReadingPages();
        final dailyProgress = _getDailyGoalProgress();
        final weeklyProgress = _getWeeklyGoalProgress();

        // Advanced stats for current session
        final readVisits = _pageVisits
            .where((v) => v.duration.inSeconds >= _minPageReadSeconds)
            .toList();
        final avgTimePerPage = readVisits.isNotEmpty
            ? readVisits
                    .map((v) => v.duration.inSeconds)
                    .reduce((a, b) => a + b) /
                readVisits.length
            : 0.0;
        final mostRead = readVisits.isNotEmpty
            ? readVisits.reduce((a, b) => a.duration > b.duration ? a : b)
            : null;
        final leastRead = readVisits.isNotEmpty
            ? readVisits.reduce((a, b) => a.duration < b.duration ? a : b)
            : null;

        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.readingAnalytics,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Section: Streaks
                Text(s.streaks, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: CircularProgressIndicator(
                                      value:
                                          (currentStreak / 30).clamp(0.0, 1.0),
                                      strokeWidth: 7,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        currentStreak >= 30
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.local_fire_department,
                                          color: Colors.orange, size: 28),
                                      Text('$currentStreak',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(s.dayStreak,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.today,
                                  color: Colors.blue, size: 32),
                              const SizedBox(height: 8),
                              Text('$todayMinutes min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue)),
                              Text(s.today,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Section: Goals
                Text(s.goals, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.dailyGoal,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text('${(dailyProgress * 100).toInt()}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: dailyProgress >= 1.0
                                            ? Colors.green
                                            : Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: dailyProgress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              dailyProgress >= 1.0
                                  ? Colors.green
                                  : Colors.orange),
                          minHeight: 10,
                        ),
                        const SizedBox(height: 4),
                        Text('$todayMinutes / $_dailyGoalMinutes minutes',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.weeklyGoal,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text('${(weeklyProgress * 100).toInt()}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        color: weeklyProgress >= 1.0
                                            ? Colors.green
                                            : Colors.orange)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: weeklyProgress.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              weeklyProgress >= 1.0
                                  ? Colors.green
                                  : Colors.orange),
                          minHeight: 10,
                        ),
                        const SizedBox(height: 4),
                        Text('$weeklyPages / $_weeklyGoalPages pages',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        ListTile(
                          title: Text(s.setDailyGoal),
                          subtitle: Text('$_dailyGoalMinutes minutes'),
                          trailing: const Icon(Icons.edit),
                          onTap: () => _showGoalSettings(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Section: Actionable Insights
                Text(s.insights,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final today = DateTime.now();
                    // 1. Weekend vs weekday reading
                    int weekdayTotal = 0, weekendTotal = 0;
                    for (int i = 0; i < 7; i++) {
                      final date = today.subtract(Duration(days: i));
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final p = _dailyReadingPages[key] ?? 0;
                      if (date.weekday == 6 || date.weekday == 7) {
                        weekendTotal += p;
                      } else {
                        weekdayTotal += p;
                      }
                    }
                    String tip1 = '';
                    if (weekendTotal > weekdayTotal) {
                      tip1 = s.weekendReadingTip;
                    } else if (weekdayTotal > weekendTotal) {
                      tip1 = s.weekdayReadingTip;
                    }
                    // 2. Streak encouragement
                    String tip2 = '';
                    if (currentStreak >= 7) {
                      tip2 =
                          'Great! Keep your $currentStreak-day streak going!';
                    } else if (currentStreak >= 3) {
                      tip2 =
                          'Great! Keep your $currentStreak-day streak going!';
                    } else if (currentStreak == 0) {
                      tip2 = s.startStreakTip;
                    }
                    // 3. Weekly goal encouragement
                    String tip3 = '';
                    if (weeklyProgress >= 1.0) {
                      tip3 = s.weeklyGoalAchievedTip;
                    } else if (weeklyProgress >= 0.7) {
                      tip3 = s.closeWeeklyGoalTip;
                    }
                    // 4. Daily goal count
                    int daysGoalMet = 0;
                    for (int i = 0; i < 7; i++) {
                      final date = today.subtract(Duration(days: i));
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final mins = _dailyReadingMinutes[key] ?? 0;
                      if (mins >= _dailyGoalMinutes) daysGoalMet++;
                    }
                    String tip4 = '';
                    if (daysGoalMet >= 5) {
                      tip4 =
                          'You met your daily goal $daysGoalMet times this week!';
                    }
                    final tips = [tip1, tip2, tip3, tip4]
                        .where((t) => t.isNotEmpty)
                        .toList();
                    if (tips.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(s.noInsights),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: tips
                          .map((t) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb,
                                        color: Colors.amber, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(t)),
                                  ],
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Section: Session Insights
                Text(s.sessionInsights,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (readVisits.isNotEmpty) ...[
                  Card(
                    color: Colors.blueGrey[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Average time per page: ${avgTimePerPage.toStringAsFixed(1)} seconds'),
                          if (mostRead != null)
                            Text(
                                'Most read page: ${mostRead.pageNumber + 1} (${mostRead.duration.inSeconds} seconds)'),
                          if (leastRead != null)
                            Text(
                                'Least read page: ${leastRead.pageNumber + 1} (${leastRead.duration.inSeconds} seconds)'),
                          Text('Unique pages read: ${readVisits.length}'),
                          Text(
                              'Total time reading: ${readVisits.map((v) => v.duration.inSeconds).reduce((a, b) => a + b)} seconds'),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.noSessionData),
                  ),
                ],
                const SizedBox(height: 24),
                // Section: History (bar chart)
                Text(s.history, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    // Prepare last 7 days data
                    final today = DateTime.now();
                    List<int> pages = [];
                    List<String> labels = [];
                    int maxPages = 1;
                    for (int i = 6; i >= 0; i--) {
                      final date = today.subtract(Duration(days: i));
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final p = _dailyReadingPages[key] ?? 0;
                      pages.add(p);
                      labels.add(DateFormat('E').format(date).substring(0, 1));
                      if (p > maxPages) maxPages = p;
                    }
                    return Card(
                      color: const Color(0xFFF5F5F5),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.pagesReadLast7Days,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _BarChart(
                                values: pages,
                                labels: labels,
                                maxValue: maxPages),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Recent Sessions List
                Text(s.recentSessions,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_readingSessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.noReadingSessions),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _readingSessions.length > 10
                          ? 10
                          : _readingSessions.length,
                      itemBuilder: (context, i) {
                        final session =
                            _readingSessions[_readingSessions.length - 1 - i];
                        final dateStr = DateFormat('MMM d, yyyy – h:mm a')
                            .format(session.date);
                        final goalMet =
                            session.durationMinutes >= _dailyGoalMinutes;
                        return ListTile(
                          leading: Icon(
                            goalMet ? Icons.emoji_events : Icons.book,
                            color: goalMet ? Colors.amber : Colors.blueGrey,
                          ),
                          title: Text(
                              '${session.pagesRead} pages, ${session.durationMinutes} min'),
                          subtitle: Text(
                              '${session.isWholeQuran ? s.fullQuran : 'Juz ${widget.juzNumber}'}\n$dateStr'),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGoalSettings() {
    final s = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) {
        int tempDailyGoal = _dailyGoalMinutes;
        int tempWeeklyGoal = _weeklyGoalPages;

        return AlertDialog(
          title: Text(s.readingGoals),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Daily Goal (minutes)'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: tempDailyGoal > 5
                          ? () {
                              tempDailyGoal -= 5;
                              (context as Element).markNeedsBuild();
                            }
                          : null,
                    ),
                    Text('$tempDailyGoal'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: tempDailyGoal < 300
                          ? () {
                              tempDailyGoal += 5;
                              (context as Element).markNeedsBuild();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Weekly Goal (pages)'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: tempWeeklyGoal > 10
                          ? () {
                              tempWeeklyGoal -= 10;
                              (context as Element).markNeedsBuild();
                            }
                          : null,
                    ),
                    Text('$tempWeeklyGoal'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: tempWeeklyGoal < 500
                          ? () {
                              tempWeeklyGoal += 10;
                              (context as Element).markNeedsBuild();
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _dailyGoalMinutes = tempDailyGoal;
                  _weeklyGoalPages = tempWeeklyGoal;
                });
                _saveReadingAnalytics();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _jumpToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _showJuzSwitcher() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadedJuzs = <int>[];
    for (int juz = 1; juz <= 30; juz++) {
      final juzDir = Directory('${dir.path}/quran_juz_$juz');
      if (juzDir.existsSync()) {
        final files = juzDir.listSync().whereType<File>().toList();
        if (files.isNotEmpty) {
          downloadedJuzs.add(juz);
        }
      }
    }
    // downloadedJuzs is already in order (1, 2, 3, etc.) since we iterate from 1 to 30

    final selectedJuz = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return ListView(
          children: downloadedJuzs
              .map((juz) => ListTile(
                    title: Text('Juz $juz'),
                    onTap: () => Navigator.of(context).pop(juz),
                  ))
              .toList(),
        );
      },
    );
    if (selectedJuz != null) {
      // Find the first page index for the selected Juz
      final dir = await getApplicationDocumentsDirectory();
      final juzDir = Directory('${dir.path}/quran_juz_$selectedJuz');
      if (juzDir.existsSync()) {
        final files = juzDir
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.path.endsWith('.jpg') ||
                f.path.endsWith('.jpeg') ||
                f.path.endsWith('.png'))
            .toList();
        files.sort((a, b) {
          final aPage = _extractPageNumber(a.path);
          final bPage = _extractPageNumber(b.path);
          return aPage.compareTo(bPage);
        });
        if (files.isNotEmpty) {
          final firstFile = files.first;
          final pageIndex =
              _images.indexWhere((img) => img.path == firstFile.path);
          if (pageIndex != -1) {
            _jumpToPage(pageIndex);
          }
        }
      }
    }
  }

  Widget _buildPageIndicator() {
    final currentPage = _currentPage;
    return GestureDetector(
      onTap: () async {
        final page = await showDialog<int>(
          context: context,
          builder: (context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text('Jump to Page'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter page number (1-${_images.length})',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final input = int.tryParse(controller.text);
                    if (input != null &&
                        input >= 1 &&
                        input <= _images.length) {
                      Navigator.of(context).pop(input - 1);
                    }
                  },
                  child: const Text('Go'),
                ),
              ],
            );
          },
        );
        if (page != null) {
          _jumpToPage(page);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Page ${currentPage + 1} of ${_images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 4,
            leading: AnimatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Icon(Icons.arrow_back_ios_new),
            ),
            centerTitle: true,
            title: Text(
              widget.isWholeQuran
                  ? s.quran
                  : widget.isDownloadedJuzsOnly
                      ? s.downloadedJuzsTitle
                      : 'Juz ${widget.juzNumber}',
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            actions: [
              AnimatedButton(
                onPressed: _images.isNotEmpty ? _toggleBookmark : null,
                child: Icon(_isCurrentPageBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border),
              ),
              if (widget.isWholeQuran)
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  tooltip: s.surahList,
                  onPressed: () async {
                    await Navigator.of(context).push(
                      AppPageRouteBuilder(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: SurahListScreen(
                            onSurahSelected: (surah) {
                              int pageIndex =
                                  (surah.page - 1).clamp(0, _images.length - 1);
                              Navigator.of(context).pop();
                              _jumpToPage(pageIndex);
                            },
                          ),
                        ),
                        transitionType: PageTransitionType.slideFromBottom,
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: s.more,
                onPressed: () async {
                  await showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.bookmarks),
                            title: const Text('Bookmarks'),
                            onTap: () {
                              Navigator.of(context).pop();
                              if (_images.isNotEmpty) _showBookmarks();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: Text(s.readingSettings),
                            onTap: () {
                              Navigator.of(context).pop();
                              if (_images.isNotEmpty) _showReadingSettings();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.analytics),
                            title: Text(s.readingAnalytics),
                            onTap: () {
                              Navigator.of(context).pop();
                              if (_images.isNotEmpty) _showReadingAnalytics();
                            },
                          ),
                          if (widget.isDownloadedJuzsOnly)
                            ListTile(
                              leading: const Icon(Icons.swap_horiz),
                              title: Text(s.switchJuz),
                              onTap: () {
                                Navigator.pop(context);
                                _showJuzSwitcher();
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _images.isEmpty
                ? Center(child: Text(s.noImagesFoundForThisJuz))
                : Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        scrollDirection:
                            _scrollDirection == ScrollDirection.horizontal
                                ? Axis.horizontal
                                : Axis.vertical,
                        reverse: _scrollDirection == ScrollDirection.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _images.length,
                        onPageChanged: (index) {
                          if (_currentPage != index) {
                            setState(() {
                              _currentPage = index;
                            });
                          }
                        },
                        itemBuilder: (context, index) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              PhotoView(
                                imageProvider: FileImage(_images[index]),
                                minScale: PhotoViewComputedScale.covered,
                                initialScale: PhotoViewComputedScale.covered,
                                maxScale: PhotoViewComputedScale.covered * 5.0,
                                basePosition: Alignment.center,
                                backgroundDecoration: const BoxDecoration(
                                  color: Colors.black,
                                ),
                              ),
                              if (_isNightMode)
                                Container(color: Colors.black54),
                            ],
                          );
                        },
                      ),
                      Positioned(
                        bottom: 24,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPageIndicator(),
                              // Timer display
                              if (_isTimerRunning) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatTime(_readingTimeSeconds),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              // Auto scroll indicator
                              if (_isAutoScrollEnabled) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        s.autoScrolling,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _toggleAutoScroll(false),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        floatingActionButton: null,
      ),
    );
  }
}

class ReadingSession {
  final DateTime date;
  final int durationMinutes;
  final int pagesRead;
  final int juzNumber;
  final bool isWholeQuran;

  ReadingSession({
    required this.date,
    required this.durationMinutes,
    required this.pagesRead,
    required this.juzNumber,
    required this.isWholeQuran,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'pagesRead': pagesRead,
        'juzNumber': juzNumber,
        'isWholeQuran': isWholeQuran,
      };

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
        date: DateTime.parse(json['date']),
        durationMinutes: json['durationMinutes'],
        pagesRead: json['pagesRead'],
        juzNumber: json['juzNumber'],
        isWholeQuran: json['isWholeQuran'] ?? false,
      );
}

// Helper widget for a simple bar chart
class _BarChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final int maxValue;
  const _BarChart(
      {required this.values, required this.labels, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final barColor = Theme.of(context).primaryColor;
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final v = values[i];
          final h = maxValue > 0 ? (v / maxValue) * 80.0 : 0.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: '${labels[i]}: $v',
                  child: Container(
                    height: h,
                    width: 16,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i], style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }),
      ),
    );
  }
}
