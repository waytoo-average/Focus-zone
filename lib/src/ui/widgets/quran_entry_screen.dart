// --- Quran Entry Screen ---
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import '../../../l10n/app_localizations.dart';
import '../../../src/utils/download_manager_v3.dart' as new_dm;
import 'juz_viewer_screen.dart';
import 'juz_list_screen.dart';
import 'package:provider/provider.dart';

const String wholeQuranFolderId = '1jT-vIj8rA7Aed5BzpyPPQBGQFH436tTk';

// Juz folder IDs for downloading individual Juzs
const Map<int, String> juzFolderIds = {
  1: '1sYAkXooneCzzalMXecHdKlMfyf8QmETI',
  2: '1QjpyuLXFkCT9TQ0xEniZO1i_NMaROxHu',
  3: '1lH4WgJxwkSPugTN9CRWvrzbBm1G3HuMd',
  4: '1kcsMs-CWhT0uI4iy5uh-BONHdP8W36iQ',
  5: '1Iu9FyGCRqL8VpDtQ0U61WppKRgncXLSA',
  6: '1_34rpZQ9aNqty6qffuKsustZWljrxMqV',
  7: '1VPF3nEeiNCIyQae8sNd9lmPRYH6DcvOs',
  8: '1N8mL4m7cOkKHSkSIY30U5LkfKWuCnhMg',
  9: '1194jR6lw4stnQsg84c_OHtdhHIr8IbzF',
  10: '1Dp8X2PihtDvUYFi0DL9lWYc5-hWXGqft',
  11: '1hQNAeOB2oqdLllqJ2fpgifrqr1wJcwLw',
  12: '1QHmTCwGdEGSnUVcH41zn7mNTFIklsu3i',
  13: '18k41IW-Y9dEQSOHEJznqhBXEDYCst6d3',
  14: '1G4a0lmDEf2nv0qiadIfN0BIEKIrrO4ca',
  15: '1n-JxmCsAt3nJB4d4NICvQS_I1DcA39py',
  16: '14FwejagwetmsshJLyrIcWvGAEoBVFrbG',
  17: '1ZSFuHQM--5zmLYE8uaCJJi56HbBTRsJn',
  18: '1Y8MqlUCKwhnkOVF4wC7ixa3O8H85ldan',
  19: '1hKpajN910Pali82mMEzwgXbaEk7Kk1VG',
  20: '1yhQoEuQ1eAiQ4y7bHKDpgEnYWzIWxnkK',
  21: '16imLUt4j2nqtTtB3pZspF1j3yHIphoii',
  22: '1OdodIgmU6KmRGwVfpNdHHtTr5h9ltFtK',
  23: '1pntM69YAjEidi4bOSYrkN7PHB7q0idyI',
  24: '1asfO8j5I4_cWzzCmXlwhZjOPsi3lF7Uu',
  25: '19JOgl6FIEG4Pu_gu9nJxUgC7IKN6_WNx',
  26: '1ANPxqS_Bqc-CEF-_Ic2BlbjYzAUpidGR',
  27: '1WKN4i5oyy_NUM4attp-5Vmrf3x0_P0wy',
  28: '1QHmTCwGdEGSnUVcH41zn7mNTFIklsu3i',
  29: '18k41IW-Y9dEQSOHEJznqhBXEDYCst6d3',
  30: '1G4a0lmDEf2nv0qiadIfN0BIEKIrrO4ca',
};

class QuranEntryScreen extends StatefulWidget {
  const QuranEntryScreen({super.key});

  @override
  State<QuranEntryScreen> createState() => _QuranEntryScreenState();
}

