// --- Download State & Managers ---
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../google_drive_helper.dart';
import '../../../notification_manager.dart';

// --- Download Status Enum ---
enum DownloadStatus {
  idle,
  downloading,
  pausing,
  paused,
  cancelling,
  cancelled,
  deleting,
  completed,
  error,
  networkError, // New status for network issues
}

// --- Download State Data ---
class DownloadState {
  final DownloadStatus status;
  final int downloadedFiles;
  final int totalFiles;
  final double progress;
  final String currentFile;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;
  final bool isNetworkError; // New field for network error tracking

  const DownloadState({
    required this.status,
    required this.downloadedFiles,
    required this.totalFiles,
    required this.progress,
    required this.currentFile,
    required this.downloadedBytes,
    required this.totalBytes,
    this.errorMessage,
    this.isNetworkError = false,
  });

  DownloadState copyWith({
    DownloadStatus? status,
    int? downloadedFiles,
    int? totalFiles,
    double? progress,
    String? currentFile,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    bool? isNetworkError,
  }) {
    return DownloadState(
      status: status ?? this.status,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      progress: progress ?? this.progress,
      currentFile: currentFile ?? this.currentFile,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      isNetworkError: isNetworkError ?? this.isNetworkError,
    );
  }

  static DownloadState initial() => const DownloadState(
        status: DownloadStatus.idle,
        downloadedFiles: 0,
        totalFiles: 0,
        progress: 0.0,
        currentFile: '',
        downloadedBytes: 0,
        totalBytes: 0,
        errorMessage: null,
        isNetworkError: false,
      );

  Map<String, dynamic> toJson() => {
        'status': status.index,
        'downloadedFiles': downloadedFiles,
        'totalFiles': totalFiles,
        'progress': progress,
        'currentFile': currentFile,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'errorMessage': errorMessage,
        'isNetworkError': isNetworkError,
      };

  static DownloadState fromJson(Map<String, dynamic> json) {
    return DownloadState(
      status: DownloadStatus.values[json['status'] ?? 0],
      downloadedFiles: json['downloadedFiles'] ?? 0,
      totalFiles: json['totalFiles'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      currentFile: json['currentFile'] ?? '',
      downloadedBytes: json['downloadedBytes'] ?? 0,
      totalBytes: json['totalBytes'] ?? 0,
      errorMessage: json['errorMessage'],
      isNetworkError: json['isNetworkError'] ?? false,
    );
  }
}

// --- Base Download Manager ---
abstract class BaseDownloadManager with ChangeNotifier {
  // Abstract methods that must be implemented by subclasses
  // Abstract methods that must be implemented by subclasses
  @protected
  Future<List<MapEntry<String, String>>> _getFilesToDownload();

  @protected
  String _getFileSavePath(String fileName);

  final String folderId;
  final String localFolderName;
  final int concurrentDownloads;
  final String prefsKey;

  DownloadState _state = DownloadState.initial();
  DownloadState get state => _state;

  // Add stream controller for real-time progress updates
  final StreamController<DownloadState> _progressController =
      StreamController<DownloadState>.broadcast();
  Stream<DownloadState> get progressStream => _progressController.stream;

  // Expose state changes as a broadcast stream
  final StreamController<DownloadState> _stateController =
      StreamController<DownloadState>.broadcast();
  Stream<DownloadState> get downloadStateStream => _stateController.stream;

  bool _isCancelled = false;
  bool _isPaused = false;
  bool _isActive = false;
  bool _isDisposed = false;
  List<DriveFile>? _allFiles;
  Directory? _downloadDir;

  // Lazy initialize Dio only when needed
  Dio? _httpClient;
  Dio get _dio => _httpClient ??= Dio();

  // Background download support
  bool _isBackgroundEnabled = false;
  Timer? _backgroundTimer;
  Timer? _networkCheckTimer;

  // Public getter for background enabled state
  bool get isBackgroundEnabled => _isBackgroundEnabled;

  // Public setter for background enabled state
  set isBackgroundEnabled(bool value) {
    _isBackgroundEnabled = value;
  }

  // Public methods for background monitoring
  void startBackgroundMonitoring() {
    _startBackgroundMonitoring();
  }

  void startNetworkMonitoring() {
    _startNetworkMonitoring();
  }

  BaseDownloadManager({
    required String folderId,
    required String localFolderName,
    required int concurrentDownloads,
    required String prefsKey,
  })  : folderId = folderId,
        localFolderName = localFolderName,
        concurrentDownloads = concurrentDownloads,
        prefsKey = prefsKey {
    // Initialize state
    _state = DownloadState.initial();
    // Load saved state if available
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedState = prefs.getString(prefsKey);
      if (savedState != null) {
        _state = DownloadState.fromJson(
            Map<String, dynamic>.from(jsonDecode(savedState)));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved state: $e');
    }
  }

  static Map<String, dynamic> _decodeJson(String jsonStr) =>
      Map<String, dynamic>.from(jsonDecode(jsonStr));

  @mustCallSuper
  void dispose() {
    _isDisposed = true;
    _backgroundTimer?.cancel();
    _networkCheckTimer?.cancel();
    _progressController.close();
    super.dispose();
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(prefsKey);

    if (jsonStr != null) {
      try {
        final json =
            Map<String, dynamic>.from(await compute(_decodeJson, jsonStr));

        // Load background flag
        _isBackgroundEnabled = json['isBackgroundEnabled'] ?? false;

        // Create state without background flag
        final stateJson = Map<String, dynamic>.from(json);
        stateJson.remove('isBackgroundEnabled');
        stateJson.remove('lastUpdated');

        final loadedState = DownloadState.fromJson(stateJson);

        // Restore background monitoring if it was enabled
        if (_isBackgroundEnabled &&
            loadedState.status == DownloadStatus.downloading) {
          _startBackgroundMonitoring();
        }

        _state = loadedState;
        notifyListeners();
      } catch (_) {
        _state = DownloadState.initial();
        notifyListeners();
      }
    }
  }

