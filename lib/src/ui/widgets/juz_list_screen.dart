import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../google_drive_helper.dart';
import 'juz_viewer_screen.dart';
import '../../utils/juz_download_manager.dart';
import '../../../l10n/app_localizations.dart';

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

class JuzListScreen extends StatefulWidget {
  const JuzListScreen({Key? key}) : super(key: key);

  @override
  State<JuzListScreen> createState() => _JuzListScreenState();
}

class _JuzListScreenState extends State<JuzListScreen> {
  final Set<int> _selectedJuzs = {};
  bool _isSelectionMode = false;

  // One manager per Juz
  final Map<int, JuzDownloadManager> _juzManagers = {};

  // Holds the expected download size for each Juz
  final Map<int, String> _expectedSizes = {};
  bool _isLoadingStatuses = true; // To show initial loading indicator

  // Cache keys for SharedPreferences
  static const String _expectedSizesKey = 'juz_expected_sizes';

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  @override
  void dispose() {
    for (final manager in _juzManagers.values) {
      manager.dispose();
    }
    _juzManagers.clear();
    super.dispose();
  }

  JuzDownloadManager _getManager(int juz) {
    if (!_juzManagers.containsKey(juz)) {
      _juzManagers[juz] = JuzDownloadManager(
        juzNumber: juz,
        folderId: juzFolderIds[juz]!,
      );
    }
    return _juzManagers[juz]!;
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSizes = prefs.getString(_expectedSizesKey);
    if (cachedSizes != null) {
      final Map<String, dynamic> sizesMap = json.decode(cachedSizes);
      setState(() {
        for (final entry in sizesMap.entries) {
          _expectedSizes[int.parse(entry.key)] = entry.value;
        }
        _isLoadingStatuses = false;
      });
      // Update in background
      _loadExpectedSizes(background: true);
    } else {
      await _loadExpectedSizes();
    }
  }

