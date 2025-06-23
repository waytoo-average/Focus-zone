import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../../google_drive_helper.dart';

enum FullQuranDownloadStatus {
  idle,
  downloading,
  pausing,
  paused,
  cancelling,
  cancelled,
  deleting,
  completed,
  error,
}

@JsonSerializable()
class FullQuranDownloadState {
  final FullQuranDownloadStatus status;
  final int downloadedFiles;
  final int totalFiles;
  final double progress;
  final String currentFile;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  const FullQuranDownloadState({
    required this.status,
    required this.downloadedFiles,
    required this.totalFiles,
    required this.progress,
    required this.currentFile,
    required this.downloadedBytes,
    required this.totalBytes,
    this.errorMessage,
  });

  FullQuranDownloadState copyWith({
    FullQuranDownloadStatus? status,
    int? downloadedFiles,
    int? totalFiles,
    double? progress,
    String? currentFile,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return FullQuranDownloadState(
      status: status ?? this.status,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      progress: progress ?? this.progress,
      currentFile: currentFile ?? this.currentFile,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static FullQuranDownloadState initial() => const FullQuranDownloadState(
        status: FullQuranDownloadStatus.idle,
        downloadedFiles: 0,
        totalFiles: 0,
        progress: 0.0,
        currentFile: '',
        downloadedBytes: 0,
        totalBytes: 0,
        errorMessage: null,
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
      };

  static FullQuranDownloadState fromJson(Map<String, dynamic> json) {
    return FullQuranDownloadState(
      status: FullQuranDownloadStatus.values[json['status'] ?? 0],
      downloadedFiles: json['downloadedFiles'] ?? 0,
      totalFiles: json['totalFiles'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
      currentFile: json['currentFile'] ?? '',
      downloadedBytes: json['downloadedBytes'] ?? 0,
      totalBytes: json['totalBytes'] ?? 0,
      errorMessage: json['errorMessage'],
    );
  }
}

class FullQuranDownloadManager extends ChangeNotifier {
  static final FullQuranDownloadManager _instance =
      FullQuranDownloadManager._internal();
  factory FullQuranDownloadManager() => _instance;
  FullQuranDownloadManager._internal() {
    _loadState();
  }

  static const String folderId = '1jT-vIj8rA7Aed5BzpyPPQBGQFH436tTk';
  static const String localFolderName = 'quran_full';
  static const int concurrentDownloads = 4;
  static const String _prefsKey = 'full_quran_download_state';

  FullQuranDownloadState _state = FullQuranDownloadState.initial();
  FullQuranDownloadState get state => _state;

  bool _isCancelled = false;
  bool _isPaused = false;
  bool _isActive = false;
  List<DriveFile>? _allFiles;
  Directory? _downloadDir;

  final Dio _dio = Dio();

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final json =
            Map<String, dynamic>.from(await compute(_decodeJson, jsonStr));
        final loadedState = FullQuranDownloadState.fromJson(json);
        // Check files on disk to update progress
        final info = await getDownloadInfo();
        final correctedState = loadedState.copyWith(
          downloadedFiles: info['fileCount'] ?? 0,
          downloadedBytes: info['totalSize'] ?? 0,
          status: loadedState.status == FullQuranDownloadStatus.downloading
              ? FullQuranDownloadStatus.paused
              : loadedState.status,
        );
        _state = correctedState;
        notifyListeners();
      } catch (_) {
        _state = FullQuranDownloadState.initial();
        notifyListeners();
      }
    }
  }

  static Map<String, dynamic> _decodeJson(String jsonStr) =>
      Map<String, dynamic>.from(jsonDecode(jsonStr));

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_state.toJson()));
  }

  void start() {
    if (_isActive || _state.status == FullQuranDownloadStatus.downloading)
      return;
    _isCancelled = false;
    _isPaused = false;
    _isActive = true;
    _downloadQuranConcurrent();
  }

  void pause() {
    if (_state.status == FullQuranDownloadStatus.downloading) {
      _isPaused = true;
      _updateState(_state.copyWith(status: FullQuranDownloadStatus.pausing));
      // No forced cancellation, just wait for in-progress downloads to finish
      // UI should show spinner until state becomes paused
    }
  }

  void resume() {
    if (_state.status == FullQuranDownloadStatus.paused) {
      print('[FullQuranDownloadManager] Resuming download...');
      _isPaused = false;
      _isCancelled = false;
      if (!_isActive) {
        _isActive = true;
        _updateState(
            _state.copyWith(status: FullQuranDownloadStatus.downloading));
        _downloadQuranConcurrent(resume: true);
      } else {
        print(
            '[FullQuranDownloadManager] Download already active, not starting another.');
      }
    }
  }

  void cancel() {
    _isCancelled = true;
    _isPaused = false;
    _isActive = false;
    _updateState(_state.copyWith(status: FullQuranDownloadStatus.cancelling));
    // No forced cancellation, just wait for in-progress downloads to finish
    // UI should show spinner until state becomes cancelled
  }

  Future<void> delete() async {
    if (_state.status == FullQuranDownloadStatus.downloading ||
        _state.status == FullQuranDownloadStatus.paused ||
        _state.status == FullQuranDownloadStatus.pausing ||
        _state.status == FullQuranDownloadStatus.cancelling) {
      print(
          '[FullQuranDownloadManager] Refusing to delete: download in progress or pending.');
      return;
    }
    _updateState(_state.copyWith(status: FullQuranDownloadStatus.deleting));
    try {
      final dir = await getApplicationDocumentsDirectory();
      final quranDir = Directory('${dir.path}/$localFolderName');
      if (quranDir.existsSync()) {
        await quranDir.delete(recursive: true);
      }
      _updateState(FullQuranDownloadState.initial());
      print('[FullQuranDownloadManager] Deleted all files.');
    } catch (e, st) {
      print('[FullQuranDownloadManager] Error deleting files: $e\n$st');
      _updateState(_state.copyWith(
          status: FullQuranDownloadStatus.error, errorMessage: e.toString()));
    }
  }

  Future<Map<String, dynamic>> getDownloadInfo() async {
    final dir = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${dir.path}/$localFolderName');
    if (!quranDir.existsSync()) {
      return {
        'exists': false,
        'fileCount': 0,
        'totalSize': 0,
      };
    }
    final files = quranDir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.jpeg') ||
            f.path.endsWith('.png'))
        .toList();
    int totalSize = 0;
    for (final file in files) {
      totalSize += await file.length();
    }
    return {
      'exists': true,
      'fileCount': files.length,
      'totalSize': totalSize,
    };
  }

  void _updateState(FullQuranDownloadState newState) {
    _state = newState;
    notifyListeners();
    _saveState();
  }

  Future<void> _downloadQuranConcurrent({bool resume = false}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _downloadDir = Directory('${dir.path}/$localFolderName');
      if (!_downloadDir!.existsSync()) {
        await _downloadDir!.create(recursive: true);
      }
      if (_allFiles == null) {
        _allFiles = await GoogleDriveHelper.listFilesInFolder(folderId);
      }
      final allFiles = _allFiles!;
      final alreadyDownloaded = _downloadDir!
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .toSet();
      int totalBytes = 0;
      for (final file in allFiles) {
        if (file.size != null) totalBytes += file.size!;
      }
      int downloadedCount = alreadyDownloaded.length;
      int downloadedBytes = 0;
      for (final file in allFiles) {
        if (alreadyDownloaded.contains(file.name) && file.size != null) {
          downloadedBytes += file.size!;
        }
      }
      _updateState(_state.copyWith(
        status: FullQuranDownloadStatus.downloading,
        totalFiles: allFiles.length,
        downloadedFiles: downloadedCount,
        progress: allFiles.isEmpty ? 0.0 : downloadedCount / allFiles.length,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        currentFile: '',
        errorMessage: null,
      ));

      final toDownload = <int>[];
      for (int i = 0; i < allFiles.length; i++) {
        if (!alreadyDownloaded.contains(allFiles[i].name)) {
          toDownload.add(i);
        }
      }
      int inProgress = 0;
      int completed = downloadedCount;
      int completedBytes = downloadedBytes;
      final Set<int> finishedIndexes = {};
      final List<Future<void>> active = [];
      final Completer<void> allDone = Completer<void>();
      int nextIndex = 0;
      bool shouldStop() => _isPaused || _isCancelled;
      void startNext() {
        if (_isCancelled) return;
        while (inProgress < concurrentDownloads &&
            nextIndex < toDownload.length &&
            !shouldStop()) {
          final idx = toDownload[nextIndex++];
          inProgress++;
          final file = allFiles[idx];
          _updateState(_state.copyWith(currentFile: file.name));
          active.add(_downloadFile(file).then((bytes) {
            finishedIndexes.add(idx);
            inProgress--;

            // Only increment if the download was successful
            if (bytes > 0) {
              completed++;
              if (file.size != null) completedBytes += file.size!;
            }

            _updateState(_state.copyWith(
              downloadedFiles: completed,
              progress: allFiles.isEmpty ? 0.0 : completed / allFiles.length,
              downloadedBytes: completedBytes,
              currentFile: file.name,
            ));

            if (!allDone.isCompleted) {
              if (finishedIndexes.length == toDownload.length || shouldStop()) {
                allDone.complete();
              } else {
                startNext();
              }
            }
          }));
        }
      }

      startNext();
      // Wait for all downloads to finish or for pause/cancel
      while (finishedIndexes.length < toDownload.length &&
          !_isCancelled &&
          !_isPaused) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      await allDone.future.catchError((_) {});
      _isActive = false;
      // After all downloads, re-check files on disk
      final filesOnDisk = _downloadDir!
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.jpg') ||
              f.path.endsWith('.jpeg') ||
              f.path.endsWith('.png'))
          .toList();
      final allDownloaded = filesOnDisk.length == allFiles.length;
      if (_isCancelled) {
        _updateState(
            _state.copyWith(status: FullQuranDownloadStatus.cancelled));
      } else if (_isPaused) {
        _updateState(_state.copyWith(status: FullQuranDownloadStatus.paused));
      } else if (allDownloaded) {
        _updateState(_state.copyWith(
          status: FullQuranDownloadStatus.completed,
          progress: 1.0,
          currentFile: '',
        ));
      } else {
        // Not all files downloaded, stay in idle or error
        _updateState(_state.copyWith(
          status: FullQuranDownloadStatus.idle,
          progress:
              filesOnDisk.isEmpty ? 0.0 : filesOnDisk.length / allFiles.length,
          currentFile: '',
        ));
      }
    } catch (e) {
      _isActive = false;
      _updateState(_state.copyWith(
        status: FullQuranDownloadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<int> _downloadFile(DriveFile file) async {
    if (_isPaused || _isCancelled) return 0;
    final url = GoogleDriveHelper.getDownloadUrl(file.id);
    final savePath = '${_downloadDir!.path}/${file.name}';
    try {
      await _dio.download(
        url,
        savePath,
        // No cancelToken, just let the file finish
      );

      // After download, check again if a pause was requested.
      if (_isPaused || _isCancelled) return 0;

      final imageFile = File(savePath);
      return file.size ?? await imageFile.length();
    } catch (e, st) {
      // Don't crash the app. Log the error and return 0 bytes.
      // The main process will continue, and the download will be marked as incomplete at the end.
      print(
          '[FullQuranDownloadManager] Resiliently handling error for ${file.name}: $e\n$st');
      return 0;
    }
  }
}
