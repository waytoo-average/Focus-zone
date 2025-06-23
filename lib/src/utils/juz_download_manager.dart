import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../google_drive_helper.dart';

enum JuzDownloadStatus {
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

class JuzDownloadState {
  final JuzDownloadStatus status;
  final int downloadedFiles;
  final int totalFiles;
  final double progress;
  final String currentFile;
  final int downloadedBytes;
  final int totalBytes;
  final String? errorMessage;

  const JuzDownloadState({
    required this.status,
    required this.downloadedFiles,
    required this.totalFiles,
    required this.progress,
    required this.currentFile,
    required this.downloadedBytes,
    required this.totalBytes,
    this.errorMessage,
  });

  JuzDownloadState copyWith({
    JuzDownloadStatus? status,
    int? downloadedFiles,
    int? totalFiles,
    double? progress,
    String? currentFile,
    int? downloadedBytes,
    int? totalBytes,
    String? errorMessage,
  }) {
    return JuzDownloadState(
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

  static JuzDownloadState initial() => const JuzDownloadState(
        status: JuzDownloadStatus.idle,
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

  static JuzDownloadState fromJson(Map<String, dynamic> json) {
    return JuzDownloadState(
      status: JuzDownloadStatus.values[json['status'] ?? 0],
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

class JuzDownloadManager extends ChangeNotifier {
  final int juzNumber;
  final String folderId;
  static const int concurrentDownloads = 3;
  late final String _prefsKey;

  JuzDownloadState _state = JuzDownloadState.initial();
  JuzDownloadState get state => _state;

  bool _isCancelled = false;
  bool _isPaused = false;
  bool _isActive = false;
  bool _isDisposed = false;
  List<DriveFile>? _allFiles;
  Directory? _downloadDir;
  final Dio _dio = Dio();

  JuzDownloadManager({required this.juzNumber, required this.folderId}) {
    _prefsKey = 'juz_download_state_$juzNumber';
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
    final jsonStr = prefs.getString(_prefsKey);
    if (jsonStr != null) {
      try {
        final json =
            Map<String, dynamic>.from(await compute(_decodeJson, jsonStr));
        final loadedState = JuzDownloadState.fromJson(json);
        // Check files on disk to update progress
        final info = await getDownloadInfo();
        if (_isDisposed) return;
        final correctedState = loadedState.copyWith(
          downloadedFiles: info['fileCount'] ?? 0,
          downloadedBytes: info['totalSize'] ?? 0,
          status: loadedState.status == JuzDownloadStatus.downloading
              ? JuzDownloadStatus.paused
              : loadedState.status,
        );
        _state = correctedState;
        notifyListeners();
      } catch (_) {
        _state = JuzDownloadState.initial();
        notifyListeners();
      }
    }
  }

  static Map<String, dynamic> _decodeJson(String jsonStr) =>
      Map<String, dynamic>.from(jsonDecode(jsonStr));

  Future<void> _saveState() async {
    if (_isDisposed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_state.toJson()));
  }

  void start() {
    if (_isActive || _state.status == JuzDownloadStatus.downloading) return;
    _isCancelled = false;
    _isPaused = false;
    _isActive = true;
    _downloadJuzConcurrent();
  }

  void pause() {
    if (_state.status == JuzDownloadStatus.downloading) {
      _isPaused = true;
      _updateState(_state.copyWith(status: JuzDownloadStatus.pausing));
    }
  }

  void resume() {
    if (_state.status == JuzDownloadStatus.paused) {
      _isPaused = false;
      _isCancelled = false;
      if (!_isActive) {
        _isActive = true;
        _updateState(_state.copyWith(status: JuzDownloadStatus.downloading));
        _downloadJuzConcurrent(resume: true);
      }
    }
  }

  void cancel() {
    _isCancelled = true;
    _isPaused = false;
    _isActive = false;
    _updateState(_state.copyWith(status: JuzDownloadStatus.cancelling));
  }

  Future<void> delete() async {
    if ([
      JuzDownloadStatus.downloading,
      JuzDownloadStatus.pausing,
      JuzDownloadStatus.cancelling,
      JuzDownloadStatus.deleting
    ].contains(_state.status)) {
      print(
          '[JuzDownloadManager] Refusing to delete: download in progress or pending.');
      return;
    }
    _updateState(_state.copyWith(status: JuzDownloadStatus.deleting));
    try {
      final dir = await getApplicationDocumentsDirectory();
      final juzDir = Directory('${dir.path}/quran_juz_$juzNumber');
      if (juzDir.existsSync()) {
        await juzDir.delete(recursive: true);
      }
      _updateState(JuzDownloadState.initial());
    } catch (e) {
      _updateState(_state.copyWith(
          status: JuzDownloadStatus.error, errorMessage: e.toString()));
    }
  }

  Future<Map<String, dynamic>> getDownloadInfo() async {
    final dir = await _getDownloadDirectory();
    if (_isDisposed) return {'fileCount': 0, 'totalSize': 0};
    if (!await dir.exists()) {
      return {'fileCount': 0, 'totalSize': 0};
    }
    final files = dir.listSync().whereType<File>().toList();
    if (_isDisposed) return {'fileCount': 0, 'totalSize': 0};

    int totalSize = 0;
    for (final file in files) {
      if (file is File) {
        totalSize += file.lengthSync();
        if (_isDisposed) return {'fileCount': 0, 'totalSize': 0};
      }
    }
    return {'fileCount': files.length, 'totalSize': totalSize};
  }

  void _updateState(JuzDownloadState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
    _saveState();
  }

  Future<Directory> _getDownloadDirectory() async {
    if (_downloadDir != null) return _downloadDir!;
    final appDir = await getApplicationDocumentsDirectory();
    if (_isDisposed)
      return Directory(appDir.path); // Return dummy to prevent crash
    _downloadDir = Directory('${appDir.path}/quran_juz_$juzNumber');
    if (!await _downloadDir!.exists()) {
      await _downloadDir!.create(recursive: true);
    }
    return _downloadDir!;
  }

  Future<List<DriveFile>> _getFilesToDownload() async {
    _allFiles ??= await GoogleDriveHelper.listFilesInFolder(folderId);
    if (_isDisposed) return [];
    final dir = await _getDownloadDirectory();
    final localFiles = (await dir.list().toList())
        .map((f) => f.path.split(Platform.pathSeparator).last)
        .toSet();
    return _allFiles!.where((file) => !localFiles.contains(file.name)).toList();
  }

  Future<void> _downloadJuzConcurrent({bool resume = false}) async {
    if (!resume) {
      _updateState(JuzDownloadState.initial()
          .copyWith(status: JuzDownloadStatus.downloading));
    }

    try {
      final filesToDownload = await _getFilesToDownload();
      if (_isDisposed) return;

      if (filesToDownload.isEmpty && !resume) {
        return;
      }

      _updateState(_state.copyWith(totalFiles: _allFiles!.length));

      final queue = List<DriveFile>.from(filesToDownload);
      int inProgress = 0;
      int completed = 0;
      int completedBytes = 0;
      final Set<int> finishedIndexes = {};
      final Completer<void> allDone = Completer<void>();
      int nextIndex = 0;

      bool shouldStop() => _isPaused || _isCancelled;

      void startNext() {
        if (shouldStop()) return;
        while (inProgress < concurrentDownloads &&
            nextIndex < queue.length &&
            !shouldStop()) {
          final idx = nextIndex++;
          inProgress++;
          final file = queue[idx];
          _updateState(_state.copyWith(currentFile: file.name));
          _downloadFile(file).then((bytes) {
            finishedIndexes.add(idx);
            inProgress--;

            if (bytes > 0) {
              completed++;
              if (file.size != null) completedBytes += file.size!;
            }

            _updateState(_state.copyWith(
              downloadedFiles: completed,
              progress:
                  _allFiles!.isEmpty ? 0.0 : completed / _allFiles!.length,
              downloadedBytes: completedBytes,
              currentFile: file.name,
            ));

            if (!allDone.isCompleted) {
              if (finishedIndexes.length == queue.length || shouldStop()) {
                allDone.complete();
              } else {
                startNext();
              }
            }
          });
        }
      }

      startNext();

      while (finishedIndexes.length < queue.length && !shouldStop()) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await allDone.future;
      _isActive = false;

      final dir = await _getDownloadDirectory();
      if (_isDisposed) return;

      final filesOnDisk = dir.listSync().whereType<File>().toList();
      final allDownloaded =
          filesOnDisk.length == _allFiles!.length && _allFiles!.isNotEmpty;

      if (_isCancelled) {
        _updateState(_state.copyWith(status: JuzDownloadStatus.cancelled));
      } else if (_isPaused) {
        _updateState(_state.copyWith(status: JuzDownloadStatus.paused));
      } else if (allDownloaded) {
        _updateState(_state.copyWith(
          status: JuzDownloadStatus.completed,
          progress: 1.0,
          currentFile: '',
        ));
      } else {
        _updateState(_state.copyWith(
          status: JuzDownloadStatus.idle,
          progress:
              _allFiles!.isEmpty ? 0.0 : filesOnDisk.length / _allFiles!.length,
          currentFile: '',
        ));
      }
    } catch (e) {
      if (_isDisposed) return;
      _isActive = false;
      _updateState(_state.copyWith(
          status: JuzDownloadStatus.error, errorMessage: e.toString()));
    }
  }

  Future<int> _downloadFile(DriveFile file) async {
    final dir = await _getDownloadDirectory();
    if (_isDisposed) return 0;
    final savePath = '${dir.path}/${file.name}';

    try {
      if (_isPaused || _isCancelled) return 0;
      final url = GoogleDriveHelper.getDownloadUrl(file.id);
      await _dio.download(url, savePath);
      if (_isPaused || _isCancelled) return 0;
      final imageFile = File(savePath);
      return file.size ?? await imageFile.length();
    } catch (e) {
      print(
          '[JuzDownloadManager] Resiliently handling error for ${file.name}: $e');
      return 0;
    }
  }
}
