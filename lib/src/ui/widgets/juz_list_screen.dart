import 'package:flutter/material.dart';
import 'dart:async';
import 'juz_viewer_screen.dart';
import '../../utils/download_manager_v3.dart' as new_dm;
import '../../../l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Standard Juz starting pages (Madani Mushaf)
const List<int> juzStartingPages = [
  1,
  22,
  42,
  62,
  82,
  102,
  121,
  142,
  162,
  182,
  201,
  222,
  242,
  262,
  282,
  302,
  322,
  342,
  362,
  382,
  402,
  422,
  442,
  462,
  482,
  502,
  522,
  542,
  562,
  582
];

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
  28: '1ZOPXFwFqRCPjgHyfAlnkcgK_xxifD0a5',
  29: '1FDse55X4px6D49hNUasY80FNv4Flsdq5',
  30: '1zi0TwtGYFX5YKiWW9CuusqzaXpcAyWEk',
};

// --- Juz List Data ---
const List<String> juzHeaders = [
  'الجزء الأول',
  'الجزء الثاني',
  'الجزء الثالث',
  'الجزء الرابع',
  'الجزء الخامس',
  'الجزء السادس',
  'الجزء السابع',
  'الجزء الثامن',
  'الجزء التاسع',
  'الجزء العاشر',
  'الجزء الحادي عشر',
  'الجزء الثاني عشر',
  'الجزء الثالث عشر',
  'الجزء الرابع عشر',
  'الجزء الخامس عشر',
  'الجزء السادس عشر',
  'الجزء السابع عشر',
  'الجزء الثامن عشر',
  'الجزء التاسع عشر',
  'الجزء العشرون',
  'الجزء الحادي والعشرون',
  'الجزء الثاني والعشرون',
  'الجزء الثالث والعشرون',
  'الجزء الرابع والعشرون',
  'الجزء الخامس والعشرون',
  'الجزء السادس والعشرون',
  'الجزء السابع والعشرون',
  'الجزء الثامن والعشرون',
  'الجزء التاسع والعشرون',
  'الجزء الثلاثون',
];

/// Official Madani Mushaf quarter/hizb-to-page mapping.
/// Each sublist represents the 7 key quarter/hizb start pages for a Juz:
/// [0] ربع الحزب الأول      → Start of the 1st quarter of the 1st Hizb
/// [1] نصف الحزب الأول      → Start of the half of the 1st Hizb
/// [2] ثلاثة أرباع الحزب الأول → Start of the three-quarters of the 1st Hizb
/// [3] الحزب الثاني         → Start of the 2nd Hizb (also the 1st quarter of the 2nd Hizb)
/// [4] ربع الحزب الثاني     → Start of the 2nd quarter of the 2nd Hizb
/// [5] نصف الحزب الثاني     → Start of the half of the 2nd Hizb
/// [6] ثلاثة أرباع الحزب الثاني → Start of the three-quarters of the 2nd Hizb
const List<List<int>> madaniQuarterHizbPageList = [
  // Juz 1
  [5, 7, 9, 11, 14, 17, 19],
  // Juz 2
  [24, 27, 29, 32, 34, 37, 39],
  // Juz 3
  [44, 46, 49, 51, 54, 56, 59],
  // Juz 4
  [64, 67, 69, 72, 74, 77, 79],
  // Juz 5
  [84, 87, 89, 92, 94, 97, 100],
  // Juz 6
  [104, 106, 109, 112, 114, 117, 119],
  // Juz 7
  [124, 126, 129, 132, 134, 137, 140],
  // Juz 8
  [144, 146, 148, 151, 154, 156, 158],
  // Juz 9
  [164, 167, 170, 173, 175, 177, 179],
  // Juz 10
  [184, 187, 189, 192, 194, 196, 199],
  // Juz 11
  [204, 206, 209, 212, 214, 217, 219],
  // Juz 12
  [224, 226, 228, 231, 233, 236, 238],
  // Juz 13
  [244, 247, 249, 252, 254, 256, 259],
  // Juz 14
  [264, 267, 270, 272, 275, 277, 280],
  // Juz 15
  [284, 287, 289, 292, 295, 297, 299],
  // Juz 16
  [304, 306, 309, 321, 315, 317, 319],
  // Juz 17
  [324, 326, 329, 332, 334, 336, 339],
  // Juz 18
  [344, 347, 350, 352, 354, 356, 359],
  // Juz 19
  [364, 367, 369, 371, 374, 377, 379],
  // Juz 20
  [384, 386, 389, 392, 394, 396, 399],
  // Juz 21
  [404, 407, 410, 413, 415, 418, 420],
  // Juz 22
  [425, 426, 429, 431, 433, 436, 439],
  // Juz 23
  [444, 446, 449, 451, 454, 456, 459],
  // Juz 24
  [464, 467, 469, 472, 474, 477, 479],
  // Juz 25
  [484, 486, 488, 491, 493, 496, 499],
  // Juz 26
  [505, 507, 510, 513, 515, 517, 519],
  // Juz 27
  [524, 526, 529, 531, 534, 536, 539],
  // Juz 28
  [544, 547, 550, 553, 554, 558, 560],
  // Juz 29
  [564, 566, 569, 572, 575, 577, 579],
  // Juz 30
  [585, 587, 589, 591, 594, 596, 599],
];