  Future<void> _loadExpectedSizes({bool background = false}) async {
    bool finished = false;
    Future<void> loadAll() async {
      for (int juz = 1; juz <= 30; juz++) {
        try {
          final folderId = juzFolderIds[juz]!;
          final files = await GoogleDriveHelper.listFilesInFolder(folderId);
          int totalSize = 0;
          for (final file in files) {
            if (file.size != null) {
              totalSize += file.size!;
            }
          }
          final mb = (totalSize / (1024 * 1024)).toStringAsFixed(1);
          if (!mounted) return;
          setState(() {
            _expectedSizes[juz] = '${mb}MB';
          });
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _expectedSizes[juz] = 'Unknown';
          });
        }
      }
      finished = true;
    }

    // Timeout after 10 seconds
    await Future.any([
      loadAll(),
      Future.delayed(const Duration(seconds: 10)),
    ]);
    if (!mounted) return;
    setState(() {
      _isLoadingStatuses = false;
    });
    await _cacheExpectedSizes();
  }

  Future<void> _cacheExpectedSizes() async {
    final prefs = await SharedPreferences.getInstance();
    final sizesMap = <String, String>{};
    for (final entry in _expectedSizes.entries) {
      sizesMap[entry.key.toString()] = entry.value;
    }
    await prefs.setString(_expectedSizesKey, json.encode(sizesMap));
  }

  void _toggleSelection(int juz) {
    setState(() {
      if (_selectedJuzs.contains(juz)) {
        _selectedJuzs.remove(juz);
      } else {
        _selectedJuzs.add(juz);
      }
      _isSelectionMode = _selectedJuzs.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedJuzs.clear();
      _isSelectionMode = false;
    });
  }

  void _handleTap(int juz) {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    if (_isSelectionMode) {
      _toggleSelection(juz);
    } else {
      final manager = _getManager(juz);
      if (manager.state.status == JuzDownloadStatus.completed) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JuzViewerScreen(juzNumber: juz),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Juz $juz is not downloaded.')),
        );
      }
    }
  }

  Future<void> _performBatchOperation(
      Future<void> Function(int) operation) async {
    final selection = Set<int>.from(_selectedJuzs);
    _clearSelection();
    for (final juz in selection) {
      await operation(juz);
    }
  }

  void _showJuzProperties(int juz) {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final manager = _getManager(juz);
        return FutureBuilder<Map<String, dynamic>>(
          future: manager.getDownloadInfo(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: Text(s.error),
                content: const Text('Could not load properties.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(s.ok),
                  ),
                ],
              );
            }
            final info = snapshot.data!;
            final expectedSize = _expectedSizes[juz] ?? 'Unknown';
            return AlertDialog(
              title: Text('${s.juzProperties} $juz'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.fileCount}: ${info['fileCount']}'),
                  const SizedBox(height: 8),
                  Text(
                      '${s.totalSize}: ${(info['totalSize'] / (1024 * 1024)).toStringAsFixed(1)}MB'),
                  const SizedBox(height: 8),
                  Text('${s.totalSize}: $expectedSize'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(s.close),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppLocalizations.of(context);

    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Browse Juzs")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.juzListTitle),
        backgroundColor: theme.colorScheme.secondary,
        foregroundColor: Colors.white,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: _isLoadingStatuses
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isSelectionMode) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: theme.primaryColor.withOpacity(0.1),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedJuzs.length} selected',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _performBatchOperation(
                              (juz) async => _getManager(juz).start()),
                          icon: const Icon(Icons.download),
                          label: Text(s.downloadSelected),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _performBatchOperation(
                              (juz) async => _getManager(juz).delete()),
                          icon: const Icon(Icons.delete),
                          label: Text(s.deleteSelected),
                          style:
                              TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: 30,
                    itemBuilder: (context, index) {
                      final juz = index + 1;
                      final manager = _getManager(juz);
                      return AnimatedBuilder(
                        animation: manager,
                        builder: (context, _) {
                          final state = manager.state;
                          final isDownloaded =
                              state.status == JuzDownloadStatus.completed;
                          final isDownloading =
                              state.status == JuzDownloadStatus.downloading;
                          final isPaused =
                              state.status == JuzDownloadStatus.paused;
                          final isError =
                              state.status == JuzDownloadStatus.error;
                          final isPending = state.status ==
                                  JuzDownloadStatus.pausing ||
                              state.status == JuzDownloadStatus.cancelling ||
                              state.status == JuzDownloadStatus.deleting;
                          return _JuzCard(
                            juz: juz,
                            title: juzHeaders[juz - 1],
                            expectedSize: _expectedSizes[juz] ?? 'Unknown',
                            isSelected: _selectedJuzs.contains(juz),
                            isDownloaded: isDownloaded,
                            isDownloading: isDownloading,
                            isPaused: isPaused,
                            progress: state.progress,
                            onTap: () => _handleTap(juz),
                            onLongPress: () => _toggleSelection(juz),
                            onDownload:
                                isPending ? null : () => manager.start(),
                            onCancel: isPending ? null : () => manager.cancel(),
                            onPauseResume: isPending
                                ? null
                                : () {
                                    if (isPaused) {
                                      manager.resume();
                                    } else {
                                      manager.pause();
                                    }
                                  },
                            onDelete: isPending ? null : () => manager.delete(),
                            onProperties: () => _showJuzProperties(juz),
                            fileCount: state.downloadedFiles,
                            totalFiles: state.totalFiles,
                            errorMessage: state.errorMessage,
                            isError: isError,
                            isPending: isPending,
                            pendingText: state.status ==
                                    JuzDownloadStatus.pausing
                                ? 'Pausing...'
                                : state.status == JuzDownloadStatus.cancelling
                                    ? 'Cancelling...'
                                    : state.status == JuzDownloadStatus.deleting
                                        ? 'Deleting...'
                                        : '',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
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
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? theme.primaryColor.withOpacity(0.1) : theme.cardColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getJuzColor(theme).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$juz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _getJuzColor(theme),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.primaryColor,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                isDownloaded ? '$fileCount/$totalFiles pages' : expectedSize,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              if (isPending) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pendingText,
                      style: const TextStyle(
                          fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ] else if (isDownloading || isPaused) ...[
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: theme.dividerColor.withOpacity(0.1),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_getJuzColor(theme)),
                  minHeight: 3,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton.icon(
                          onPressed: onPauseResume,
                          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause,
                              size: 14),
                          label: Text(
                            isPaused ? 'Resume' : 'Pause',
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isPaused ? Colors.green : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: IconButton(
                        onPressed: onCancel,
                        icon: const Icon(Icons.stop, size: 14),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (isDownloaded) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton.icon(
                          onPressed: onTap,
                          icon: const Icon(Icons.visibility, size: 14),
                          label: const Text(
                            'View',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'properties':
                              onProperties();
                              break;
                            case 'delete':
                              if (onDelete != null) onDelete!();
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'properties',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16),
                                SizedBox(width: 8),
                                Text('Properties',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          if (fileCount > 0)
                            PopupMenuItem(
                              value: 'delete',
                              enabled: onDelete != null,
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: onDelete != null
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 16),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(
                                          color: onDelete != null
                                              ? Colors.red
                                              : Colors.grey,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                        ],
                        child: const Icon(Icons.more_vert, size: 16),
                      ),
                    ),
                  ],
                ),
              ] else if (isError) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage ?? 'An error occurred.',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: onDownload,
                        child:
                            const Text('Retry', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ] else if (fileCount > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: ElevatedButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download, size: 14),
                          label: const Text(
                            'Resume',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 28,
                      width: 28,
                      child: IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 16),
                        tooltip: 'Delete',
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  height: 28,
                  child: ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text(
                      'Download',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getJuzColor(ThemeData theme) {
    if (isDownloaded) return Colors.green;
    if (isDownloading) return Colors.orange;
    if (isPaused) return Colors.blue;
    if (isPending) return Colors.grey;
    return theme.colorScheme.secondary;
  }
}