  Future<void> saveState() async {
    if (_isDisposed) return;
    final prefs = await SharedPreferences.getInstance();

    // Save state with background flag
    final stateData = {
      ..._state.toJson(),
      'isBackgroundEnabled': _isBackgroundEnabled,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await prefs.setString(prefsKey, jsonEncode(stateData));
  }

  void start({bool enableBackground = false}) {
    if (_isActive || _state.status == DownloadStatus.downloading) return;

    _isBackgroundEnabled = enableBackground;
    _isCancelled = false;
    _isPaused = false;
    _isActive = true;

    // Immediately update state to downloading so UI updates right away
    _updateState(_state.copyWith(status: DownloadStatus.downloading));

    // Start background monitoring if enabled
    if (enableBackground) {
      _startBackgroundMonitoring();
      _startNetworkMonitoring();
    }

    // Use compute for background processing
    _downloadConcurrent();
  }

  // Add network monitoring
  void _startNetworkMonitoring() {
    _networkCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      // Only check network if we're in error state or downloading
      if (_state.status == DownloadStatus.error ||
          _state.status == DownloadStatus.networkError ||
          _state.status == DownloadStatus.downloading) {
        final connectivity = await Connectivity().checkConnectivity();
        final hasConnection = connectivity != ConnectivityResult.none;

        if (!hasConnection && _state.status == DownloadStatus.downloading) {
          // Network lost while downloading - pause and set network error
          _updateState(_state.copyWith(
            status: DownloadStatus.networkError,
            errorMessage: 'Network connection lost',
            isNetworkError: true,
          ));
        } else if (hasConnection &&
            _state.status == DownloadStatus.networkError) {
          // Network restored - resume download
          _updateState(_state.copyWith(
            status: DownloadStatus.downloading,
            errorMessage: null,
            isNetworkError: false,
          ));

          // Restart download if it was active
          if (_isActive && !_isCancelled && !_isPaused) {
            _downloadConcurrent(resume: true);
          }
        }
      }
    });
  }

  void pause() {
    if (_state.status == DownloadStatus.downloading) {
      _isPaused = true;
      _updateState(_state.copyWith(status: DownloadStatus.pausing));
    } else {
      print('❌ Cannot pause: not downloading (status: ${_state.status})');
    }
  }

  void resume() {
    if (_state.status == DownloadStatus.paused) {
      _isPaused = false;
      _isCancelled = false;
      if (!_isActive) {
        _isActive = true;
        _updateState(_state.copyWith(status: DownloadStatus.downloading));
        _downloadConcurrent(resume: true);
      }
    } else {
      print('❌ Cannot resume: not paused (status: ${_state.status})');
    }
  }

  void cancel() {
    print('❌ Cancelling download...');
    _isCancelled = true;
    _isPaused = false;
    _isActive = false;

    // Preserve the current state but mark as cancelled
    final currentState = _state;
    _updateState(currentState.copyWith(status: DownloadStatus.cancelled));

    // Don't clear the cached info - keep the download progress
    // This prevents the UI from showing "unknown" after cancellation
  }

  void _updateState(DownloadState newState) {
    if (_isDisposed) return;
    _state = newState;
    // Safely emit to streams; ignore if a controller was closed elsewhere
    try {
      _progressController.add(newState);
    } catch (_) {}
    try {
      _stateController.add(newState);
    } catch (_) {}
    if (!_isDisposed) {
      notifyListeners();
      saveState();
    }

    // Trigger notification update if background is enabled
    if (_isBackgroundEnabled) {
      _triggerNotificationUpdate();
    }
  }

  // Notification methods that can be called from UI
  void _triggerNotificationUpdate() {
    // This will be called by the UI to update notifications
    // The actual notification update will be handled in the UI layer
  }

  void showNotification(BuildContext context) {
    if (_isBackgroundEnabled) {
      NotificationManager.showQuranDownloadNotification(context);
    }
  }

  void updateNotification(BuildContext context) {
    if (_isBackgroundEnabled) {
      final title = _getDownloadTitle();
      final body = _getDownloadSubtitle();
      final progress = (_state.progress * 100).toInt();
      NotificationManager.updateQuranDownloadNotification(context, title, body,
          progress: progress);
    }
  }

  void hideNotification(BuildContext context) {
    NotificationManager.hideQuranDownloadNotification(context);
  }

  // Method to force notification update after actions
  void forceNotificationUpdate(BuildContext context) {
    if (_isBackgroundEnabled) {
      // Small delay to ensure state is updated
      Future.delayed(const Duration(milliseconds: 100), () {
        updateNotification(context);
      });
    }
  }

  Future<void> delete() async {
    _updateState(_state.copyWith(status: DownloadStatus.deleting));
    try {
      // Delete from both possible locations to prevent duplicates
      final appDir = await getApplicationDocumentsDirectory();

      // Delete from juz-specific directory if this is a juz download
      if (this is JuzDownloadManager) {
        final juzNumber = (this as JuzDownloadManager).juzNumber;
        final juzDir = Directory('${appDir.path}/quran_juz_$juzNumber');
        if (await juzDir.exists()) {
          await juzDir.delete(recursive: true);
        }
      }

      // Also clean up from full quran directory
      final fullDir = Directory('${appDir.path}/quran_full');
      if (await fullDir.exists()) {
        await fullDir.delete(recursive: true);
      }

      // Update cache info
      await cacheQuranDownloadInfo(
        isFullQuran: this is FullQuranDownloadManager,
        downloaded: false,
        fileSize: 0,
        pageCount: 0,
        juzNumber: this is JuzDownloadManager
            ? (this as JuzDownloadManager).juzNumber
            : null,
      );

      _updateState(DownloadState.initial());
    } catch (e) {
      _updateState(_state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Failed to delete: $e',
      ));
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (_downloadDir != null) return _downloadDir!;

    if (Platform.isAndroid || Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      _downloadDir = Directory('${appDir.path}/quran_full');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      _downloadDir = Directory('${appDir.path}/quran_full');
    }
    if (!await _downloadDir!.exists()) {
      await _downloadDir!.create(recursive: true);
    }
    return _downloadDir!;
  }

