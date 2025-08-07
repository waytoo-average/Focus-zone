// --- New Download Manager Architecture ---
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../google_drive_helper.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// --- Clean Download Status Enum ---
enum DownloadStatus {
  idle, // Not started
  downloading, // Currently downloading
  paused, // Paused by user
  completed, // Successfully completed
  error, // Failed with error
  cancelled, // Cancelled by user
}

// --- Immutable Download State ---
class DownloadState {
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final String currentFile;
  final int downloadedFiles;
  final int totalFiles;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool isPaused;
  final bool isCancelled;

  const DownloadState({
    required this.status,
    required this.progress,
    required this.currentFile,
    required this.downloadedFiles,
    required this.totalFiles,
    required this.downloadedBytes,
    required this.totalBytes,
    this.errorMessage,
    this.lastUpdated,
    required this.isPaused,
    required this.isCancelled,
  });

  // Immutable copyWith for state transitions
  DownloadState copyWith({
    DownloadStatus? status,
    double? progress,
    String? currentFile,
    int? downloadedFiles,
    int? totalFiles,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? isPaused,
    bool? isCancelled,
  }) {
    return DownloadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentFile: currentFile ?? this.currentFile,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? DateTime.now(),
      isPaused: isPaused ?? this.isPaused,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  // Clear state validation
  bool get isValid {
    return progress >= 0.0 &&
        progress <= 1.0 &&
        downloadedFiles >= 0 &&
        totalFiles >= downloadedFiles &&
        downloadedBytes >= 0 &&
        totalBytes >= downloadedBytes;
  }

  // State query helpers
  bool get isActive => status == DownloadStatus.downloading;
  bool get isCompleted => status == DownloadStatus.completed;
  bool get hasError => status == DownloadStatus.error;
  bool get canPause => isActive && !isPaused;
  bool get canResume => isPaused && !isCancelled;
  bool get canCancel => isActive || isPaused;
  bool get canRetry => hasError;

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'status': status.index,
        'progress': progress,
        'currentFile': currentFile,
        'downloadedFiles': downloadedFiles,
        'totalFiles': totalFiles,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'errorMessage': errorMessage,
        'lastUpdated': lastUpdated?.toIso8601String(),
        'isPaused': isPaused,
        'isCancelled': isCancelled,
      };

  factory DownloadState.fromJson(Map<String, dynamic> json) {
    return DownloadState(
      status: DownloadStatus.values[json['status'] as int],
      progress: json['progress'] as double,
      currentFile: json['currentFile'] as String,
      downloadedFiles: json['downloadedFiles'] as int,
      totalFiles: json['totalFiles'] as int,
      downloadedBytes: json['downloadedBytes'] as int,
      totalBytes: json['totalBytes'] as int,
      errorMessage: json['errorMessage'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      isPaused: json['isPaused'] as bool? ?? false,
      isCancelled: json['isCancelled'] as bool? ?? false,
    );
  }

  static DownloadState initial() => const DownloadState(
        status: DownloadStatus.idle,
        progress: 0.0,
        currentFile: '',
        downloadedFiles: 0,
        totalFiles: 0,
        downloadedBytes: 0,
        totalBytes: 0,
        isPaused: false,
        isCancelled: false,
      );
}

// --- Async Semaphore for Better Concurrency Control ---
class _AsyncSemaphore {
  final int _maxCount;
  int _currentCount = 0;
  final List<Completer<void>> _waiters = [];

  _AsyncSemaphore(this._maxCount);