class _QuranEntryScreenState extends State<QuranEntryScreen>
    with WidgetsBindingObserver {
  new_dm.FullQuranDownloadManager? _manager;
  bool _isDownloadedCached = false;
  String _expectedSize = 'Unknown';
  int _expectedFileCount = 0;
  int _downloadedJuzsCount = 0; // Add this to track downloaded Juzs
  bool _hasAnyQuranFiles = false; // Tracks if any Quran files exist locally

  // Hardcoded Quran constants
  static const int TOTAL_QURAN_PAGES = 604;
  static const String TOTAL_QURAN_SIZE = '152MB'; // Approximate size

  // Enhanced state tracking
  bool _isRetrying = false;
  bool _isResuming = false;
  Timer? _refreshTimer;

  // Temporary state override for UI responsiveness
  bool _forceDownloadingState = false;
  Timer? _forceStateTimer;

  // Rotating Quranic verses
  int _currentVerseIndex = 0;
  Timer? _verseTimer;
  final List<String> _quranicVerses = [
    'ٱلَّذِينَ ءَاتَيْنَٰهُمُ ٱلْكِتَٰبَ يَتْلُونَهُۥ حَقَّ تِلَاوَتِهِۦٓ أُو۟لَٰٓئِكَ يُؤْمِنُونَ بِهِۦ وَمَن يَكْفُرْ بِهِۦ فَأُو۟لَٰٓئِكَ هُمُ ٱلْخَٰسِرُونَ',
    'الٓمٓ ۝ ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ فِيهِ هُدًى لِّلْمُتَّقِينَ',
    'أَفَلَا يَتَدَبَّرُونَ ٱلْقُرْءَانَ وَلَوْ كَانَ مِنْ عِندِ غَيْرِ ٱللَّهِ لَوَجَدُوا۟ فِيهِ ٱخْتِلَٰفًا كَثِيرًا',
    'إِنَّآ أَنزَلْنَٰهُ قُرْءَٰنًا عَرَبِيًّا لَّعَلَّكُمْ تَعْقِلُونَ',
    'إِنَّا نَحْنُ نَزَّلْنَا ٱلذِّكْرَ وَإِنَّا لَهُۥ لَحَٰفِظُونَ',
    'فَإِذَا قَرَأْتَ ٱلْقُرْءَانَ فَٱسْتَعِذْ بِٱللَّهِ مِنَ ٱلشَّيْطَٰنِ ٱلرَّجِيمِ',
    'إِنَّ هَٰذَا ٱلْقُرْءَانَ يَهْدِى لِلَّتِى هِىَ أَقْوَمُ وَيُبَشِّرُ ٱلْمُؤْمِنِينَ ٱلَّذِينَ يَعْمَلُونَ ٱلصَّٰلِحَٰتِ أَنَّ لَهُمْ أَجْرًا كَبِيرًا',
    'وَلَقَدْ صَرَّفْنَا فِى هَٰذَا ٱلْقُرْءَانِ لِلنَّاسِ مِن كُلِّ مَثَلٍ وَكَانَ ٱلْإِنسَٰنُ أَكْثَرَ شَىْءٍ جَدَلًا',
    'وَأَنْ أَتْلُوَا۟ ٱلْقُرْءَانَ فَمَنِ ٱهْتَدَىٰ فَإِنَّمَا يَهْتَدِى لِنَفْسِهِۦ وَمَن ضَلَّ فَقُلْ إِنَّنَآ أَنَا۠ مِنَ ٱلْمُنذِرِينَ',
    'كِتَٰبٌ أَنزَلْنَٰهُ إِلَيْكَ مُبَٰرَكٌ لِّيَدَّبَّرُوٓا۟ ءَايَٰتِهِۦ وَلِيَتَذَكَّرَ أُو۟لُوا۟ ٱلْأَلْبَٰبِ',
    'وَلَقَدْ ضَرَبْنَا لِلنَّاسِ فِى هَٰذَا ٱلْقُرْءَانِ مِن كُلِّ مَثَلٍ لَّعَلَّهُمْ يَتَذَكَّرُونَ',
    'وَلَقَدْ يَسَّرْنَا ٱلْقُرْءَانَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ',
    'بَلْ هُوَ قُرْءَانٌ مَّجِيدٌ۝فِى لَوْحٍ مَّحْفُوظٍۭ',
    'أَفَلَا يَتَدَبَّرُونَ الْقُرْآنَ أَمْ عَلَىٰ قُلُوبٍ أَقْفَالُهَا',
    'كِتَابٌ أَنزَلْنَاهُ إِلَيْكَ مُبَارَكٌ لِّيَدَّبَرُوا آيَاتِهِ وَلِيَتَذَكَّرَ أُولُو الْأَلْبَابِ ',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Set hardcoded values immediately for instant UI display
    _expectedSize = TOTAL_QURAN_SIZE;
    _expectedFileCount = TOTAL_QURAN_PAGES;

    _initializeManager();
    _loadCachedQuranInfo(); // Load cached info (will only override if valid)
    _loadDownloadedJuzsCount();
    _updateHasAnyQuranFiles();
    _startVerseRotation();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verseTimer?.cancel();
    _refreshTimer?.cancel();
    _forceStateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Ensure downloads continue when app goes to background
    if (state == AppLifecycleState.paused) {
      // App is going to background - ensure download continues
      if (_manager?.state.status == new_dm.DownloadStatus.downloading) {
        // Force background mode if not already enabled
        if (!_manager!.isBackgroundEnabled) {
          _manager!.isBackgroundEnabled = true;
          _manager!.startBackgroundMonitoring();
          _manager!.startNetworkMonitoring();
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      // App is coming back to foreground - refresh state
      setState(() {
        _loadDownloadedJuzsCount();
        _loadCachedQuranInfo();
        _updateHasAnyQuranFiles();
      });
    }
  }

  void _startRefreshTimer() {
    // Refresh UI every 2 seconds to handle network changes and state updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (mounted) {
        // Check if we're in error state and try to recover
        final state = _manager?.state;
        if (state?.status == new_dm.DownloadStatus.error) {
          // Try to check if network is restored
          try {
            await _reloadCachedInfo();
            // If we can reload info successfully, the error might be resolved
            setState(() {});
          } catch (e) {
            // Network still down, keep error state
          }
        } else {
          // Normal refresh for other states
          setState(() {
            _loadDownloadedJuzsCount();
            _updateHasAnyQuranFiles();
          });
        }
      }
    });
  }

  // Check if any Quran files exist in storage (quran_full or any quran_juz_<n>)
  Future<void> _updateHasAnyQuranFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final basePath = dir.path;

      // Helper to check if a directory contains any non-temp files
      Future<bool> dirHasFiles(String path) async {
        final d = Directory(path);
        if (!await d.exists()) return false;
        try {
          await for (final entity in d.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final name = entity.path.split(Platform.pathSeparator).last;
              if (!name.endsWith('.part')) {
                return true;
              }
            }
          }
        } catch (_) {
          // Ignore errors and treat as no files
        }
        return false;
      }

      // Check full Quran folder
      final hasFull = await dirHasFiles('$basePath${Platform.pathSeparator}quran_full');
      bool hasAny = hasFull;

      // If not found yet, check each juz folder quickly
      if (!hasAny) {
        for (int i = 1; i <= 30; i++) {
          final hasJuz = await dirHasFiles(
              '$basePath${Platform.pathSeparator}quran_juz_$i');
          if (hasJuz) {
            hasAny = true;
            break;
          }
        }
      }

      if (mounted && _hasAnyQuranFiles != hasAny) {
        setState(() {
          _hasAnyQuranFiles = hasAny;
        });
      }
    } catch (_) {
      // On error, don't change state
    }
  }

  void _startVerseRotation() {
    _verseTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentVerseIndex = (_currentVerseIndex + 1) % _quranicVerses.length;
        });
      }
    });
  }

  Future<void> _initializeManager() async {
    // Use the global manager from Provider instead of creating a new instance
    _manager =
        Provider.of<new_dm.FullQuranDownloadManager>(context, listen: false);
    await _loadCachedQuranInfo();
    await _loadDownloadedJuzsCount();

    // Add listener to refresh Juz count when download state changes
    _manager?.addListener(() {
      if (mounted) {
        setState(() {
          // Force refresh of all state
          _loadDownloadedJuzsCount();
          _loadCachedQuranInfo();
          _updateHasAnyQuranFiles();
        });

        // Update notification if background is enabled
        if (_manager?.isBackgroundEnabled == true) {
          final state = _manager?.state;
          if (state != null) {
            if (state.status == new_dm.DownloadStatus.completed ||
                state.status == new_dm.DownloadStatus.cancelled) {
              _manager?.hideNotification(context);
            } else {
              _manager?.updateNotification(context);
            }
          }
        }
      }
    });
  }

  // Add the missing method
  Future<Map<String, dynamic>> getCachedQuranDownloadInfo(
      {required bool isFullQuran}) async {
    try {
      if (_manager == null) {
        return {
          'downloaded': false,
          'pageCount': 0,
          'fileSize': 0,
        };
      }

      if (isFullQuran) {
        // Check if the full Quran is downloaded
        final state = _manager!.state;
        final isDownloaded = state.status == new_dm.DownloadStatus.completed;

        return {
          'downloaded': isDownloaded,
          'pageCount': state.totalFiles,
          'fileSize': state.downloadedBytes,
        };
      }

      return {
        'downloaded': false,
        'pageCount': 0,
        'fileSize': 0,
      };
    } catch (e) {
      return {
        'downloaded': false,
        'pageCount': 0,
        'fileSize': 0,
      };
    }
  }

  // Add method to count downloaded Juzs
  Future<int> _getDownloadedJuzsCount() async {
    try {
      final progress =
          await new_dm.FullQuranDownloadManager.getAllJuzsDownloadProgress();
      return progress['downloadedJuzsCount'] as int;
    } catch (e) {
      return 0;
    }
  }

  // Get detailed Juz progress for UI display
  Future<Map<String, dynamic>> _getDetailedJuzProgress() async {
    try {
      return await new_dm.FullQuranDownloadManager.getAllJuzsDownloadProgress();
    } catch (e) {
      return {
        'totalDownloadedPages': 0,
        'totalExpectedPages': new_dm.FullQuranDownloadManager.TOTAL_QURAN_PAGES,
        'overallProgress': 0.0,
        'downloadedJuzsCount': 0,
        'totalFileSize': 0,
        'juzProgress': <int, Map<String, dynamic>>{},
      };
    }
  }

  Future<void> _loadDownloadedJuzsCount() async {
    final count = await _getDownloadedJuzsCount();
    if (mounted) {
      setState(() {
        _downloadedJuzsCount = count;
      });
    }
  }

  Future<void> _loadCachedQuranInfo() async {
    try {
      final info = await getCachedQuranDownloadInfo(isFullQuran: true);
      if (mounted) {
        setState(() {
          _isDownloadedCached = info['downloaded'] ?? false;
          // Only override hardcoded values if we have valid cached data
          if (info['pageCount'] != null && info['pageCount'] > 0) {
            _expectedFileCount = info['pageCount'];
          }
          if (info['fileSize'] != null && info['fileSize'] > 0) {
            _expectedSize = _formatFileSize(info['fileSize']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // _isLoadingSize = false; // This line is removed
        });
      }
    }
  }

  Future<void> _reloadCachedInfo() async {
    await _loadCachedQuranInfo();
    await _loadDownloadedJuzsCount();
    await _updateHasAnyQuranFiles();
  }

  // Enhanced state calculation that handles all edge cases
  Map<String, dynamic> _calculateDownloadState() {
    final state = _manager?.state;
    final completedFiles = state?.downloadedFiles ?? 0;
    final totalFiles = state?.totalFiles ?? 0;
    final progress = state?.progress ?? 0.0;
    final status = state?.status ?? new_dm.DownloadStatus.idle;

    // Determine current state
    final isDownloading =
        _forceDownloadingState || status == new_dm.DownloadStatus.downloading;
    final isPausing = status == new_dm.DownloadStatus.pausing;
    final isPaused = status == new_dm.DownloadStatus.paused;
    final isError = status == new_dm.DownloadStatus.error;
    final isNetworkError = status == new_dm.DownloadStatus.networkError;
    final isCancelled = status == new_dm.DownloadStatus.cancelled;
    final isCompleted = status == new_dm.DownloadStatus.completed;

    // Calculate if download is complete
    final isDownloaded = _isDownloadedCached ||
        (totalFiles > 0 && completedFiles == totalFiles) ||
        isCompleted;

    // Calculate if we have any progress
    final hasProgress = completedFiles > 0 || progress > 0.0;

    // Determine if we should show retry/resume
    // Show retry for network errors or regular errors with progress
    final shouldShowRetry = (isNetworkError || isError) && hasProgress;
    // Show resume if paused/cancelled AND we have progress
    final shouldShowResume = (isPaused || isCancelled) && hasProgress;

    // Check if error state should be cleared (network restored)
    final shouldClearError = (isError || isNetworkError) && !hasProgress;

    // Calculate display text
    String statusText = '';
    if (isDownloading) {
      statusText =
          "$completedFiles of $totalFiles files downloaded (${(progress * 100).toInt()}%)";
    } else if (isPausing) {
      statusText =
          "$completedFiles of $totalFiles files downloaded (${(progress * 100).toInt()}%) - Pausing...";
    } else if (isPaused) {
      statusText =
          "$completedFiles of $totalFiles files downloaded (${(progress * 100).toInt()}%) - Paused";
    } else if (isNetworkError) {
      statusText =
          "$completedFiles of $totalFiles files downloaded (${(progress * 100).toInt()}%) - Network Error";
    } else if (isError && !shouldClearError) {
      statusText =
          "$completedFiles of $totalFiles files downloaded (${(progress * 100).toInt()}%) - Error";
    } else if (isCancelled) {
      // After cancellation, show full size instead of remaining progress
      statusText =
          "Complete Quran (${_formatFileSize(new_dm.FullQuranDownloadManager.TOTAL_QURAN_SIZE_BYTES)}, ${new_dm.FullQuranDownloadManager.TOTAL_QURAN_PAGES} pages)";
    } else if (isDownloaded) {
      statusText =
          "Complete Quran ($_expectedSize, $_expectedFileCount pages) - Ready";
    } else {
      // Default state - show full size
      statusText =
          "Complete Quran (${_formatFileSize(new_dm.FullQuranDownloadManager.TOTAL_QURAN_SIZE_BYTES)}, ${new_dm.FullQuranDownloadManager.TOTAL_QURAN_PAGES} pages)";
    }

    return {
      'isDownloading': isDownloading,
      'isPausing': isPausing,
      'isPaused': isPaused,
      'isError': isError && !shouldClearError,
      'isNetworkError': isNetworkError,
      'isCancelled': isCancelled,
      'isCompleted': isCompleted,
      'isDownloaded': isDownloaded,
      'hasProgress': hasProgress,
      'shouldShowRetry': shouldShowRetry,
      'shouldShowResume': shouldShowResume,
      'shouldClearError': shouldClearError,
      'completedFiles': completedFiles,
      'totalFiles': totalFiles,
      'progress': progress,
      'statusText': statusText,
      'status': status,
    };
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return 'Unknown';
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
    return '${mb}MB';
  }

  // --- Enhanced Full Quran Action for Images ---
  void _handleFullQuranAction() async {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    // Check if the full Quran is completed
    final state = _manager?.state;
    final isCompleted = state?.status == new_dm.DownloadStatus.completed;

    // Check if any Juz is currently downloading
    final hasActiveDownloads =
        state?.status == new_dm.DownloadStatus.downloading;

    // Check if any Juz is paused
    final hasPausedDownloads = state?.status == new_dm.DownloadStatus.paused;

    if (isCompleted) {
      openWholeQuranViewer(context);
    } else if (hasActiveDownloads || hasPausedDownloads) {
      // Don't show modal sheet, let the card controls handle it
      return;
    } else {
      // Calculate remaining files and size
      final progress = await _getDetailedJuzProgress();
      final totalDownloadedPages = progress['totalDownloadedPages'] as int;
      final totalExpectedPages = progress['totalExpectedPages'] as int;
      final totalDownloadedSize = progress['totalFileSize'] as int;

      // If nothing is downloaded, show full size
      String dialogText;
      if (totalDownloadedPages == 0) {
        dialogText =
            'The full Quran contains $totalExpectedPages image pages (approximately ${_formatFileSize(new_dm.FullQuranDownloadManager.TOTAL_QURAN_SIZE_BYTES)}). '
            'This will download high-quality Quran page images. Continue?';
      } else {
        final remainingPages = totalExpectedPages - totalDownloadedPages;
        final remainingSize = _calculateRemainingSize(
            totalDownloadedSize, totalDownloadedPages, remainingPages);
        dialogText =
            'The full Quran contains $remainingPages remaining image pages (approximately ${_formatFileSize(remainingSize)}). '
            'This will download high-quality Quran page images. Continue?';
      }

      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.downloadFullQuran),
          content: Text(dialogText),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Download Images'),
            ),
          ],
        ),
      );
      if (shouldDownload == true) {
        // Start full Quran download with background enabled
        if (_manager != null) {
          try {
            // Start the Flutter manager for UI state management
            _manager!.start(enableBackground: true);

            // Show notification when download starts
            _manager!.showNotification(context);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error starting download: $e')),
            );
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download manager not initialized')),
          );
        }
        await _loadCachedQuranInfo();
      }
    }
  }

  // Calculate remaining size based on downloaded size and remaining pages
  int _calculateRemainingSize(
      int downloadedSize, int downloadedPages, int remainingPages) {
    if (downloadedPages == 0) {
      // If nothing downloaded, return total size
      return new_dm.FullQuranDownloadManager.TOTAL_QURAN_SIZE_BYTES;
    }

    // Calculate average size per page
    final averageSizePerPage = downloadedSize / downloadedPages;

    // Estimate remaining size
    return (averageSizePerPage * remainingPages).round();
  }

  // --- Enhanced Delete Function for Image Downloads ---
  Future<void> _deleteWholeQuran() async {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteFullQuran),
        content: const Text(
            'Are you sure you want to delete all downloaded Quran images? '
            'This will free up storage space but you will need to download the images again to view them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      // Delete all downloaded Juzs
      await _manager?.delete();
      await _loadCachedQuranInfo();
      await _updateHasAnyQuranFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full Quran deleted successfully.')),
      );
    }
  }

  // Enhanced retry method with proper state handling
  Future<void> _handleRetry() async {
    if (_isRetrying) return; // Prevent multiple retries

    setState(() {
      _isRetrying = true;
      _forceDownloadingState = true; // Force downloading state immediately
    });

    // Clear any existing force state timer
    _forceStateTimer?.cancel();

    try {
      // Ensure manager is initialized
      if (_manager == null) {
        await _initializeManager();
      }

      // Clear any error state first
      await _reloadCachedInfo();

      // Start the download
      _manager?.start();

      // Keep force state for 3 seconds to ensure UI updates
      _forceStateTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _forceDownloadingState = false;
          });
        }
      });

      // Additional updates to ensure state propagation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {});
        }
      });

      // Check for network recovery after 2 seconds
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          // Force a state refresh to check if network error is resolved
          await _reloadCachedInfo();
          setState(() {});
        }
      });
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  // Enhanced resume method with proper state handling
  Future<void> _handleResume() async {
    if (_isResuming) return; // Prevent multiple resumes

    setState(() {
      _isResuming = true;
      _forceDownloadingState = true; // Force downloading state immediately
    });

    // Clear any existing force state timer
    _forceStateTimer?.cancel();

    try {
      // Ensure manager is initialized
      if (_manager == null) {
        await _initializeManager();
      }

      // Reload cached info to get current progress
      await _reloadCachedInfo();

      // Resume the download
      _manager?.start();

      // Keep force state for 3 seconds to ensure UI updates
      _forceStateTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _forceDownloadingState = false;
          });
        }
      });

      // Additional updates to ensure state propagation
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resume failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResuming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final s = AppLocalizations.of(context);

    if (s == null) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: const Text("Quran")),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: _manager ?? const AlwaysStoppedAnimation(0),
        builder: (context, _) {
          // Use comprehensive state calculation
          final downloadState = _calculateDownloadState();
          final hasDownloadedJuzs = _downloadedJuzsCount > 0;

          return Container(
            color: theme.scaffoldBackgroundColor,
            child: ListView(
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      // Quran Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.menu_book,
                          size: 40,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Title
                      Text(
                        s.quranSubtitle,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      Text(
                        s.quranTitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textTheme.titleMedium?.color
                              ?.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description with rotating Quran verses
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          _quranicVerses[_currentVerseIndex],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            color: theme.textTheme.bodyMedium?.color,
                            height: 1.6,
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Options Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Browse Juzs Card
                      _ModernQuranCard(
                        icon: Icons.grid_view,
                        title: s.browseJuzs,
                        subtitle: s.browseJuzsSubtitle,
                        color: theme.colorScheme.secondary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const JuzListScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // View Downloaded Juzs Card (if any Juzs are downloaded)
                      if (hasDownloadedJuzs) ...[
                        FutureBuilder<Map<String, dynamic>>(
                          future: _getDetailedJuzProgress(),
                          builder: (context, snapshot) {
                            final progress = snapshot.data ??
                                {
                                  'totalDownloadedPages': 0,
                                  'totalExpectedPages': new_dm
                                      .FullQuranDownloadManager
                                      .TOTAL_QURAN_PAGES,
                                  'overallProgress': 0.0,
                                  'downloadedJuzsCount': _downloadedJuzsCount,
                                  'totalFileSize': 0,
                                };

                            final totalDownloadedPages =
                                progress['totalDownloadedPages'] as int;
                            final totalExpectedPages =
                                progress['totalExpectedPages'] as int;
                            final overallProgress =
                                progress['overallProgress'] as double;
                            final downloadedJuzsCount =
                                progress['downloadedJuzsCount'] as int;
                            final totalFileSize =
                                progress['totalFileSize'] as int;

                            String subtitle;
                            if (downloadedJuzsCount == 30) {
                              subtitle =
                                  'Complete Quran downloaded (${_formatFileSize(totalFileSize)})';
                            } else {
                              final progressPercent =
                                  (overallProgress * 100).toInt();
                              subtitle =
                                  '$downloadedJuzsCount of 30 Juzs • $totalDownloadedPages/$totalExpectedPages pages • $progressPercent%';
                            }

                            return _ModernQuranCard(
                              icon: Icons.book,
                              title: 'View Downloaded Juzs',
                              subtitle: subtitle,
                              color: Colors.green.shade400,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JuzViewerScreen(
                                      juzNumber: 1,
                                      isDownloadedJuzsOnly: true,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Full Quran Card
                      _ModernQuranCard(
                        icon: downloadState['isDownloaded']
                            ? Icons.book
                            : downloadState['isDownloading']
                                ? Icons.pause
                                : downloadState['isPausing']
                                    ? Icons.pause
                                    : downloadState['isPaused']
                                        ? Icons.play_arrow
                                        : Icons.download,
                        title: downloadState['isDownloaded']
                            ? s.viewFullQuran
                            : downloadState['isDownloading']
                                ? s.pauseDownload
                                : downloadState['isPausing']
                                    ? 'Pausing...'
                                    : downloadState['isPaused']
                                        ? s.resumeDownload
                                        : s.downloadFullQuran,
                        subtitle: downloadState['statusText'],
                        color: downloadState['isDownloaded']
                            ? Colors.green.shade400
                            : downloadState['isDownloading']
                                ? Colors.orange
                                : downloadState['isPausing']
                                    ? Colors.orange
                                    : downloadState['isPaused']
                                        ? Colors.blue
                                        : theme.colorScheme.secondary,
                        onTap: downloadState['isDownloading'] ||
                                downloadState['isPausing'] ||
                                downloadState['isPaused']
                            ? () {
                                // This onTap is now handled by the card's showControls
                              }
                            : _handleFullQuranAction,
                        showProgress: downloadState['isDownloading'] ||
                            downloadState['isPausing'] ||
                            downloadState['isPaused'],
                        progress: downloadState['progress'],
                        showControls: downloadState['isDownloading'] ||
                            downloadState['isPausing'] ||
                            downloadState['isPaused'],
                        onPauseResume: downloadState['isDownloading']
                            ? () {
                                _manager?.pause();
                              }
                            : downloadState['isPaused']
                                ? () {
                                    _manager?.resume();
                                  }
                                : null,
                        onCancel: () async {
                          // Show confirmation dialog for cancel
                          final shouldCancel = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cancel Download'),
                              content: const Text(
                                  'Are you sure you want to cancel the download? '
                                  'This will stop the download and you can resume it later.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Cancel Download'),
                                ),
                              ],
                            ),
                          );
                          if (shouldCancel == true) {
                            _manager?.cancel();
                          }
                        },
                        isDownloading: downloadState['isDownloading'],
                        isPaused: downloadState['isPaused'],
                        isPausing: downloadState['isPausing'],
                      ),

                      // Error Card - Only show if there's an error and we have progress
                      if (downloadState['shouldShowRetry']) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: downloadState['isNetworkError']
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: downloadState['isNetworkError']
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                  downloadState['isNetworkError']
                                      ? Icons.wifi_off
                                      : Icons.error,
                                  color: downloadState['isNetworkError']
                                      ? Colors.orange
                                      : Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      downloadState['isNetworkError']
                                          ? 'Network connection lost'
                                          : 'Download error occurred',
                                      style: TextStyle(
                                        color: downloadState['isNetworkError']
                                            ? Colors.orange
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      downloadState['isNetworkError']
                                          ? 'Download will resume automatically when connection is restored'
                                          : 'Please try again',
                                      style: TextStyle(
                                        color: downloadState['isNetworkError']
                                            ? Colors.orange.shade700
                                            : Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _isRetrying ? null : _handleRetry,
                                child: _isRetrying
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text(s.retry),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Delete Button (show whenever any Quran files exist locally)
                      if (_hasAnyQuranFiles) ...[
                        const SizedBox(height: 16),
                        _ModernQuranCard(
                          icon: Icons.delete_outline,
                          title: s.deleteFullQuran,
                          subtitle: s.freeUpStorage,
                          color: theme.colorScheme.error,
                          onTap: _deleteWholeQuran,
                          isDestructive: true,
                        ),
                      ],
                      // Resume Download Warning - Only show if paused/cancelled with progress
                      if (downloadState['shouldShowResume']) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange
                                .withOpacity(isDarkMode ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange
                                    .withOpacity(isDarkMode ? 0.5 : 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange[isDarkMode ? 300 : 700],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.downloadIncomplete,
                                      style: TextStyle(
                                        color: Colors
                                            .orange[isDarkMode ? 300 : 700],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$_downloadedJuzsCount of 30 Juzs downloaded',
                                      style: TextStyle(
                                        color: Colors
                                            .orange[isDarkMode ? 400 : 600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _isResuming ? null : _handleResume,
                                child: _isResuming
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : Text(s.resumeDownload),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Footer Info
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  child: Text(
                    s.stillUnderDevelopment,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void openWholeQuranViewer(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => JuzViewerScreen(juzNumber: 0, isWholeQuran: true),
    ),
  );
}

class _ModernQuranCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool showProgress;
  final double progress;
  final bool isDestructive;
  final bool showControls;
  final VoidCallback? onPauseResume;
  final VoidCallback? onCancel;
  final bool isDownloading;
  final bool isPaused;
  final bool isPausing;

  const _ModernQuranCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.showProgress = false,
    this.progress = 0.0,
    this.isDestructive = false,
    this.showControls = false,
    this.onPauseResume,
    this.onCancel,
    this.isDownloading = false,
    this.isPaused = false,
    this.isPausing = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    if (s == null) {
      return Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDestructive
                                  ? color
                                  : theme.textTheme.titleLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arrow Icon or Controls
                    if (!showProgress && !showControls)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: theme.dividerColor,
                        size: 16,
                      ),
                  ],
                ),
                // Progress Bar
                if (showProgress) ...[
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isDownloading
                                ? s.downloading
                                : isPausing
                                    ? 'Pausing...'
                                    : isPaused
                                        ? 'Paused'
                                        : s.downloading,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.dividerColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
                // Control Buttons
                if (showControls) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onPauseResume,
                          icon: Icon(
                              isDownloading ? Icons.pause : Icons.play_arrow),
                          label: Text(isDownloading
                              ? s.pauseDownload
                              : s.resumeDownload),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDownloading ? Colors.orange : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.stop),
                          label: Text(s.cancel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