  Future<Map<String, dynamic>> getDownloadInfo() async {
    try {
      final dir = await _getDownloadDirectory();
      if (!await dir.exists()) {
        return {'fileCount': 0, 'totalSize': 0};
      }

      int fileCount = 0;
      int totalSize = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          fileCount++;
          totalSize += await entity.length();
        }
      }
      return {'fileCount': fileCount, 'totalSize': totalSize};
    } catch (e) {
      return {'fileCount': 0, 'totalSize': 0};
    }
  }

  // Enhanced download method with better background support
  Future<void> _downloadConcurrent({bool resume = false}) async {
    try {
      _updateState(_state.copyWith(status: DownloadStatus.downloading));

      if (_allFiles == null) {
        _allFiles = await GoogleDriveHelper.listFilesInFolder(folderId);
      }

      if (_allFiles == null || _allFiles!.isEmpty) {
        _updateState(_state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'No files found in folder',
        ));
        return;
      }

      final dir = await _getDownloadDirectory();
      final filesToDownload = <DriveFile>[];

      for (final file in _allFiles!) {
        final targetFile = File('${dir.path}/${file.name}');
        final exists = await targetFile.exists();
        if (!exists) {
          filesToDownload.add(file);
          continue;
        }
        // Validate existing file by size and magic bytes; if mismatches, re-download
        try {
          final localLen = await targetFile.length();
          final remoteLen = file.size ?? -1;
          final raf = await targetFile.open();
          final header = await raf.read(8);
          await raf.close();
          final isJpeg = header.length >= 3 && header[0] == 0xFF && header[1] == 0xD8;
          final isPng = header.length >= 8 &&
              header[0] == 0x89 &&
              header[1] == 0x50 &&
              header[2] == 0x4E &&
              header[3] == 0x47 &&
              header[4] == 0x0D &&
              header[5] == 0x0A &&
              header[6] == 0x1A &&
              header[7] == 0x0A;
          final magicOk = isJpeg || isPng;
          if ((remoteLen <= 0 || localLen == remoteLen) && magicOk) {
            // Looks complete, skip
          } else {
            filesToDownload.add(file);
          }
        } catch (_) {
          filesToDownload.add(file);
        }
      }

      if (filesToDownload.isEmpty) {
        _updateState(_state.copyWith(
          status: DownloadStatus.completed,
          downloadedFiles: _allFiles!.length,
          totalFiles: _allFiles!.length,
          progress: 1.0,
        ));
        await cacheQuranDownloadInfo(
          isFullQuran: this is FullQuranDownloadManager,
          downloaded: true,
          fileSize: await _getTotalSize(),
          pageCount: _allFiles!.length,
          juzNumber: this is JuzDownloadManager
              ? (this as JuzDownloadManager).juzNumber
              : null,
        );
        return;
      }

      // Preserve original total files count when resuming
      final originalTotalFiles = resume ? _state.totalFiles : _allFiles!.length;
      final totalFiles = resume ? originalTotalFiles : filesToDownload.length;

      // Calculate initial progress when resuming
      int initialDownloadedFiles = 0;
      int initialDownloadedBytes = 0;

      if (resume) {
        for (final file in _allFiles!) {
          final localFile = File('${dir.path}/${file.name}');
          if (await localFile.exists()) {
            initialDownloadedFiles++;
            initialDownloadedBytes += await localFile.length();
          }
        }
      }

      int downloadedFiles = initialDownloadedFiles;
      int downloadedBytes = initialDownloadedBytes;
      int totalBytes = 0;

      for (final file in filesToDownload) {
        totalBytes += file.size ?? 0;
      }
      totalBytes += initialDownloadedBytes;

      _updateState(_state.copyWith(
        totalFiles: totalFiles,
        totalBytes: totalBytes,
        downloadedFiles: downloadedFiles,
        downloadedBytes: downloadedBytes,
        progress: downloadedFiles / totalFiles,
      ));

      // RESTORED: Concurrent download with semaphore
      final semaphore = Completer<void>();
      int activeDownloads = 0;

      Future<void> downloadFile(DriveFile file) async {
        if (_isCancelled || _isPaused) return;

        try {
          activeDownloads++;
          final targetFile = File('${dir.path}/${file.name}');
          final tempFile = File('${dir.path}/${file.name}.part');

          if (await targetFile.exists()) {
            downloadedFiles++;
            downloadedBytes += await targetFile.length();
            _updateState(_state.copyWith(
              downloadedFiles: downloadedFiles,
              downloadedBytes: downloadedBytes,
              progress: downloadedFiles / totalFiles,
              currentFile: file.name,
            ));
            return;
          }

          _updateState(_state.copyWith(currentFile: file.name));

          // Use direct download instead of compute so it can be interrupted
          final dio = Dio();
          dio.options.connectTimeout = const Duration(seconds: 30);
          dio.options.receiveTimeout = const Duration(seconds: 60);
          dio.options.sendTimeout = const Duration(seconds: 30);

          try {
            // Ensure no stale temp file
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
            final response = await dio.download(
              'https://drive.usercontent.google.com/download?id=${file.id}&export=download',
              tempFile.path,
              onReceiveProgress: (received, total) {
                // Check for pause/cancel during download
                if (_isCancelled || _isPaused) {
                  throw Exception('Download interrupted');
                }
              },
            );

            if (response.statusCode == 200) {
              // Validate magic bytes before finalizing
              bool magicOk = false;
              try {
                final raf = await tempFile.open();
                final header = await raf.read(8);
                await raf.close();
                final isJpeg = header.length >= 3 && header[0] == 0xFF && header[1] == 0xD8;
                final isPng = header.length >= 8 &&
                    header[0] == 0x89 &&
                    header[1] == 0x50 &&
                    header[2] == 0x4E &&
                    header[3] == 0x47 &&
                    header[4] == 0x0D &&
                    header[5] == 0x0A &&
                    header[6] == 0x1A &&
                    header[7] == 0x0A;
                magicOk = isJpeg || isPng;
              } catch (_) {
                magicOk = false;
              }

              if (!magicOk) {
                // Treat as failed download so it will retry next run
                throw Exception('Invalid image data (bad magic header)');
              }

              downloadedFiles++;
              // Atomically move completed temp file into place
              if (await targetFile.exists()) {
                await targetFile.delete();
              }
              await tempFile.rename(targetFile.path);
              downloadedBytes += await targetFile.length();
              _updateState(_state.copyWith(
                downloadedFiles: downloadedFiles,
                downloadedBytes: downloadedBytes,
                progress: downloadedFiles / totalFiles,
                currentFile: file.name,
              ));
            }
          } catch (e) {
            if (_isCancelled || _isPaused) {
              // Download was intentionally interrupted
              // Clean up partial temp file
              try {
                if (await tempFile.exists()) {
                  await tempFile.delete();
                }
              } catch (_) {}
              return;
            }
            throw e; // Re-throw other errors
          }
        } catch (e) {
          if (!_isCancelled) {
            final errorString = e.toString().toLowerCase();
            final isNetworkError = errorString.contains('socketexception') ||
                errorString.contains('timeoutexception') ||
                errorString.contains('connection') ||
                errorString.contains('network') ||
                errorString.contains('dioerror');

            if (isNetworkError) {
              _updateState(_state.copyWith(
                status: DownloadStatus.networkError,
                errorMessage: 'Network connection lost',
                isNetworkError: true,
              ));
            } else {
              final currentState = _state;
              _updateState(currentState.copyWith(
                status: DownloadStatus.error,
                errorMessage: 'Failed to download ${file.name}: $e',
              ));
            }
          }
        } finally {
          activeDownloads--;
          if (activeDownloads == 0 && semaphore.isCompleted == false) {
            semaphore.complete();
          }
          // On any non-success path, ensure temp file is removed
          try {
            final tempPath = '${dir.path}/${file.name}.part';
            final f = File(tempPath);
            if (await f.exists()) {
              await f.delete();
            }
          } catch (_) {}
        }
      }

      // Start concurrent downloads
      final futures = <Future<void>>[];
      for (int i = 0;
          i < concurrentDownloads && i < filesToDownload.length;
          i++) {
        futures.add(downloadFile(filesToDownload[i]));
      }

      int nextFileIndex = concurrentDownloads;
      int currentFutureIndex = 0;
      while (currentFutureIndex < futures.length) {
        await futures[currentFutureIndex];
        currentFutureIndex++;
        if (_isCancelled || _isPaused) break;
        if (nextFileIndex < filesToDownload.length) {
          futures.add(downloadFile(filesToDownload[nextFileIndex++]));
        }
      }

      await semaphore.future;

      if (_isCancelled) {
        _updateState(_state.copyWith(status: DownloadStatus.cancelled));
      } else if (_isPaused) {
        _updateState(_state.copyWith(status: DownloadStatus.paused));
      } else if (downloadedFiles == totalFiles) {
        _updateState(_state.copyWith(status: DownloadStatus.completed));
        await cacheQuranDownloadInfo(
          isFullQuran: this is FullQuranDownloadManager,
          downloaded: true,
          fileSize: await _getTotalSize(),
          pageCount: _allFiles!.length,
          juzNumber: this is JuzDownloadManager
              ? (this as JuzDownloadManager).juzNumber
              : null,
        );
      }
    } catch (e) {
      if (!_isCancelled) {
        final errorString = e.toString().toLowerCase();
        final isNetworkError = errorString.contains('socketexception') ||
            errorString.contains('timeoutexception') ||
            errorString.contains('connection') ||
            errorString.contains('network') ||
            errorString.contains('dioerror');

        if (isNetworkError) {
          _updateState(_state.copyWith(
            status: DownloadStatus.networkError,
            errorMessage: 'Network connection lost',
            isNetworkError: true,
          ));
        } else {
          final currentState = _state;
          _updateState(currentState.copyWith(
            status: DownloadStatus.error,
            errorMessage: 'Download failed: $e',
          ));
        }
      }
    } finally {
      _isActive = false;
    }
  }

  Future<int> _getTotalSize() async {
    final dir = await _getDownloadDirectory();
    if (!await dir.exists()) return 0;
    int totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  String _getDownloadTitle() {
    if (this is FullQuranDownloadManager) {
      return 'Quran Download';
    } else if (this is JuzDownloadManager) {
      final juzNumber = (this as JuzDownloadManager).juzNumber;
      return 'Juz $juzNumber Download';
    }
    return 'Download';
  }

  String _getDownloadSubtitle() {
    final progress = (_state.progress * 100).toInt();
    final status = _state.status;

    switch (status) {
      case DownloadStatus.downloading:
        return 'Downloading... $progress% (${_state.downloadedFiles}/${_state.totalFiles})';
      case DownloadStatus.pausing:
        return 'Pausing... $progress%';
      case DownloadStatus.paused:
        return 'Paused - $progress% (${_state.downloadedFiles}/${_state.totalFiles})';
      case DownloadStatus.cancelling:
        return 'Cancelling...';
      case DownloadStatus.cancelled:
        return 'Cancelled';
      case DownloadStatus.completed:
        return 'Download Complete!';
      case DownloadStatus.error:
        return 'Download Error';
      case DownloadStatus.networkError:
        return 'Network Error - Waiting for connection...';
      default:
        return 'Preparing...';
    }
  }

  void _startBackgroundMonitoring() {
    _backgroundTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isDisposed || _state.status == DownloadStatus.completed) {
        timer.cancel();
        return;
      }

      await saveState();
    });
  }
}