  Future<void> acquire() async {
    if (_currentCount < _maxCount) {
      _currentCount++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    _currentCount--;
    if (_waiters.isNotEmpty) {
      final waiter = _waiters.removeAt(0);
      waiter.complete();
      _currentCount++;
    }
  }
}

// --- Download Actions for State Machine ---
enum DownloadAction {
  start,
  pause,
  resume,
  cancel,
  retry,
  delete,
}

// --- State Machine for Clean Transitions ---
class DownloadStateMachine {
  static DownloadState transition(
      DownloadState current, DownloadAction action) {
    switch (action) {
      case DownloadAction.start:
        if (current.status == DownloadStatus.idle ||
            current.status == DownloadStatus.error ||
            current.status == DownloadStatus.cancelled) {
          return current.copyWith(
            status: DownloadStatus.downloading,
            isPaused: false,
            isCancelled: false,
            errorMessage: null,
          );
        }
        break;

      case DownloadAction.pause:
        if (current.status == DownloadStatus.downloading) {
          return current.copyWith(
            status: DownloadStatus.paused,
            isPaused: true,
          );
        }
        break;

      case DownloadAction.resume:
        if (current.status == DownloadStatus.paused) {
          return current.copyWith(
            status: DownloadStatus.downloading,
            isPaused: false,
            isCancelled: false,
          );
        }
        break;

      case DownloadAction.cancel:
        if (current.status == DownloadStatus.downloading ||
            current.status == DownloadStatus.paused) {
          return current.copyWith(
            status: DownloadStatus.cancelled,
            isCancelled: true,
            isPaused: false,
          );
        }
        break;

      case DownloadAction.retry:
        if (current.status == DownloadStatus.error ||
            current.status == DownloadStatus.cancelled) {
          return current.copyWith(
            status: DownloadStatus.downloading,
            isPaused: false,
            isCancelled: false,
            errorMessage: null,
          );
        }
        break;

      case DownloadAction.delete:
        return DownloadState.initial();
    }

    // Invalid transition - return current state unchanged
    return current;
  }

  static bool canTransition(DownloadState current, DownloadAction action) {
    final newState = transition(current, action);
    return newState != current;
  }
}

// --- Error Types ---
enum DownloadError {
  networkError,
  storageError,
  permissionError,
  serverError,
  quotaExceeded,
  fileNotFound,
  accessDenied,
  unknownError,
}

// --- Error Handler ---
class DownloadErrorHandler {
  static String getUserFriendlyMessage(DownloadError error) {
    switch (error) {
      case DownloadError.networkError:
        return 'Network connection error. Please check your internet connection and try again.';
      case DownloadError.storageError:
        return 'Storage error. Please check your device storage and permissions.';
      case DownloadError.permissionError:
        return 'Permission denied. Please grant storage permission in settings.';
      case DownloadError.serverError:
        return 'Server error. Please try again later.';
      case DownloadError.quotaExceeded:
        return 'Google Drive quota exceeded. Please try again later.';
      case DownloadError.fileNotFound:
        return 'File not found. The content may have been moved or deleted.';
      case DownloadError.accessDenied:
        return 'Access denied. The file may be private or restricted.';
      case DownloadError.unknownError:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  static bool canRetry(DownloadError error) {
    return error != DownloadError.permissionError &&
        error != DownloadError.fileNotFound &&
        error != DownloadError.accessDenied;
  }

  static DownloadError classifyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Google Drive API specific errors
    if (errorStr.contains('quota') || errorStr.contains('rate limit')) {
      return DownloadError.quotaExceeded;
    }
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return DownloadError.fileNotFound;
    }
    if (errorStr.contains('access denied') || errorStr.contains('403')) {
      return DownloadError.accessDenied;
    }

    // Network errors
    if (errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('socket')) {
      return DownloadError.networkError;
    }

    // Storage errors
    if (errorStr.contains('storage') ||
        errorStr.contains('permission') ||
        errorStr.contains('denied')) {
      return DownloadError.storageError;
    }

    // Server errors
    if (errorStr.contains('server') ||
        errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503')) {
      return DownloadError.serverError;
    }

    return DownloadError.unknownError;
  }
}

// --- Enhanced Quran Download Manager ---
class QuranDownloadManagerV2 extends ChangeNotifier {
  final Dio _dio = Dio();
  final String driveRootFolderId;
  final int maxConcurrentJuzDownloads;
  final int maxConcurrentFileDownloadsPerJuz;

  // Single source of truth for all download states
  final Map<int, DownloadState> _states = {};
  final Map<int, Directory> _downloadDirs = {}; // Cache directories
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Active download tasks for cancellation
  final Map<int, Future<void>?> _activeTasks = {};
  final Map<int, CancelToken> _cancelTokens = {};

