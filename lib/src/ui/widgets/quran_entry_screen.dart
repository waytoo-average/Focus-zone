// --- Quran Entry Screen ---
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../google_drive_helper.dart';
import 'juz_list_screen.dart';
import 'juz_viewer_screen.dart';
import '../../utils/download_manager.dart';
import '../../../l10n/app_localizations.dart';

const String wholeQuranFolderId = '1jT-vIj8rA7Aed5BzpyPPQBGQFH436tTk';

class QuranEntryScreen extends StatefulWidget {
  const QuranEntryScreen({Key? key}) : super(key: key);

  @override
  State<QuranEntryScreen> createState() => _QuranEntryScreenState();
}

class _QuranEntryScreenState extends State<QuranEntryScreen> {
  final FullQuranDownloadManager _manager = FullQuranDownloadManager();
  String _expectedSize = 'Unknown';
  int _expectedFileCount = 0;
  bool _isLoadingSize = true;

  @override
  void initState() {
    super.initState();
    _loadExpectedSize();
  }

  Future<void> _loadExpectedSize() async {
    setState(() => _isLoadingSize = true);
    try {
      final files =
          await GoogleDriveHelper.listFilesInFolder(wholeQuranFolderId);
      int totalSize = 0;
      for (final file in files) {
        if (file.size != null) {
          totalSize += file.size!;
        }
      }
      final mb = (totalSize / (1024 * 1024)).toStringAsFixed(1);
      if (!mounted) return;
      setState(() {
        _expectedSize = '${mb}MB';
        _expectedFileCount = files.length;
        _isLoadingSize = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _expectedSize = 'Unknown';
        _expectedFileCount = 0;
        _isLoadingSize = false;
      });
    }
  }

  void _handleFullQuranAction() async {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    final state = _manager.state;
    if (state.status == DownloadStatus.completed) {
      openWholeQuranViewer(context);
    } else if (state.status == DownloadStatus.downloading ||
        state.status == DownloadStatus.paused) {
      _showDownloadControls();
    } else {
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.downloadFullQuran),
          content: Text(
              'The full Quran is approximately $_expectedSize and contains $_expectedFileCount pages. '
              'This may take some time to download. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Download'),
            ),
          ],
        ),
      );
      if (shouldDownload == true) {
        _manager.start();
      }
    }
  }

  void _showDownloadControls() {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DownloadControlsSheet(manager: _manager),
    );
  }

  Future<void> _deleteWholeQuran() async {
    final s = AppLocalizations.of(context);
    if (s == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteFullQuran),
        content: const Text('Are you sure you want to delete the full Quran? '
            'This will free up storage space but you will need to download it again to view it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(s.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _manager.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full Quran deleted successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final s = AppLocalizations.of(context);

    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quran")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedBuilder(
      animation: _manager,
      builder: (context, _) {
        final state = _manager.state;
        final isDownloaded = state.status == DownloadStatus.completed;
        final isDownloading = state.status == DownloadStatus.downloading;
        final isPaused = state.status == DownloadStatus.paused;
        final isIdle = state.status == DownloadStatus.idle;
        final isError = state.status == DownloadStatus.error;
        final isCancelled = state.status == DownloadStatus.cancelled;
        final isPending = state.status == DownloadStatus.pausing ||
            state.status == DownloadStatus.cancelling ||
            state.status == DownloadStatus.deleting;
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
                    // Description
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
                        s.quranDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.textTheme.bodyMedium?.color,
                          height: 1.4,
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
                    // Full Quran Card
                    _ModernQuranCard(
                      icon: isDownloaded
                          ? Icons.book
                          : isDownloading
                              ? Icons.pause
                              : isPaused
                                  ? Icons.play_arrow
                                  : Icons.download,
                      title: isDownloaded
                          ? s.viewFullQuran
                          : isDownloading
                              ? s.pauseDownload
                              : isPaused
                                  ? s.resumeDownload
                                  : s.downloadFullQuran,
                      subtitle: isDownloaded
                          ? s.fullQuranReady
                          : isDownloading || isPaused
                              ? "${state.downloadedFiles}/${state.totalFiles} pages (${(state.progress * 100).toInt()}%)"
                              : _isLoadingSize
                                  ? "Loading..."
                                  : "Complete Quran ($_expectedSize)",
                      color: isDownloaded
                          ? Colors.green.shade400
                          : isDownloading
                              ? Colors.orange
                              : isPaused
                                  ? Colors.blue
                                  : theme.colorScheme.secondary,
                      onTap: isPending ? null : _handleFullQuranAction,
                      showProgress: isDownloading || isPaused || isPending,
                      progress: state.progress,
                      showControls: (isDownloading || isPaused) && !isPending,
                      onPauseResume: isPending
                          ? null
                          : () {
                              if (isPaused) {
                                _manager.resume();
                              } else {
                                _manager.pause();
                              }
                            },
                      onCancel: isPending
                          ? null
                          : () {
                              _manager.cancel();
                            },
                      isPaused: isPaused,
                    ),
                    // Spinner and message for pending states
                    if (isPending) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(strokeWidth: 2),
                          const SizedBox(width: 12),
                          Text(
                            state.status == DownloadStatus.pausing
                                ? 'Pausing, please wait...'
                                : state.status == DownloadStatus.cancelling
                                    ? 'Cancelling, please wait...'
                                    : 'Deleting, please wait...',
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Delete Button (if any files are present)
                    if (state.downloadedFiles > 0 &&
                        !isDownloading &&
                        !isPaused &&
                        !isPending) ...[
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
                    // Incomplete Download Warning
                    if (!isDownloaded &&
                        state.downloadedFiles > 0 &&
                        !isDownloading &&
                        !isPaused) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              Colors.orange.withOpacity(isDarkMode ? 0.2 : 0.1),
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
                                      color:
                                          Colors.orange[isDarkMode ? 300 : 700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.pagesDownloaded(state.downloadedFiles,
                                        state.totalFiles),
                                    style: TextStyle(
                                      color:
                                          Colors.orange[isDarkMode ? 400 : 600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _manager.start();
                              },
                              child: Text(s.resume),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isError) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.errorMessage ??
                                    'An error occurred during download.',
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _manager.start();
                              },
                              child: Text(s.retry),
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
    );
  }
}

class _DownloadControlsSheet extends StatelessWidget {
  final FullQuranDownloadManager manager;
  const _DownloadControlsSheet({required this.manager});

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

    final state = manager.state;
    final isPaused = state.status == DownloadStatus.paused;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            s.downloadControls,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          // Progress info
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.progress),
                  Text('${state.downloadedFiles}/${state.totalFiles}'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: theme.dividerColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${s.current} ${state.currentFile}',
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Control buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isPaused) {
                      manager.resume();
                    } else {
                      manager.pause();
                    }
                  },
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(isPaused ? s.resume : 'Pause'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaused ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    manager.cancel();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.stop),
                  label: Text(s.cancel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await manager.delete();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete),
            label: Text(s.deleteDownloadedFiles),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
  final bool isPaused;

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
    this.isPaused = false,
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
                            isPaused ? s.paused : s.downloading,
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
                          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                          label: Text(isPaused ? s.resume : 'Pause'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isPaused ? Colors.green : Colors.orange,
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