// --- Juz Download Manager ---
class JuzDownloadManager extends BaseDownloadManager {
  final int juzNumber;
  bool _isInitialized = false;

  // This field is intentionally unused as it's only used in the base class
  // ignore: unused_field
  final Dio? _httpClient = null;

  static const List<int> _juzStartingPages = [
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

  JuzDownloadManager({required this.juzNumber, required String folderId})
      : super(
          folderId: folderId,
          localFolderName: 'quran_juz_$juzNumber',
          concurrentDownloads: 3,
          prefsKey: 'juz_download_state_$juzNumber',
        ) {
    _initialize();
  }

  // Get directory for this juz - handled by base class
  // This method is intentionally empty as the base class handles directory creation
  
  // Override to save Juz files under a juz-specific directory that matches
  // the progress scanner (quran_juz_<juzNumber>) used by the UI.
  @override
  Future<Directory> _getDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/quran_juz_$juzNumber');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load existing state
    await loadState();

    // If we were downloading, reset to idle
    if (_state.status == DownloadStatus.downloading) {
      _updateState(_state.copyWith(
        status: DownloadStatus.idle,
        progress: 0,
        currentFile: '',
      ));
    }
  }

  @override
  Future<List<MapEntry<String, String>>> _getFilesToDownload() async {
    try {
      final files = await GoogleDriveHelper.listFilesInFolder(folderId);

      // Filter only image files for this juz and map to (id, name) pairs
      final juzFiles = <MapEntry<String, String>>[];
      for (final file in files) {
        final fileName = file.name ?? '';
        if (fileName.isEmpty) continue;

        final pageNumber = _extractPageNumber(fileName);
        if (pageNumber > 0 && _isPageInJuz(pageNumber)) {
          final fileId = file.id ?? '';
          if (fileId.isNotEmpty) {
            juzFiles.add(MapEntry(fileId, fileName));
          }
        }
      }

      return juzFiles;
    } catch (e) {
      _updateState(_state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Failed to fetch file list: $e',
      ));
      rethrow;
    }
  }

  @override
  String _getFileSavePath(String fileName) {
    // Extract page number from filename
    final pageNumber = _extractPageNumber(fileName);

    // If we can't determine the page number, just use the original filename
    if (pageNumber <= 0) {
      return fileName;
    }

    // Return just the filename, the full path will be handled by the base class
    return 'juz_${juzNumber}_page_${pageNumber.toString().padLeft(3, '0')}.jpg';
  }

  static const List<int> juzStartingPages = [
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

  bool _isPageInJuz(int pageNumber) {
    if (juzNumber < 1 || juzNumber > 30) return false;

    // Get page range for this juz
    final startPage = _juzStartingPages[juzNumber - 1];
    final endPage = juzNumber < 30 ? _juzStartingPages[juzNumber] - 1 : 604;

    return pageNumber >= startPage && pageNumber <= endPage;
  }

  int _extractPageNumber(String filename) {
    try {
      // Try to extract page number from common patterns
      final RegExp pageNumRegex =
          RegExp(r'(\d{3})\.(jpg|jpeg|png)', caseSensitive: false);
      final match = pageNumRegex.firstMatch(filename);
      if (match != null && match.groupCount >= 1) {
        return int.parse(match.group(1)!.trim());
      }

      // Try alternative patterns if needed
      final altRegex = RegExp(r'page[_\s]*(\d+)', caseSensitive: false);
      final altMatch = altRegex.firstMatch(filename);
      if (altMatch != null && altMatch.groupCount >= 1) {
        return int.parse(altMatch.group(1)!.trim());
      }

      debugPrint('Could not extract page number from: $filename');
      return -1;
    } catch (e) {
      debugPrint('Error extracting page number from $filename: $e');
      return -1;
    }
  }
}