class JuzListScreen extends StatefulWidget {
  const JuzListScreen({Key? key}) : super(key: key);

  @override
  State<JuzListScreen> createState() => _JuzListScreenState();
}

class _JuzListScreenState extends State<JuzListScreen>
    with AutomaticKeepAliveClientMixin {
  final Set<int> _selectedJuzs = {};
  bool _isSelectionMode = false;

  // Create individual JuzDownloadManager instances
  final Map<int, new_dm.JuzDownloadManager> _juzManagers = {};
  final Map<int, StreamSubscription> _downloadSubscriptions = {};

  // Cache for all Juz progress data to avoid multiple calls
  Map<String, dynamic>? _cachedAllJuzProgress;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(seconds: 1);
  
  // Flag to track if we're currently updating UI to prevent setState during build
  bool _isUpdatingUI = false;

  @override
  void initState() {
    super.initState();
    _initializeJuzManagers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Invalidate cache when dependencies change to ensure fresh data
    _invalidateCache();
  }

  // Invalidate cache to force fresh data fetch
  void _invalidateCache() {
    if (mounted) {
      setState(() {
        _cachedAllJuzProgress = null;
        _lastCacheTime = null;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  void _initializeJuzManagers() {
    for (int juz = 1; juz <= 30; juz++) {
      final folderId = juzFolderIds[juz];
      if (folderId != null) {
        final manager = new_dm.JuzDownloadManager(
          juzNumber: juz,
          folderId: folderId,
        );
        _juzManagers[juz] = manager;
        
        // Listen to download state changes
        _downloadSubscriptions[juz] = manager.downloadStateStream.listen((_) {
          // Invalidate cache when download state changes
          _invalidateCache();
          
          // Only update UI if we're not already in the middle of an update
          if (mounted && !_isUpdatingUI) {
            _isUpdatingUI = true;
            if (mounted) {
              setState(() {
                // Force UI rebuild
              });
            }
            _isUpdatingUI = false;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _downloadSubscriptions.values) {
      subscription.cancel();
    }
    _downloadSubscriptions.clear();
    
    // Dispose all managers
    for (final manager in _juzManagers.values) {
      manager.dispose();
    }
    _juzManagers.clear();
    
    super.dispose();
  }

  void _toggleSelection(int juz) {
    setState(() {
      if (_selectedJuzs.contains(juz)) {
        _selectedJuzs.remove(juz);
      } else {
        _selectedJuzs.add(juz);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedJuzs.clear();
    });
  }

  // Get cached or fresh all Juz progress data
  Future<Map<String, dynamic>> _getAllJuzProgress() async {
    final now = DateTime.now();

    // Return cached data if it's still valid
    if (_cachedAllJuzProgress != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!) < _cacheValidDuration) {
      return _cachedAllJuzProgress!;
    }

    try {
      final allProgress =
          await new_dm.FullQuranDownloadManager.getAllJuzsDownloadProgress();

      // Cache the result
      _cachedAllJuzProgress = allProgress;
      _lastCacheTime = now;

      return allProgress;
    } catch (e) {
      // Return cached data if available, otherwise return empty data
      if (_cachedAllJuzProgress != null) {
        return _cachedAllJuzProgress!;
      }

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

  // Get Juz download progress for a specific Juz from cached data
  Future<Map<String, dynamic>> _getJuzProgress(int juzNumber) async {
    try {
      final allProgress = await _getAllJuzProgress();
      final juzProgress =
          allProgress['juzProgress'] as Map<int, Map<String, dynamic>>;
      final progress = juzProgress[juzNumber];

      if (progress != null) {
        return progress;
      }

      // Fallback if not found
      return {
        'downloaded': false,
        'downloadedPages': 0,
        'totalPages':
            new_dm.FullQuranDownloadManager.getExpectedPageCountForJuz(
                juzNumber),
        'progress': 0.0,
        'fileSize': 0,
      };
    } catch (e) {
      return {
        'downloaded': false,
        'downloadedPages': 0,
        'totalPages':
            new_dm.FullQuranDownloadManager.getExpectedPageCountForJuz(
                juzNumber),
        'progress': 0.0,
        'fileSize': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Call super.build
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    final juzCount = 30;
    final quarters = [
      'ربع الحزب',
      'نصف الحزب',
      'ثلاثة أرباع الحزب',
    ];
    final hizbLabel = 'الحزب';

    // Note: Avoid replacing the whole screen with a global spinner.
    // Each Juz card will reflect its own progress to prevent full-screen rebuild UX issues.

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          title: const Text('قائمة الأجزاء',
              style:
                  TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Cancel Selection',
                    onPressed: _clearSelection,
                  ),
                ]
              : null,
        ),
        body: _isSelectionMode
            ? Stack(
                children: [
                  Positioned.fill(
                    child: ListView.builder(
                      itemCount: juzCount,
                      itemBuilder: (context, index) {
                        final juzNumber = index + 1;
                        final folderId = juzFolderIds[juzNumber]!;

                        return FutureBuilder<Map<String, dynamic>>(
                          future: _getJuzProgress(juzNumber),
                          builder: (context, snapshot) {
                            final manager = _juzManagers[juzNumber];
                            final juzProgress = snapshot.data ??
                                {
                                  'downloaded': false,
                                  'downloadedPages': 0,
                                  'totalPages': new_dm.FullQuranDownloadManager
                                      .getExpectedPageCountForJuz(juzNumber),
                                  'progress': 0.0,
                                  'fileSize': 0,
                                };

                            final isDownloaded =
                                juzProgress['downloaded'] as bool;
                            final downloadedPages =
                                juzProgress['downloadedPages'] as int;
                            final totalPages = juzProgress['totalPages'] as int;
                            final juzProgressValue =
                                juzProgress['progress'] as double;
                            final fileSize = juzProgress['fileSize'] as int;

                            // Reflect per-juz manager runtime state for active download UI
                            final isDownloading = manager?.state.status == new_dm.DownloadStatus.downloading;
                            final isIdle = !isDownloaded && !isDownloading;
                            final isSelected =
                                _selectedJuzs.contains(juzNumber);

                            // Format file size for display
                            String formatFileSize(int bytes) {
                              if (bytes < 1024) return '${bytes}B';
                              if (bytes < 1024 * 1024)
                                return '${(bytes / 1024).toStringAsFixed(1)}KB';
                              return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
                            }

                            final expectedSize =
                                fileSize > 0 ? formatFileSize(fileSize) : "";

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              elevation: isSelected ? 6 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isSelected
                                    ? BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2)
                                    : BorderSide.none,
                              ),
                              child: StreamBuilder<new_dm.DownloadState>(
                                stream: manager?.downloadStateStream,
                                initialData: manager?.state,
                                builder: (context, stateSnap) {
                                  final dState = stateSnap.data ?? manager?.state;
                                  final bool liveIsDownloading =
                                      (dState?.status == new_dm.DownloadStatus.downloading);
                                  final liveProgress = liveIsDownloading == true
                                      ? (dState?.progress ?? juzProgressValue)
                                      : juzProgressValue;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _JuzCard(
                                        juz: juzNumber,
                                        title: 'الجزء ${_arabicNumber(juzNumber)}',
                                        expectedSize: expectedSize,
                                        isSelected: isSelected,
                                        isDownloaded: isDownloaded,
                                        isDownloading: liveIsDownloading,
                                        isPaused: false,
                                        // Drive the progress bar from live manager state when downloading, fallback to FS-based progress
                                        progress: liveProgress,
                                        onTap: isDownloaded
                                            ? () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => JuzViewerScreen(
                                                        juzNumber: juzNumber),
                                                  ),
                                                )
                                            : () {},
                                        onLongPress: () => _toggleSelection(juzNumber),
                                        onDownload: isDownloaded || liveIsDownloading
                                            ? null
                                            : () async {
                                                final m = _juzManagers[juzNumber];
                                                if (m != null) {
                                                  m.start(enableBackground: true);
                                                  _invalidateCache();
                                                }
                                              },
                                        onCancel: null,
                                        onPauseResume: null,
                                        onDelete: isDownloaded
                                            ? () async {
                                                final shouldDelete = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text('Delete Juz $juzNumber'),
                                                    content: const Text('Are you sure you want to delete this Juz?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(false),
                                                        child: const Text('No'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(true),
                                                        child: const Text('Delete'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (shouldDelete == true) {
                                                  final m = _juzManagers[juzNumber];
                                                  if (m != null) {
                                                    await m.delete();
                                                    _invalidateCache();
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Deleted Juz $juzNumber')),
                                                      );
                                                    }
                                                  }
                                                }
                                              }
                                             : null,
                                        onProperties: () {},
                                        fileCount: downloadedPages,
                                        totalFiles: totalPages,
                                        errorMessage: null,
                                        isError: false,
                                        isPending: false,
                                        pendingText: '',
                                      ),
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Text('${_selectedJuzs.length} محدد',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text('تحميل'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              for (final juz in _selectedJuzs) {
                                final folderId = juzFolderIds[juz]!;
                                _juzManagers[juz]!
                                    .start(enableBackground: true);
                              }
                              _clearSelection();
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('حذف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              // Show confirmation dialog for bulk delete
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Selected Juzs'),
                                  content: Text(
                                      'Are you sure you want to delete ${_selectedJuzs.length} selected Juz(s)? '
                                      'This will free up storage space but you will need to download them again to view them.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (shouldDelete == true) {
                                for (final juz in _selectedJuzs) {
                                  final folderId = juzFolderIds[juz]!;
                                  // Add delete logic to QuranDownloadManager if needed
                                  // downloadManager.deleteJuz(juz: juz);
                                }
                                _clearSelection();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : FutureBuilder<Map<String, dynamic>>(
                future: _getAllJuzProgress(),
                initialData: _cachedAllJuzProgress ??
                    {'juzProgress': <int, Map<String, dynamic>>{}},
                builder: (context, snapshot) {
                  // Avoid full-screen spinner: render with initialData while waiting
                  // Only show an error if there is no usable data at all
                  if (snapshot.hasError && snapshot.data == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading Juz data',
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Please try again',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final allJuzProgress = snapshot.data ??
                      {'juzProgress': <int, Map<String, dynamic>>{}};
                  final juzProgress = allJuzProgress['juzProgress']
                      as Map<int, Map<String, dynamic>>;

                  return ListView.builder(
                    itemCount: juzCount,
                    itemBuilder: (context, index) {
                      final juzNumber = index + 1;
                      final downloadState = _juzManagers[juzNumber]!.state;
                      final status = downloadState.status;
                      final error = downloadState.errorMessage;

                      // Get Juz progress from cached data
                      final juzData = juzProgress[juzNumber] ??
                          {
                            'downloaded': false,
                            'downloadedPages': 0,
                            'totalPages': new_dm.FullQuranDownloadManager
                                .getExpectedPageCountForJuz(juzNumber),
                            'progress': 0.0,
                            'fileSize': 0,
                          };

                      final isDownloaded = juzData['downloaded'] as bool;
                      final downloadedPages = juzData['downloadedPages'] as int;
                      final totalPages = juzData['totalPages'] as int;
                      final juzProgressValue = juzData['progress'] as double;
                      final fileSize = juzData['fileSize'] as int;

                      // Use file system status for download detection, but keep manager status for active downloads
                      final isDownloading =
                          status == new_dm.DownloadStatus.downloading;
                      final isIdle = !isDownloaded &&
                          !isDownloading &&
                          (status == new_dm.DownloadStatus.idle ||
                              status == new_dm.DownloadStatus.cancelled);
                      final isSelected = _selectedJuzs.contains(juzNumber);

                      // Format file size for display
                      String formatFileSize(int bytes) {
                        if (bytes < 1024) return '${bytes}B';
                        if (bytes < 1024 * 1024)
                          return '${(bytes / 1024).toStringAsFixed(1)}KB';
                        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
                      }

                      final expectedSize =
                          fileSize > 0 ? formatFileSize(fileSize) : "";

                      final manager = _juzManagers[juzNumber];
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            child: StreamBuilder<new_dm.DownloadState>(
                              stream: manager?.downloadStateStream,
                              initialData: manager?.state,
                              builder: (context, stateSnap) {
                                final dState = stateSnap.data ?? manager?.state;
                                final bool liveIsDownloading =
                                    (dState?.status == new_dm.DownloadStatus.downloading);
                                final liveProgress = liveIsDownloading == true
                                    ? (dState?.progress ?? juzProgressValue)
                                    : juzProgressValue;
                                return _JuzCard(
                                  juz: juzNumber,
                                  title: 'الجزء ${_arabicNumber(juzNumber)}',
                                  expectedSize: expectedSize,
                                  isSelected: isSelected,
                                  isDownloaded: isDownloaded,
                                  isDownloading: liveIsDownloading,
                                  isPaused: false,
                                  progress: liveProgress,
                                  onTap: isDownloaded
                                      ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => JuzViewerScreen(
                                                  juzNumber: juzNumber),
                                            ),
                                          )
                                      : () {},
                                  onLongPress: () => _toggleSelection(juzNumber),
                                  onDownload: (!isDownloaded && (liveIsDownloading != true)) ||
                                          status == new_dm.DownloadStatus.error
                                      ? () {
                                          manager!.start(enableBackground: true);
                                          _invalidateCache();
                                        }
                                      : null,
                                  onCancel: (liveIsDownloading == true) ||
                                          status == new_dm.DownloadStatus.error
                                      ? () {
                                          manager!.cancel();
                                          _invalidateCache();
                                        }
                                      : null,
                                  onPauseResume: null,
                                  onDelete: isDownloaded ||
                                          status == new_dm.DownloadStatus.error ||
                                          (!isDownloaded && liveIsDownloading != true && isIdle)
                                      ? () async {
                                          final shouldDelete = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('Delete Juz $juzNumber'),
                                              content: Text(
                                                  'Are you sure you want to delete Juz $juzNumber? This will free up storage space but you will need to download it again to view it.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('No'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (shouldDelete == true) {
                                            if (manager != null) {
                                              await manager.delete();
                                              _invalidateCache();
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Deleted Juz $juzNumber')),
                                                );
                                              }
                                            }
                                          }
                                        }
                                      : null,
                                  onProperties: () {},
                                  fileCount: downloadedPages,
                                  totalFiles: totalPages,
                                  errorMessage: error,
                                  isError: status == new_dm.DownloadStatus.error,
                                  isPending: status == new_dm.DownloadStatus.idle,
                                  pendingText: '',
                                );
                              },
                            ),
                          ),
                          if (index < juzCount - 1)
                            const Divider(height: 1, thickness: 1),
                        ],
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _JuzDownloadControlsSheet extends StatelessWidget {
  final new_dm.JuzDownloadManager manager;
  final int juzNumber;
  const _JuzDownloadControlsSheet(
      {required this.manager, required this.juzNumber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);
    if (s == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return AnimatedBuilder(
      animation: manager,
      builder: (context, _) {
        final state = manager.state;
        final isDownloading = state.status == new_dm.DownloadStatus.downloading;
        final isCompleted = state.status == new_dm.DownloadStatus.completed;
        final isIdle = state.status == new_dm.DownloadStatus.idle ||
            state.status == new_dm.DownloadStatus.cancelled;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Juz $juzNumber Image Download Controls',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              // Enhanced Progress info for images
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Image Progress'),
                      Text(
                          '${state.downloadedFiles}/${state.totalFiles} images'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: theme.dividerColor.withOpacity(0.1),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  // Show current status message
                  Builder(
                    builder: (context) {
                      String statusMessage =
                          'Downloading: ${state.currentFile}';

                      if (state.status == new_dm.DownloadStatus.cancelled) {
                        if (state.currentFile.contains('Cancelling...')) {
                          statusMessage =
                              'Cancelling... Please wait for current file to finish.';
                        } else {
                          statusMessage = 'Download cancelled.';
                        }
                      } else if (state.status ==
                          new_dm.DownloadStatus.downloading) {
                        statusMessage = 'Downloading: ${state.currentFile}';
                      }

                      return Text(
                        statusMessage,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Juz $juzNumber contains approximately 21 high-quality Quran page images',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (state.status == new_dm.DownloadStatus.error &&
                  state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Image Download Error',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => manager.start(enableBackground: true),
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (isDownloading && state.status != new_dm.DownloadStatus.error)
                ElevatedButton.icon(
                  onPressed: state.currentFile.contains('Cancelling...')
                      ? null
                      : () {
                          manager.cancel();
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.stop),
                  label: Text(s.cancel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),

              if (isCompleted || isIdle)
                ElevatedButton.icon(
                  onPressed: () async {
                    await manager.delete();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete),
                  label: Text('Delete Images'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _arabicNumber(int n) {
  // Converts 1 -> ١, 2 -> ٢, ...
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((d) => arabicDigits[int.parse(d)]).join();
}

// Utility function to get the relative page number within a Juz for a specific quarter/hizb
// quarterIndex mapping:
// [0] ربع الحزب الأول (1st quarter of 1st Hizb)
// [1] نصف الحزب الأول (half of 1st Hizb)
// [2] ثلاثة أرباع الحزب الأول (three-quarters of 1st Hizb)
// [3] الحزب الثاني (2nd Hizb - also 1st quarter of 2nd Hizb)
// [4] ربع الحزب الثاني (2nd quarter of 2nd Hizb)
// [5] نصف الحزب الثاني (half of 2nd Hizb)
// [6] ثلاثة أرباع الحزب الثاني (three-quarters of 2nd Hizb)
// Note: الحزب الأول (First Hizb) button goes to page 0 (start of Juz)
int getRelativePageInJuz(int juzNumber, int quarterIndex) {
  if (juzNumber < 1 || juzNumber > 30) return 0;
  if (quarterIndex < 0 || quarterIndex >= 7) return 0;

  final juzIndex = juzNumber - 1;
  final quarterPages = madaniQuarterHizbPageList[juzIndex];
  final absolutePage = quarterPages[quarterIndex];
  final juzStartPage = juzStartingPages[juzIndex];
  return absolutePage - juzStartPage;
}

class _JuzCard extends StatelessWidget {
  final int juz;
  final String title;
  final String expectedSize;
  final bool isSelected;
  final bool isDownloaded;
  final bool isDownloading;
  final bool isPaused;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onDownload;
  final VoidCallback? onCancel;
  final VoidCallback? onPauseResume;
  final VoidCallback? onDelete;
  final VoidCallback onProperties;
  final int fileCount;
  final int totalFiles;
  final String? errorMessage;
  final bool isError;
  final bool isPending;
  final String pendingText;

  const _JuzCard({
    required this.juz,
    required this.title,
    required this.expectedSize,
    required this.isSelected,
    required this.isDownloaded,
    required this.isDownloading,
    required this.isPaused,
    required this.progress,
    required this.onTap,
    required this.onLongPress,
    this.onDownload,
    this.onCancel,
    this.onPauseResume,
    this.onDelete,
    required this.onProperties,
    required this.fileCount,
    required this.totalFiles,
    required this.errorMessage,
    required this.isError,
    required this.isPending,
    required this.pendingText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = juz - 1;

    // Helper for unavailable tap
    void _showUnavailableSnackBar() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تحميل الجزء أولاً')),
      );
    }

    final bool unavailable = !isDownloaded && !isDownloading;

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thin progress bar at the top if downloading
        if (isDownloading)
          SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: progress > 0 && progress < 1 ? progress : null,
              backgroundColor: theme.dividerColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: unavailable ? _showUnavailableSnackBar : onTap,
                child: Center(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                      fontSize: 24,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (onDownload != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: onDownload,
                  color: theme.colorScheme.primary,
                ),
              )
            else if (onDelete != null)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Table(
            border: TableBorder.all(
              color: theme.dividerColor.withOpacity(0.7),
              width: 1.2,
            ),
            columnWidths: const {
              0: FlexColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth(),
              3: FlexColumnWidth(),
              4: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  _buildJuzTableCell(
                    context,
                    label: 'الحزب ${_arabicNumber((index * 2) + 1)}',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: 0, // Start of Juz
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  _buildJuzTableCell(
                    context,
                    label: 'ربع الحزب',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: getRelativePageInJuz(juz,
                                      0), // ربع الحزب الأول (1st quarter of 1st Hizb)
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  _buildJuzTableCell(
                    context,
                    label: 'نصف الحزب',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: getRelativePageInJuz(juz,
                                      1), // نصف الحزب الأول (half of 1st Hizb)
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  _buildJuzTableCell(
                    context,
                    label: 'ثلاثة أرباع الحزب',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: getRelativePageInJuz(juz,
                                      2), // ثلاثة أرباع الحزب الأول (three-quarters of 1st Hizb)
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: _buildJuzTableCell(
                      context,
                      label: '',
                      onTap: () {},
                      theme: theme,
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  _buildJuzTableCell(
                    context,
                    label: 'الحزب ${_arabicNumber((index * 2) + 2)}',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: getRelativePageInJuz(juz,
                                      3), // الحزب الثاني (2nd Hizb - also 1st quarter of 2nd Hizb)
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  _buildJuzTableCell(
                    context,
                    label: 'ربع الحزب',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: getRelativePageInJuz(juz,
                                      4), // ربع الحزب الثاني (2nd quarter of 2nd Hizb)
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  _buildJuzTableCell(
                    context,
                    label: 'نصف الحزب',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: getRelativePageInJuz(juz,
                                      5), // نصف الحزب الثاني (half of 2nd Hizb)
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  _buildJuzTableCell(
                    context,
                    label: 'ثلاثة أرباع الحزب',
                    onTap: isDownloaded
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => JuzViewerScreen(
                                  juzNumber: juz,
                                  initialPage: getRelativePageInJuz(juz,
                                      6), // ثلاثة أرباع الحزب الثاني (three-quarters of 2nd Hizb)
                                ),
                              ),
                            );
                          }
                        : _showUnavailableSnackBar,
                    theme: theme,
                  ),
                  Container(), // Empty cell to allow the above cell to span two rows
                ],
              ),
            ],
          ),
        ),
      ],
    );

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: cardContent,
          ),
          if (unavailable)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: Colors.grey.withOpacity(0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _buildJuzTableCell(BuildContext context,
    {required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isNumber = false}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48, // Set cell height to 48 for better content fit
      alignment: Alignment.center,
      color: Colors.transparent,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: isNumber ? null : 'Amiri',
          fontWeight: isNumber ? FontWeight.bold : FontWeight.normal,
          fontSize: isNumber ? 18 : 15,
          color: theme.colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
