// --- Download State & Managers ---
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../google_drive_helper.dart';

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

  const DownloadState({
    required this.status,
    required this.downloadedFiles,
    required this.totalFiles,
    required this.progress,
    required this.currentFile,
    required this.downloadedBytes,
    required this.totalBytes,
    this.errorMessage,
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
    );
  }
}

// --- Base Download Manager ---
abstract class BaseDownloadManager extends ChangeNotifier {
  final String folderId;
  final String localFolderName;
  final int concurrentDownloads;
  final String prefsKey;

  DownloadState _state = DownloadState.initial();
  DownloadState get state => _state;

  bool _isCancelled = false;
  bool _isPaused = false;
  bool _isActive = false;
  bool _isDisposed = false;
  List<DriveFile>? _allFiles;
  Directory? _downloadDir;
  final Dio _dio = Dio();

  BaseDownloadManager({
    required this.folderId,
    required this.localFolderName,
    required this.concurrentDownloads,
    required this.prefsKey,
  }) {
    _loadState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isDisposed) return;
    final jsonStr = prefs.getString(prefsKey);
    if (jsonStr != null) {
      try {
        final json =
            Map<String, dynamic>.from(await compute(_decodeJson, jsonStr));
        final loadedState = DownloadState.fromJson(json);
        final info = await getDownloadInfo();
        if (_isDisposed) return;
        final correctedState = loadedState.copyWith(
          downloadedFiles: info['fileCount'] ?? 0,
          downloadedBytes: info['totalSize'] ?? 0,
          status: loadedState.status == DownloadStatus.downloading
              ? DownloadStatus.paused
              : loadedState.status,
        );
        _state = correctedState;
        notifyListeners();
      } catch (_) {
        _state = DownloadState.initial();
        notifyListeners();
      }
    }
  }

  static Map<String, dynamic> _decodeJson(String jsonStr) =>
      Map<String, dynamic>.from(jsonDecode(jsonStr));

  Future<void> _saveState() async {
    if (_isDisposed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(_state.toJson()));
  }

  void _updateState(DownloadState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
    _saveState();
  }

  void start() {
    if (_isActive || _state.status == DownloadStatus.downloading) return;
    _isCancelled = false;
    _isPaused = false;
    _isActive = true;
    _downloadConcurrent();
  }

  void pause() {
    if (_state.status == DownloadStatus.downloading) {
      _isPaused = true;
      _updateState(_state.copyWith(status: DownloadStatus.pausing));
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
    }
  }

  void cancel() {
    _isCancelled = true;
    _isPaused = false;
    _isActive = false;
    _updateState(_state.copyWith(status: DownloadStatus.cancelling));
  }

  Future<void> delete() async {
    _updateState(_state.copyWith(status: DownloadStatus.deleting));
    try {
      final dir = await _getDownloadDirectory();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
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
    final appDir = await getApplicationDocumentsDirectory();
    _downloadDir = Directory('${appDir.path}/$localFolderName');
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
        final localFile = File('${dir.path}/${file.name}');
        if (!await localFile.exists()) {
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
        return;
      }

      final totalFiles = filesToDownload.length;
      int downloadedFiles = 0;
      int downloadedBytes = 0;
      int totalBytes = 0;

      for (final file in filesToDownload) {
        totalBytes += file.size ?? 0;
      }

      _updateState(_state.copyWith(
        totalFiles: totalFiles,
        totalBytes: totalBytes,
      ));

      final semaphore = Completer<void>();
      int activeDownloads = 0;

      Future<void> downloadFile(DriveFile file) async {
        if (_isCancelled || _isPaused) return;

        try {
          activeDownloads++;
          final localFile = File('${dir.path}/${file.name}');

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

          final response = await _dio.download(
            'https://drive.google.com/uc?export=download&id=${file.id}',
            localFile.path,
            onReceiveProgress: (received, total) {
              if (_isCancelled || _isPaused) return;
              final progress =
                  (downloadedFiles + (received / total)) / totalFiles;
              _updateState(_state.copyWith(progress: progress));
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
          if (!_isCancelled) {
            _updateState(_state.copyWith(
              status: DownloadStatus.error,
              errorMessage: 'Failed to download ${file.name}: $e',
            ));
          }
        } finally {
          activeDownloads--;
          if (activeDownloads == 0 && semaphore.isCompleted == false) {
            semaphore.complete();
          }
        }
      }

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
      }
    } catch (e) {
      if (!_isCancelled) {
        _updateState(_state.copyWith(
          status: DownloadStatus.error,
          errorMessage: 'Download failed: $e',
        ));
      }
    } finally {
      _isActive = false;
    }
  }
}

// --- Juz Download Manager ---
class JuzDownloadManager extends BaseDownloadManager {
  final int juzNumber;

  JuzDownloadManager({required this.juzNumber, required String folderId})
      : super(
          folderId: folderId,
          localFolderName: 'quran_juz_$juzNumber',
          concurrentDownloads: 3,
          prefsKey: 'juz_download_state_$juzNumber',
        );
}

// --- Full Quran Download Manager ---
class FullQuranDownloadManager extends BaseDownloadManager {
  static final FullQuranDownloadManager _instance =
      FullQuranDownloadManager._internal();
  factory FullQuranDownloadManager() => _instance;

  FullQuranDownloadManager._internal()
      : super(
          folderId: '1jT-vIj8rA7Aed5BzpyPPQBGQFH436tTk',
          localFolderName: 'quran_full',
          concurrentDownloads: 4,
          prefsKey: 'full_quran_download_state',
        );
}