// --- Full Quran Download Manager ---
class FullQuranDownloadManager extends BaseDownloadManager {
  static final FullQuranDownloadManager _instance =
      FullQuranDownloadManager._internal();
  factory FullQuranDownloadManager() => _instance;

  @override
  @protected
  Future<List<MapEntry<String, String>>> _getFilesToDownload() async {
    final files = await GoogleDriveHelper.listFilesInFolder(folderId);

    // Filter and map files to their IDs and names
    return files
        .where((file) => file.name.endsWith('.jpg'))
        .map((file) => MapEntry(file.id, file.name))
        .toList();
  }

  @override
  @protected
  String _getFileSavePath(String fileName) {
    // For full Quran, files are stored directly in the download directory
    if (_downloadDir == null) {
      throw StateError('Download directory not initialized');
    }
    return '${_downloadDir!.path}/$fileName';
  }

  // Hardcoded Quran constants
  static const int TOTAL_QURAN_PAGES = 604;
  static const int TOTAL_QURAN_SIZE_BYTES = 159383552; // ~152MB in bytes

  // Juz starting pages (Madani Mushaf)
  static const List<int> juzStartingPages = [
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

  // Juz page counts (Madani Mushaf) - pages per Juz
  static const List<int> juzPageCounts = [
    21, // Juz 1: pages 1-21
    20, // Juz 2: pages 22-41
    20, // Juz 3: pages 42-61
    20, // Juz 4: pages 62-81
    20, // Juz 5: pages 82-101
    20, // Juz 6: pages 102-121
    20, // Juz 7: pages 121-141
    20, // Juz 8: pages 142-161
    20, // Juz 9: pages 162-181
    20, // Juz 10: pages 182-201
    20, // Juz 11: pages 201-221
    20, // Juz 12: pages 222-241
    20, // Juz 13: pages 242-261
    20, // Juz 14: pages 262-281
    20, // Juz 15: pages 282-301
    20, // Juz 16: pages 302-321
    20, // Juz 17: pages 322-341
    20, // Juz 18: pages 342-361
    20, // Juz 19: pages 362-381
    20, // Juz 20: pages 382-401
    20, // Juz 21: pages 402-421
    20, // Juz 22: pages 422-441
    20, // Juz 23: pages 442-461
    20, // Juz 24: pages 462-481
    20, // Juz 25: pages 482-501
    20, // Juz 26: pages 502-521
    20, // Juz 27: pages 522-541
    20, // Juz 28: pages 542-561
    20, // Juz 29: pages 562-581
    23, // Juz 30: pages 582-604
  ];

  // Juz page ranges (start page, end page) for each Juz
  static const List<MapEntry<int, int>> juzPageRanges = [
    MapEntry(1, 21), // Juz 1
    MapEntry(22, 41), // Juz 2
    MapEntry(42, 61), // Juz 3
    MapEntry(62, 81), // Juz 4
    MapEntry(82, 101), // Juz 5
    MapEntry(102, 121), // Juz 6
    MapEntry(121, 141), // Juz 7
    MapEntry(142, 161), // Juz 8
    MapEntry(162, 181), // Juz 9
    MapEntry(182, 201), // Juz 10
    MapEntry(201, 221), // Juz 11
    MapEntry(222, 241), // Juz 12
    MapEntry(242, 261), // Juz 13
    MapEntry(262, 281), // Juz 14
    MapEntry(282, 301), // Juz 15
    MapEntry(302, 321), // Juz 16
    MapEntry(322, 341), // Juz 17
    MapEntry(342, 361), // Juz 18
    MapEntry(362, 381), // Juz 19
    MapEntry(382, 401), // Juz 20
    MapEntry(402, 421), // Juz 21
    MapEntry(422, 441), // Juz 22
    MapEntry(442, 461), // Juz 23
    MapEntry(462, 481), // Juz 24
    MapEntry(482, 501), // Juz 25
    MapEntry(502, 521), // Juz 26
    MapEntry(522, 541), // Juz 27
    MapEntry(542, 561), // Juz 28
    MapEntry(562, 581), // Juz 29
    MapEntry(582, 604), // Juz 30
  ];

  FullQuranDownloadManager._internal()
      : super(
          folderId: '1jT-vIj8rA7Aed5BzpyPPQBGQFH436tTk',
          localFolderName:
              'quran_full', // This will be overridden for individual Juz folders
          concurrentDownloads: 4,
          prefsKey: 'full_quran_download_state',
        );

  // Override to get Juz-specific directory
  @override
  Future<Directory> _getDownloadDirectory() async {
    // Always use juz-specific directory to prevent duplicates
    if (this is JuzDownloadManager) {
      final juzNumber = (this as JuzDownloadManager).juzNumber;
      final appDir = await getApplicationDocumentsDirectory();
      _downloadDir = Directory('${appDir.path}/quran_juz_$juzNumber');
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      _downloadDir = Directory('${appDir.path}/quran_full');
    }

    if (!await _downloadDir!.exists()) {
      await _downloadDir!.create(recursive: true);
    }
    return _downloadDir!;
  }

  // Get directory for a specific juz
  Future<Directory> _getJuzDirectory(int juzNumber) async {
    final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/quran_juz_$juzNumber');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Get directory for a specific juz by page number
  Future<Directory> _getJuzDirectoryForPage(int pageNumber) =>
      _getJuzDirectory(_getJuzNumberForPage(pageNumber));

  // Juz starting pages (1-based)
  static const List<int> _juzStartingPages = [
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

  // Extract page number from filename
  int _extractPageNumber(String filename) {
    try {
      // Try matching common page number patterns
      final patterns = [
        RegExp(r'page[_\s]*(\d+)'), // page_001, page 001, page001
        RegExp(r'(\d{3,})\.'), // 001.jpg, 001.png, etc.
        RegExp(r'(\d+)') // any number sequence
      ];

      for (final pattern in patterns) {
        final match = pattern.firstMatch(filename.toLowerCase());
        if (match != null && match.groupCount >= 1) {
          final number = int.tryParse(match.group(1) ?? '');
          if (number != null && number > 0) {
            return number;
          }
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Get juz number for a page (1-based)
  int _getJuzNumberForPage(int pageNumber) {
    // Check if using page ranges (preferred method)
    if (juzPageRanges.isNotEmpty) {
      for (int i = 0; i < juzPageRanges.length; i++) {
        final range = juzPageRanges[i];
        if (pageNumber >= range.key && pageNumber <= range.value) {
          return i + 1; // Juz numbers are 1-based
        }
      }
      return 1; // Default to Juz 1 if not found
    }

    // Fallback to starting pages method if ranges not available
    if (pageNumber <= 0) return 1;

    for (int i = 0; i < _juzStartingPages.length; i++) {
      if (i == _juzStartingPages.length - 1 ||
          pageNumber < _juzStartingPages[i + 1]) {
        return i + 1; // Juz numbers are 1-based
      }
    }
    return _juzStartingPages.length; // Last juz
  }

  // Get the expected page count for a specific Juz
  static int getExpectedPageCountForJuz(int juzNumber) {
    if (juzNumber >= 1 && juzNumber <= juzPageCounts.length) {
      return juzPageCounts[juzNumber - 1];
    }
    return 0;
  }

  // Get the page range for a specific Juz
  static MapEntry<int, int> getPageRangeForJuz(int juzNumber) {
    if (juzNumber >= 1 && juzNumber <= juzPageRanges.length) {
      return juzPageRanges[juzNumber - 1];
    }
    return const MapEntry(0, 0);
  }

  // Check if a page belongs to a specific Juz
  static bool isPageInJuz(int pageNumber, int juzNumber) {
    final range = getPageRangeForJuz(juzNumber);
    return pageNumber >= range.key && pageNumber <= range.value;
  }

  // Get download progress for a specific Juz
  static Future<Map<String, dynamic>> getJuzDownloadProgress(
      int juzNumber) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final juzDir = Directory('${appDir.path}/quran_juz_$juzNumber');

      if (!await juzDir.exists()) {
        return {
          'downloaded': false,
          'downloadedPages': 0,
          'totalPages': getExpectedPageCountForJuz(juzNumber),
          'progress': 0.0,
          'fileSize': 0,
        };
      }

      final files = juzDir.listSync().whereType<File>().toList();
      final downloadedPages = <int>{};
      int totalSize = 0;

      for (final file in files) {
        final pageNumber = _extractPageNumberFromPath(file.path);
        if (pageNumber > 0 && isPageInJuz(pageNumber, juzNumber)) {
          downloadedPages.add(pageNumber);
          totalSize += await file.length();
        }
      }

      final totalPages = getExpectedPageCountForJuz(juzNumber);
      final progress =
          totalPages > 0 ? downloadedPages.length / totalPages : 0.0;
      final isComplete = downloadedPages.length == totalPages;

      return {
        'downloaded': isComplete,
        'downloadedPages': downloadedPages.length,
        'totalPages': totalPages,
        'progress': progress,
        'fileSize': totalSize,
        'downloadedPageNumbers': downloadedPages.toList()..sort(),
      };
    } catch (e) {
      return {
        'downloaded': false,
        'downloadedPages': 0,
        'totalPages': getExpectedPageCountForJuz(juzNumber),
        'progress': 0.0,
        'fileSize': 0,
      };
    }
  }

  // Extract page number from file path
  static int _extractPageNumberFromPath(String filePath) {
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
      return int.tryParse(numbers.first.group(0)!) ?? 0;
    }

    return 0;
  }

  // Get overall download progress for all Juzs
  static Future<Map<String, dynamic>> getAllJuzsDownloadProgress() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      int totalDownloadedPages = 0;
      int totalExpectedPages = 0;
      int totalFileSize = 0;
      int downloadedJuzsCount = 0;
      final juzProgress = <int, Map<String, dynamic>>{};

      for (int juz = 1; juz <= 30; juz++) {
        final progress = await getJuzDownloadProgress(juz);
        juzProgress[juz] = progress;

        totalDownloadedPages += progress['downloadedPages'] as int;
        totalExpectedPages += progress['totalPages'] as int;
        totalFileSize += progress['fileSize'] as int;

        if (progress['downloaded'] as bool) {
          downloadedJuzsCount++;
        }
      }

      final overallProgress = totalExpectedPages > 0
          ? totalDownloadedPages / totalExpectedPages
          : 0.0;

      return {
        'totalDownloadedPages': totalDownloadedPages,
        'totalExpectedPages': totalExpectedPages,
        'overallProgress': overallProgress,
        'downloadedJuzsCount': downloadedJuzsCount,
        'totalFileSize': totalFileSize,
        'juzProgress': juzProgress,
      };
    } catch (e) {
      return {
        'totalDownloadedPages': 0,
        'totalExpectedPages': TOTAL_QURAN_PAGES,
        'overallProgress': 0.0,
        'downloadedJuzsCount': 0,
        'totalFileSize': 0,
        'juzProgress': <int, Map<String, dynamic>>{},
      };
    }
  }

  // Override the download method to distribute files into Juz folders
  @override
  Future<void> _downloadConcurrent({bool resume = false}) async {
    try {
      _updateState(_state.copyWith(status: DownloadStatus.downloading));

      if (_allFiles == null) {
        _allFiles = await GoogleDriveHelper.listFilesInFolder(folderId);
      }

      if (_allFiles == null || _allFiles!.isEmpty) {
        _updateState(_state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'No files found in folder',
        ));
        return;
      }

      final filesToDownload = <DriveFile>[];
      final juzDirectories = <int, Directory>{};

      // Pre-create all Juz directories and determine which files to download
      for (final file in _allFiles!) {
        final pageNumber = _extractPageNumber(file.name);
        if (pageNumber > 0) {
          final juzDir = await _getJuzDirectoryForPage(pageNumber);
          final juzNumber = _getJuzNumberForPage(pageNumber);
          juzDirectories[juzNumber] = juzDir;

          final localFile = File('${juzDir.path}/${file.name}');
          if (!await localFile.exists()) {
            filesToDownload.add(file);
          }
        }
      }

      // Sort files by page number to ensure sequential download
      filesToDownload.sort((a, b) {
        final aPage = _extractPageNumber(a.name);
        final bPage = _extractPageNumber(b.name);
        return aPage.compareTo(bPage);
      });

      if (filesToDownload.isEmpty) {
        _updateState(_state.copyWith(
          status: DownloadStatus.completed,
          downloadedFiles: _allFiles!.length,
          totalFiles: _allFiles!.length,
          progress: 1.0,
        ));
        await cacheQuranDownloadInfo(
          isFullQuran: true,
          downloaded: true,
          fileSize: await _getTotalSize(),
          pageCount: _allFiles!.length,
        );
        return;
      }

      // Preserve original total files count when resuming
      final originalTotalFiles = resume ? _state.totalFiles : _allFiles!.length;
      final totalFiles = resume ? originalTotalFiles : filesToDownload.length;

      // Calculate initial progress when resuming
      int initialDownloadedFiles = 0;
      int initialDownloadedBytes = 0;

      if (resume) {
        for (final file in _allFiles!) {
          final pageNumber = _extractPageNumber(file.name);
          if (pageNumber > 0) {
            final juzDir = await _getJuzDirectoryForPage(pageNumber);
            final localFile = File('${juzDir.path}/${file.name}');
            if (await localFile.exists()) {
              initialDownloadedFiles++;
              initialDownloadedBytes += await localFile.length();
            }
          }
        }
      }

      int downloadedFiles = initialDownloadedFiles;
      int downloadedBytes = initialDownloadedBytes;
      int totalBytes = 0;

      for (final file in filesToDownload) {
        totalBytes += file.size ?? 0;
      }
      totalBytes += initialDownloadedBytes;

      _updateState(_state.copyWith(
        totalFiles: totalFiles,
        totalBytes: totalBytes,
        downloadedFiles: downloadedFiles,
        downloadedBytes: downloadedBytes,
        progress: downloadedFiles / totalFiles,
      ));

      // RESTORED: Concurrent download with semaphore
      final semaphore = Completer<void>();
      int activeDownloads = 0;

      Future<void> downloadFile(DriveFile file) async {
        if (_isCancelled || _isPaused) return;

        try {
          activeDownloads++;
          final pageNumber = _extractPageNumber(file.name);
          final juzDir = await _getJuzDirectoryForPage(pageNumber);
          final localFile = File('${juzDir.path}/${file.name}');

          if (await localFile.exists()) {
            downloadedFiles++;
            downloadedBytes += await localFile.length();
            _updateState(_state.copyWith(
              downloadedFiles: downloadedFiles,
              downloadedBytes: downloadedBytes,
              progress: downloadedFiles / totalFiles,
              currentFile: file.name,
            ));
            return;
          }

          _updateState(_state.copyWith(currentFile: file.name));

          // Use direct download instead of compute so it can be interrupted
          final dio = Dio();
          dio.options.connectTimeout = const Duration(seconds: 30);
          dio.options.receiveTimeout = const Duration(seconds: 60);
          dio.options.sendTimeout = const Duration(seconds: 30);

          try {
            final response = await dio.download(
              'https://drive.google.com/uc?export=download&id=${file.id}',
              localFile.path,
              onReceiveProgress: (received, total) {
                // Check for pause/cancel during download
                if (_isCancelled || _isPaused) {
                  throw Exception('Download interrupted');
                }
              },
            );

            if (response.statusCode == 200) {
              downloadedFiles++;
              downloadedBytes += await localFile.length();
              _updateState(_state.copyWith(
                downloadedFiles: downloadedFiles,
                downloadedBytes: downloadedBytes,
                progress: downloadedFiles / totalFiles,
              ));
            }
          } catch (e) {
            if (_isCancelled || _isPaused) {
              // Download was intentionally interrupted
              return;
            }
            throw e; // Re-throw other errors
          }
        } catch (e) {
          if (!_isCancelled) {
            final errorString = e.toString().toLowerCase();
            final isNetworkError = errorString.contains('socketexception') ||
                errorString.contains('timeoutexception') ||
                errorString.contains('connection') ||
                errorString.contains('network') ||
                errorString.contains('dioerror');

            if (isNetworkError) {
              _updateState(_state.copyWith(
                status: DownloadStatus.networkError,
                errorMessage: 'Network connection lost',
                isNetworkError: true,
              ));
            } else {
              final currentState = _state;
              _updateState(currentState.copyWith(
                status: DownloadStatus.error,
                errorMessage: 'Failed to download ${file.name}: $e',
              ));
            }
          }
        } finally {
          activeDownloads--;
          if (activeDownloads == 0 && semaphore.isCompleted == false) {
            semaphore.complete();
          }
        }
      }

      // Start concurrent downloads
      final futures = <Future<void>>[];
      for (int i = 0;
          i < concurrentDownloads && i < filesToDownload.length;
          i++) {
        futures.add(downloadFile(filesToDownload[i]));
      }

      int nextFileIndex = concurrentDownloads;
      int currentFutureIndex = 0;
      while (currentFutureIndex < futures.length) {
        await futures[currentFutureIndex];
        currentFutureIndex++;
        if (_isCancelled || _isPaused) break;
        if (nextFileIndex < filesToDownload.length) {
          futures.add(downloadFile(filesToDownload[nextFileIndex++]));
        }
      }

      await semaphore.future;

      if (_isCancelled) {
        _updateState(_state.copyWith(status: DownloadStatus.cancelled));
      } else if (_isPaused) {
        _updateState(_state.copyWith(status: DownloadStatus.paused));
      } else if (downloadedFiles == totalFiles) {
        _updateState(_state.copyWith(status: DownloadStatus.completed));
        await cacheQuranDownloadInfo(
          isFullQuran: true,
          downloaded: true,
          fileSize: await _getTotalSize(),
          pageCount: _allFiles!.length,
        );
      }
    } catch (e) {
      if (!_isCancelled) {
        final errorString = e.toString().toLowerCase();
        final isNetworkError = errorString.contains('socketexception') ||
            errorString.contains('timeoutexception') ||
            errorString.contains('connection') ||
            errorString.contains('network') ||
            errorString.contains('dioerror');

        if (isNetworkError) {
          _updateState(_state.copyWith(
            status: DownloadStatus.networkError,
            errorMessage: 'Network connection lost',
            isNetworkError: true,
          ));
        } else {
          final currentState = _state;
          _updateState(currentState.copyWith(
            status: DownloadStatus.error,
            errorMessage: 'Download failed: $e',
          ));
        }
      }
    } finally {
      _isActive = false;
    }
  }

  // Override delete method to clean up all Juz folders
  @override
  Future<void> delete() async {
    _updateState(_state.copyWith(status: DownloadStatus.deleting));
    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Delete all Juz folders that were created by this download
      for (int juz = 1; juz <= 30; juz++) {
        final juzDir = Directory('${appDir.path}/quran_juz_$juz');
        if (await juzDir.exists()) {
          await juzDir.delete(recursive: true);
        }
      }

      _updateState(DownloadState.initial());
      // Cache info as deleted
      await cacheQuranDownloadInfo(
        isFullQuran: true,
        downloaded: false,
        fileSize: 0,
        pageCount: 0,
      );
    } catch (e) {
      _updateState(_state.copyWith(
        status: DownloadStatus.error,
        errorMessage: 'Failed to delete: $e',
      ));
    }
  }