  // Internal flags for pause/cancel (like the old working manager)
  final Map<int, bool> _isPaused = {};
  final Map<int, bool> _isCancelled = {};

  static const String _prefsKey = 'quran_download_states_v2';
  static const String kQuranDownloadRoot = 'quran_downloads';
  static const int kJuzCount = 30;

  QuranDownloadManagerV2({
    required this.driveRootFolderId,
    this.maxConcurrentJuzDownloads = 4,
    this.maxConcurrentFileDownloadsPerJuz = 3,
  }) {
    _loadAllStates();
  }

  // --- Enhanced State Management ---
  Future<void> _loadAllStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final Map<String, dynamic> stateMap = jsonDecode(jsonStr);
        _states.clear();
        stateMap.forEach((k, v) {
          _states[int.parse(k)] =
              DownloadState.fromJson(Map<String, dynamic>.from(v));
        });
      }
    } catch (e) {
      // Start fresh if loading fails
      _states.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAllStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateMap =
          _states.map((k, v) => MapEntry(k.toString(), v.toJson()));
      await prefs.setString(_prefsKey, jsonEncode(stateMap));
    } catch (e) {
      // Ignore save errors
    }
  }

  void _updateJuzState(int juz, DownloadState newState) {
    _states[juz] = newState;
    notifyListeners();
    _saveAllStates(); // Auto-save on every state change
  }

  // --- Enhanced Directory Management ---
  Future<Directory> _getJuzDirectory(int juz) async {
    if (_downloadDirs.containsKey(juz)) return _downloadDirs[juz]!;

    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/$kQuranDownloadRoot/juz_$juz');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _downloadDirs[juz] = dir;
    return dir;
  }

  // --- Enhanced Utility Methods from Unified Manager ---
  DownloadStatus get fullQuranStatus {
    final states = _states.values;
    if (states.isEmpty) return DownloadStatus.idle;

    final downloading =
        states.where((s) => s.status == DownloadStatus.downloading).length;
    final paused =
        states.where((s) => s.status == DownloadStatus.paused).length;
    final completed =
        states.where((s) => s.status == DownloadStatus.completed).length;
    final error = states.where((s) => s.status == DownloadStatus.error).length;
    final cancelled =
        states.where((s) => s.status == DownloadStatus.cancelled).length;

    if (downloading > 0) return DownloadStatus.downloading;
    if (paused > 0) return DownloadStatus.paused;
    if (error > 0) return DownloadStatus.error;
    if (cancelled > 0) return DownloadStatus.cancelled;
    if (completed == states.length) return DownloadStatus.completed;
    return DownloadStatus.idle;
  }

  double get fullQuranProgress {
    final states = _states.values;
    if (states.isEmpty) return 0.0;

    // Calculate progress based on completed Juzs and current progress
    int completedJuzs = 0;
    double currentProgress = 0.0;

    for (final state in states) {
      if (state.status == DownloadStatus.completed) {
        completedJuzs++;
        currentProgress += 1.0; // Full progress for completed Juzs
      } else if (state.status == DownloadStatus.downloading ||
          state.status == DownloadStatus.paused) {
        currentProgress += state.progress; // Partial progress for active Juzs
      }
    }

    // Return progress as percentage of total Juzs (30)
    return currentProgress / 30.0;
  }

  int get downloadedJuzsCount {
    return _states.values
        .where((s) => s.status == DownloadStatus.completed)
        .length;
  }

  Map<int, DownloadState> get allJuzStates => Map.unmodifiable(_states);

  // --- Get Juz State Method ---
  DownloadState getJuzState(int juz) => _states[juz] ?? DownloadState.initial();

  // --- Enhanced State Management ---

  // --- Clear API Methods ---
  Future<void> startDownload(int juz, String folderId) async {
    final currentState = _states[juz] ?? DownloadState.initial();
    if (!DownloadStateMachine.canTransition(
        currentState, DownloadAction.start)) {
      return;
    }

    // Reset internal flags (like the old working manager)
    _isPaused[juz] = false;
    _isCancelled[juz] = false;

    final newState =
        DownloadStateMachine.transition(currentState, DownloadAction.start);
    _updateJuzState(juz, newState);

    // Start the actual download
    _activeTasks[juz] = _downloadJuz(juz, folderId);
    await _activeTasks[juz];
    _activeTasks[juz] = null;
  }

  // --- Enhanced Pause/Resume for Image Downloads ---
  void pauseDownload(int juz) {
    final currentState = _states[juz] ?? DownloadState.initial();
    if (!DownloadStateMachine.canTransition(
        currentState, DownloadAction.pause)) {
      return;
    }

    // Set internal flag (like the old working manager)
    _isPaused[juz] = true;
    _isCancelled[juz] = false;

    // Update UI immediately to show "Pausing..." message
    _updateJuzState(
        juz,
        currentState.copyWith(
          status: DownloadStatus.paused,
          currentFile: 'Pausing... Please wait for current file to finish.',
          isPaused: true,
        ));

    // Force UI update
    notifyListeners();
  }

  void resumeDownload(int juz, String folderId) {
    final currentState = _states[juz] ?? DownloadState.initial();
    if (!DownloadStateMachine.canTransition(
        currentState, DownloadAction.resume)) {
      return;
    }

    // Reset internal flags (like the old working manager)
    _isPaused[juz] = false;
    _isCancelled[juz] = false;

    // For image downloads, we resume from where we left off
    final newState =
        DownloadStateMachine.transition(currentState, DownloadAction.resume);
    _updateJuzState(juz, newState);

    // Create a new cancel token for the resumed download
    final cancelToken = CancelToken();
    _cancelTokens[juz] = cancelToken;

    // Start the download task with the same folder ID
    // The download will continue from the last downloaded file
    _activeTasks[juz] = _downloadJuz(juz, folderId);
  }

  void cancelDownload(int juz) {
    final currentState = _states[juz] ?? DownloadState.initial();
    if (!DownloadStateMachine.canTransition(
        currentState, DownloadAction.cancel)) {
      return;
    }

    // Set internal flag (like the old working manager)
    _isCancelled[juz] = true;
    _isPaused[juz] = false;

    // Update UI immediately to show "Cancelling..." message
    _updateJuzState(
        juz,
        currentState.copyWith(
          status: DownloadStatus.cancelled,
          currentFile: 'Cancelling... Please wait for current file to finish.',
          isCancelled: true,
          isPaused: false,
        ));

    // Force UI update
    notifyListeners();
  }

  Future<void> retryDownload(int juz, String folderId) async {
    final currentState = _states[juz] ?? DownloadState.initial();
    if (!DownloadStateMachine.canTransition(
        currentState, DownloadAction.retry)) {
      return;
    }

    final newState =
        DownloadStateMachine.transition(currentState, DownloadAction.retry);
    _updateJuzState(juz, newState);

    // Start the retry download
    _activeTasks[juz] = _downloadJuz(juz, folderId);
    await _activeTasks[juz];
    _activeTasks[juz] = null;
  }

  Future<void> deleteDownload(int juz) async {
    final currentState = _states[juz] ?? DownloadState.initial();
    final newState =
        DownloadStateMachine.transition(currentState, DownloadAction.delete);
    _updateJuzState(juz, newState);

    // Delete files
    try {
      final dir = await _getJuzDirectory(juz);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      print('Error deleting Juz $juz: $e');
    }
  }

  // --- Enhanced Aggregate Operations for Image Downloads ---
  void pauseAll() {
    for (int juz = 1; juz <= kJuzCount; juz++) {
      final state = _states[juz];
      if (state != null && state.status == DownloadStatus.downloading) {
        pauseDownload(juz);
      }
    }
  }

  void resumeAll(Map<int, String> juzFolderIds) {
    for (int juz = 1; juz <= kJuzCount; juz++) {
      final state = _states[juz] ?? DownloadState.initial();
      if (state.status == DownloadStatus.paused) {
        final folderId = juzFolderIds[juz];
        if (folderId != null) {
          resumeDownload(juz, folderId);
        }
      }
    }
  }

  void cancelAll() {
    for (int juz = 1; juz <= kJuzCount; juz++) {
      cancelDownload(juz);
    }
    // Force a state update to ensure UI reflects the cancellation
    notifyListeners();
  }

  // --- Status Queries ---
  bool isDownloading(int juz) => _states[juz]?.isActive ?? false;
  bool isPaused(int juz) =>
      _states[juz]?.status == DownloadStatus.paused ?? false;
  bool isCompleted(int juz) => _states[juz]?.isCompleted ?? false;
  bool hasError(int juz) => _states[juz]?.hasError ?? false;
  bool canPause(int juz) => _states[juz]?.canPause ?? false;
  bool canResume(int juz) => _states[juz]?.canResume ?? false;
  bool canCancel(int juz) => _states[juz]?.canCancel ?? false;
  bool canRetry(int juz) => _states[juz]?.canRetry ?? false;

  // --- Aggregate Status (Enhanced from Unified Manager) ---
  // Note: fullQuranStatus, fullQuranProgress, and downloadedJuzsCount are already defined above

  // --- File System Operations ---
  Future<bool> isJuzDownloaded(int juz) async {
    final dir = await _getJuzDirectory(juz);
    if (!await dir.exists()) return false;

    // Check if all expected files are present and valid
    final state = _states[juz];
    if (state == null || state.totalFiles == 0) return false;

    int validFiles = 0;
    try {
      await for (final file in dir.list()) {
        if (file is File && await file.length() > 0) {
          validFiles++;
        }
      }
    } catch (e) {
      return false;
    }

    return validFiles >= state.totalFiles;
  }

  Future<bool> isFullQuranDownloaded() async {
    for (int juz = 1; juz <= kJuzCount; juz++) {
      if (!await isJuzDownloaded(juz)) return false;
    }
    return true;
  }

  // --- File Validation ---
  Future<bool> validateDownloadedFile(File file, int expectedSize) async {
    try {
      if (!await file.exists()) return false;

      final actualSize = await file.length();
      if (actualSize != expectedSize) return false;

      // For image files, we could add additional validation
      // For now, just check if file is readable
      final stream = file.openRead();
      await stream.first;

      return true;
    } catch (e) {
      return false;
    }
  }

  // --- Enhanced Image-Specific Validation ---
  Future<bool> validateImageFile(File file, int expectedSize) async {
    try {
      if (!await file.exists()) return false;

      final actualSize = await file.length();
      if (actualSize != expectedSize) return false;

      // For image files, we can add additional validation
      // Check if file is readable and has basic image properties
      final stream = file.openRead();
      final firstBytes = await stream.first;
      await stream.drain(); // Clean up the stream

      // Basic check for image file headers (JPEG, PNG, etc.)
      if (firstBytes.length >= 2) {
        // Check for JPEG header
        if (firstBytes[0] == 0xFF && firstBytes[1] == 0xD8) {
          return true;
        }
        // Check for PNG header
        if (firstBytes.length >= 8 &&
            firstBytes[0] == 0x89 &&
            firstBytes[1] == 0x50 &&
            firstBytes[2] == 0x4E &&
            firstBytes[3] == 0x47) {
          return true;
        }
      }

      // If we can't identify the format, just check if file is readable
      return actualSize > 0;
    } catch (e) {
      return false;
    }
  }

  // --- Enhanced State Recovery for Image Downloads ---
  Future<void> recoverDownloadState(int juz) async {
    try {
      final dir = await _getJuzDirectory(juz);
      if (!await dir.exists()) return;

      final state = _states[juz];
      if (state == null) return;

      // Count existing valid image files
      int validFiles = 0;
      int totalSize = 0;
      final existingFiles = <String>[];

      await for (final file in dir.list()) {
        if (file is File) {
          final fileSize = await file.length();
          if (fileSize > 0) {
            validFiles++;
            totalSize += fileSize;
            existingFiles.add(file.path.split('/').last);
          }
        }
      }

      // Update state if we found existing files
      if (validFiles > 0) {
        final progress =
            state.totalFiles > 0 ? validFiles / state.totalFiles : 0.0;
        _updateJuzState(
            juz,
            state.copyWith(
              downloadedFiles: validFiles,
              downloadedBytes: totalSize,
              progress: progress.clamp(0.0, 1.0),
              currentFile: existingFiles.isNotEmpty ? existingFiles.last : '',
            ));
      }
    } catch (e) {
      // Ignore recovery errors
    }
  }

  // --- Enhanced Cleanup for Image Downloads ---
  Future<void> cleanupImageDownloads(int juz) async {
    try {
      final dir = await _getJuzDirectory(juz);
      if (!await dir.exists()) return;

      final state = _states[juz];
      if (state == null) return;

      // Remove files that don't match expected count or are corrupted
      int fileCount = 0;
      await for (final file in dir.list()) {
        if (file is File) {
          fileCount++;
          final fileSize = await file.length();

          // Remove files that are empty or corrupted
          if (fileSize == 0) {
            await file.delete();
            fileCount--;
          }
          // Remove extra files beyond expected count
          else if (fileCount > state.totalFiles) {
            await file.delete();
            fileCount--;
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  // --- Cleanup Methods ---
  Future<void> cleanupPartialDownloads(int juz) async {
    try {
      final dir = await _getJuzDirectory(juz);
      if (!await dir.exists()) return;

      final state = _states[juz];
      if (state == null) return;

      // Remove files that don't match expected count
      int fileCount = 0;
      await for (final file in dir.list()) {
        if (file is File) {
          fileCount++;
          // If we have more files than expected, remove extras
          if (fileCount > state.totalFiles) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  // --- Storage Management ---
  Future<int> getDownloadedSize() async {
    int totalSize = 0;
    for (int juz = 1; juz <= kJuzCount; juz++) {
      final state = _states[juz];
      if (state != null && state.status == DownloadStatus.completed) {
        totalSize += state.downloadedBytes;
      }
    }
    return totalSize;
  }

  Future<void> clearAllDownloads() async {
    for (int juz = 1; juz <= kJuzCount; juz++) {
      await deleteDownload(juz);
    }
  }

  // --- Full Quran Download ---
  Future<void> downloadFullQuran(Map<int, String> juzFolderIds) async {
    final futures = <Future>[];
    final sem = _AsyncSemaphore(maxConcurrentJuzDownloads);

    for (int juz = 1; juz <= kJuzCount; juz++) {
      final folderId = juzFolderIds[juz];
      if (folderId == null) continue;

      await sem.acquire();
      final f = startDownload(juz, folderId).whenComplete(() => sem.release());
      futures.add(f);
    }

    // Wait for all downloads to complete, but check for cancellation
    try {
      await Future.wait(futures);
    } catch (e) {
      // Handle any cancellation errors gracefully
      if (e is DioException && CancelToken.isCancel(e)) {
        // Downloads were cancelled, this is expected
        return;
      }
      rethrow;
    }
  }

  // --- Download Operations ---
  // --- Image-Specific Download Optimizations ---
  Future<void> _downloadJuz(int juz, String folderId) async {
    // Create a fresh cancel token for this download session
    final cancelToken = CancelToken();
    _cancelTokens[juz] = cancelToken;

    try {
      // Update state to downloading
      _updateJuzState(
          juz,
          _states[juz]?.copyWith(
                status: DownloadStatus.downloading,
                progress: 0.0,
                currentFile: 'Initializing...',
                downloadedFiles: 0,
                totalFiles: 0,
                downloadedBytes: 0,
                totalBytes: 0,
                isPaused: false,
                isCancelled: false,
              ) ??
              DownloadState.initial());

      // Get files from Google Drive
      final files = await GoogleDriveHelper.listFilesInFolder(folderId);
      if (files.isEmpty) {
        _handleError(juz, DownloadError.fileNotFound);
        return;
      }

      // Calculate total size more efficiently for images
      int totalBytes = 0;
      final validFiles = <DriveFile>[];
      for (final file in files) {
        if (file.size != null && file.size! > 0) {
          totalBytes += file.size!;
          validFiles.add(file);
        }
      }

      if (validFiles.isEmpty) {
        _handleError(juz, DownloadError.fileNotFound);
        return;
      }

      // Update state with total file count for images
      _updateJuzState(
          juz,
          _states[juz]?.copyWith(
                totalFiles: validFiles.length,
                totalBytes: totalBytes,
                currentFile: 'Preparing image downloads...',
              ) ??
              DownloadState.initial());

      // Download files with enhanced progress tracking for images
      int downloadedFiles = 0;
      int downloadedBytes = 0;
      final completedFiles = <String>{};

      // If resuming, load the previous progress
      final currentState = _states[juz] ?? DownloadState.initial();
      if (currentState.status == DownloadStatus.paused) {
        downloadedFiles = currentState.downloadedFiles;
        downloadedBytes = currentState.downloadedBytes;
      }

      for (int fileIndex = 0; fileIndex < validFiles.length; fileIndex++) {
        final file = validFiles[fileIndex];

        // Check for cancellation - get fresh state
        var currentState = _states[juz] ?? DownloadState.initial();
        if (cancelToken.isCancelled) {
          return;
        }

        // Check for cancellation - get fresh state
        currentState = _states[juz] ?? DownloadState.initial();
        if (cancelToken.isCancelled) {
          return;
        }

        // If we're cancelled after the current file finished, clean up and exit
        if (currentState.isCancelled) {
          // Clean up any partial files and exit
          final localFile =
              File('${(await _getJuzDirectory(juz)).path}/${file.name}');
          if (await localFile.exists()) {
            await localFile.delete();
          }
          _updateJuzState(
              juz,
              currentState.copyWith(
                downloadedFiles: downloadedFiles,
                downloadedBytes: downloadedBytes,
                currentFile: 'Download cancelled.',
              ));
          return;
        }

        final localFile =
            File('${(await _getJuzDirectory(juz)).path}/${file.name}');

        // Check if file already exists and is valid for images
        if (await localFile.exists()) {
          final fileSize = await localFile.length();
          if (fileSize > 0 && fileSize == (file.size ?? 0)) {
            // File already downloaded, skip it
            downloadedFiles++;
            downloadedBytes += fileSize;
            completedFiles.add(file.name);
            _updateProgress(juz, downloadedFiles, validFiles.length,
                downloadedBytes, totalBytes, file.name);
            continue;
          } else {
            // File exists but size doesn't match, delete and re-download
            await localFile.delete();
          }
        }

        // If we're resuming and this file was already processed, skip it
        if (completedFiles.contains(file.name)) {
          continue;
        }

        // Update current file name for progress tracking
        _updateJuzState(
            juz,
            currentState.copyWith(
              currentFile: 'Downloading ${file.name}...',
            ));

        try {
          // Check state again before starting download
          currentState = _states[juz] ?? DownloadState.initial();
          if (cancelToken.isCancelled) {
            return;
          }

          final response = await _dio.download(
            'https://drive.google.com/uc?export=download&id=${file.id}',
            localFile.path,
            cancelToken: cancelToken,
            onReceiveProgress: (received, total) {
              // Check for cancellation during progress updates
              if (cancelToken.isCancelled) {
                return;
              }

              // Check for pause/cancel during progress updates (like the old working manager)
              if (_isCancelled[juz] == true || _isPaused[juz] == true) {
                return; // Stop progress updates if paused/cancelled
              }

              if (total > 0) {
                final currentProgress = downloadedBytes + received;
                final overallProgress =
                    totalBytes > 0 ? currentProgress / totalBytes : 0.0;
                _updateProgress(juz, downloadedFiles, validFiles.length,
                    currentProgress, totalBytes, file.name);
              }
            },
          );

          if (response.statusCode == 200) {
            // Validate downloaded image file
            final downloadedSize = await localFile.length();
            if (downloadedSize > 0 && downloadedSize == (file.size ?? 0)) {
              downloadedFiles++;
              downloadedBytes += downloadedSize;
              completedFiles.add(file.name);

              // Check for pause/cancel after current file completes (like the old working manager)
              if (_isCancelled[juz] == true) {
                // Clean up any partial files and exit
                final localFile =
                    File('${(await _getJuzDirectory(juz)).path}/${file.name}');
                if (await localFile.exists()) {
                  await localFile.delete();
                }
                _updateJuzState(
                    juz,
                    currentState.copyWith(
                      downloadedFiles: downloadedFiles,
                      downloadedBytes: downloadedBytes,
                      currentFile: 'Download cancelled.',
                    ));
                notifyListeners(); // Force UI update
                return;
              }

              if (_isPaused[juz] == true) {
                // Save the current progress before exiting
                _updateJuzState(
                    juz,
                    currentState.copyWith(
                      downloadedFiles: downloadedFiles,
                      downloadedBytes: downloadedBytes,
                      currentFile: 'Paused at ${file.name}',
                    ));
                notifyListeners(); // Force UI update
                return;
              }
            } else {
              // File size mismatch, delete and continue
              await localFile.delete();
              _handleError(juz, DownloadError.unknownError);
              return;
            }
          } else {
            _handleError(juz, DownloadError.serverError);
            return;
          }
        } catch (e) {
          if (e is DioException && CancelToken.isCancel(e)) {
            // Clean up partial file on cancellation
            if (await localFile.exists()) {
              await localFile.delete();
            }
            return; // Cancelled
          }
          // Clean up partial file
          if (await localFile.exists()) {
            await localFile.delete();
          }
          _handleError(juz, DownloadErrorHandler.classifyError(e));
          return;
        }
      }

      // Mark as completed only if all image files downloaded successfully
      if (downloadedFiles == validFiles.length) {
        _updateJuzState(
            juz,
            _states[juz]?.copyWith(
                  status: DownloadStatus.completed,
                  progress: 1.0,
                  downloadedFiles: downloadedFiles,
                  totalFiles: validFiles.length,
                  downloadedBytes: downloadedBytes,
                  totalBytes: totalBytes,
                  currentFile: '',
                  isPaused: false,
                  isCancelled: false,
                ) ??
                DownloadState.initial());
      } else {
        _handleError(juz, DownloadError.unknownError);
      }
    } catch (e) {
      _handleError(juz, DownloadErrorHandler.classifyError(e));
    } finally {
      // Clean up the cancel token
      _cancelTokens.remove(juz);
    }
  }

  // --- Enhanced Progress Tracking for Images ---
  void _updateProgress(int juz, int downloadedFiles, int totalFiles,
      int downloadedBytes, int totalBytes, String currentFile) {
    final currentState = _states[juz] ?? DownloadState.initial();

    // Calculate progress more accurately for images
    double progress = 0.0;
    if (totalFiles > 0) {
      // For images, we consider both file count and byte progress
      final fileProgress = downloadedFiles / totalFiles;
      final byteProgress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
      // Weight file progress more heavily for images since each file is an image
      progress = (fileProgress * 0.7) + (byteProgress * 0.3);
    }

    final newState = currentState.copyWith(
      status: DownloadStatus.downloading,
      progress: progress.clamp(0.0, 1.0),
      currentFile: currentFile,
      downloadedFiles: downloadedFiles,
      totalFiles: totalFiles,
      downloadedBytes: downloadedBytes,
      totalBytes: totalBytes,
      isPaused: false,
      isCancelled: false,
    );

    _updateJuzState(juz, newState);
  }

  // --- Enhanced Error Handling for Image Downloads ---
  void _handleError(int juz, DownloadError error) {
    final currentState = _states[juz] ?? DownloadState.initial();
    final errorMessage = DownloadErrorHandler.getUserFriendlyMessage(error);

    // For image downloads, provide more specific error messages
    String specificMessage = errorMessage;
    if (error == DownloadError.networkError) {
      specificMessage =
          'Network error while downloading Quran images. Please check your connection.';
    } else if (error == DownloadError.storageError) {
      specificMessage =
          'Storage error while saving Quran images. Please check available space.';
    } else if (error == DownloadError.fileNotFound) {
      specificMessage =
          'Quran images not found. The content may have been moved.';
    } else if (error == DownloadError.quotaExceeded) {
      specificMessage = 'Google Drive quota exceeded. Please try again later.';
    }

    final newState = currentState.copyWith(
      status: DownloadStatus.error,
      errorMessage: specificMessage,
      isPaused: false,
      isCancelled: false,
    );

    _updateJuzState(juz, newState);
  }

  @override
  void dispose() {
    // Cancel all active downloads
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    super.dispose();
  }
}