  // Override getTotalSize to calculate size from all Juz folders
  @override
  Future<int> _getTotalSize() async {
    final appDir = await getApplicationDocumentsDirectory();
    int totalSize = 0;

    for (int juz = 1; juz <= 30; juz++) {
      final juzDir = Directory('${appDir.path}/quran_juz_$juz');
      if (await juzDir.exists()) {
        await for (final entity in juzDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }
    }

    return totalSize;
  }
}

// --- Caching Helpers ---
Future<void> cacheQuranDownloadInfo({
  required bool isFullQuran,
  required bool downloaded,
  required int fileSize,
  required int pageCount,
  int? juzNumber,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final prefix = isFullQuran ? 'quran_full' : 'juz_${juzNumber ?? 0}';
  await prefs.setBool('${prefix}_downloaded', downloaded);
  await prefs.setInt('${prefix}_size', fileSize);
  await prefs.setInt('${prefix}_page_count', pageCount);
}

Future<Map<String, dynamic>> getCachedQuranDownloadInfo({
  required bool isFullQuran,
  int? juzNumber,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final prefix = isFullQuran ? 'quran_full' : 'juz_${juzNumber ?? 0}';
  return {
    'downloaded': prefs.getBool('${prefix}_downloaded') ?? false,
    'fileSize': prefs.getInt('${prefix}_size') ?? 0,
    'pageCount': prefs.getInt('${prefix}_page_count') ?? 0,
  };
}
