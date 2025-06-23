import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../google_drive_helper.dart';

enum DownloadStatus {
  idle,
  downloading,
  paused,
  completed,
  cancelled,
  error,
}

class DownloadProgress {
  final int downloadedFiles;
  final int totalFiles;
  final double progress;
  final String currentFile;
  final int downloadedBytes;
  final int totalBytes;

  DownloadProgress({
    required this.downloadedFiles,
    required this.totalFiles,
    required this.progress,
    required this.currentFile,
    required this.downloadedBytes,
    required this.totalBytes,
  });
}

class QuranDownloadService {
  static final QuranDownloadService _instance =
      QuranDownloadService._internal();
  factory QuranDownloadService() => _instance;
  QuranDownloadService._internal();

  DownloadStatus _status = DownloadStatus.idle;
  DownloadProgress? _progress;
  StreamController<DownloadProgress>? _progressController;
  StreamController<DownloadStatus>? _statusController;
  bool _isCancelled = false;
  bool _isPaused = false;
  bool _isDisposed = false;
  List<String> _downloadedFiles = [];
  List<DriveFile>? _allFiles;
  Directory? _downloadDir;

  // Getters
  DownloadStatus get status => _status;
  DownloadProgress? get progress => _progress;
  Stream<DownloadProgress> get progressStream =>
      _progressController?.stream ?? Stream.empty();
  Stream<DownloadStatus> get statusStream =>
      _statusController?.stream ?? Stream.empty();
  bool get isDownloading => _status == DownloadStatus.downloading;
  bool get isPaused => _status == DownloadStatus.paused;
  bool get isCompleted => _status == DownloadStatus.completed;

  // Initialize streams
  void _initializeStreams() {
    if (_isDisposed) return;
    _progressController = StreamController<DownloadProgress>.broadcast();
    _statusController = StreamController<DownloadStatus>.broadcast();
  }

  // Dispose streams
  void dispose() {
    _isDisposed = true;
    _progressController?.close();
    _statusController?.close();
    _progressController = null;
    _statusController = null;
  }

  // Update status and notify listeners
  void _updateStatus(DownloadStatus newStatus) {
    if (_isDisposed || _statusController?.isClosed == true) return;
    _status = newStatus;
    _statusController?.add(newStatus);
  }

  // Update progress and notify listeners
  void _updateProgress(DownloadProgress newProgress) {
    if (_isDisposed || _progressController?.isClosed == true) return;
    _progress = newProgress;
    _progressController?.add(newProgress);
  }

  // Start or resume download
  Future<void> startDownload(String folderId,
      {bool isWholeQuran = false}) async {
    if (_status == DownloadStatus.downloading || _isDisposed) return;

    _isCancelled = false;
    _isPaused = false;
    _initializeStreams();

    // Setup directory
    final appDir = await getApplicationDocumentsDirectory();
    _downloadDir = Directory(
        '${appDir.path}/${isWholeQuran ? 'quran_full' : 'quran_juz_$folderId'}');
    if (!_downloadDir!.existsSync()) {
      await _downloadDir!.create(recursive: true);
    }

    // Get list of files to download
    try {
      _allFiles = await GoogleDriveHelper.listFilesInFolder(folderId);
      _downloadedFiles = _getExistingFiles();

      _updateStatus(DownloadStatus.downloading);

      await _downloadFiles();
    } catch (e) {
      if (!_isDisposed) {
        _updateStatus(DownloadStatus.error);
      }
      rethrow;
    }
  }

  // Get list of already downloaded files
  List<String> _getExistingFiles() {
    if (_downloadDir == null || !_downloadDir!.existsSync()) return [];

    return _downloadDir!
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith('.jpg') ||
            f.path.endsWith('.jpeg') ||
            f.path.endsWith('.png'))
        .map((f) => f.path.split('/').last)
        .toList();
  }

  // Download files with pause/resume support
  Future<void> _downloadFiles() async {
    if (_allFiles == null || _isDisposed) return;

    int downloadedCount = _downloadedFiles.length;
    int totalBytes = 0;
    int downloadedBytes = 0;

    // Calculate total size
    for (final file in _allFiles!) {
      if (file.size != null) {
        totalBytes += file.size!;
      }
    }

    // Calculate already downloaded bytes
    for (final fileName in _downloadedFiles) {
      final file = _allFiles!.firstWhere(
        (f) => f.name == fileName,
        orElse: () => DriveFile(id: '', name: fileName, mimeType: '', size: 0),
      );
      if (file.size != null) {
        downloadedBytes += file.size!;
      }
    }

    for (int i = 0; i < _allFiles!.length; i++) {
      final file = _allFiles![i];

      // Skip if already downloaded
      if (_downloadedFiles.contains(file.name)) {
        continue;
      }

      // Check for cancellation or disposal
      if (_isCancelled || _isDisposed) {
        if (!_isDisposed) {
          _updateStatus(DownloadStatus.cancelled);
        }
        return;
      }

      // Check for pause
      while (_isPaused && !_isDisposed) {
        if (!_isDisposed) {
          _updateStatus(DownloadStatus.paused);
        }
        await Future.delayed(const Duration(milliseconds: 100));

        if (_isCancelled || _isDisposed) {
          if (!_isDisposed) {
            _updateStatus(DownloadStatus.cancelled);
          }
          return;
        }
      }

      if (!_isDisposed) {
        _updateStatus(DownloadStatus.downloading);
      }

      try {
        // Download file
        final url = GoogleDriveHelper.getDownloadUrl(file.id);
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200 && !_isDisposed) {
          final imageFile = File('${_downloadDir!.path}/${file.name}');
          await imageFile.writeAsBytes(response.bodyBytes);

          downloadedCount++;
          if (file.size != null) {
            downloadedBytes += file.size!;
          }
          _downloadedFiles.add(file.name);

          // Update progress
          final progress = downloadedCount / _allFiles!.length;
          _updateProgress(DownloadProgress(
            downloadedFiles: downloadedCount,
            totalFiles: _allFiles!.length,
            progress: progress,
            currentFile: file.name,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
          ));
        }
      } catch (e) {
        print('Error downloading ${file.name}: $e');
        // Continue with next file instead of stopping
      }
    }

    if (!_isCancelled && !_isDisposed) {
      _updateStatus(DownloadStatus.completed);
    }
  }

  // Pause download
  void pauseDownload() {
    if (_status == DownloadStatus.downloading && !_isDisposed) {
      _isPaused = true;
    }
  }

  // Resume download
  void resumeDownload() {
    if (_status == DownloadStatus.paused && !_isDisposed) {
      _isPaused = false;
    }
  }

  // Cancel download
  void cancelDownload() {
    _isCancelled = true;
    _isPaused = false;
  }

  // Delete downloaded files
  Future<void> deleteDownload({bool isWholeQuran = false}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${appDir.path}/${isWholeQuran ? 'quran_full' : 'quran_juz'}');

    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }

    _downloadedFiles.clear();
    _progress = null;
    if (!_isDisposed) {
      _updateStatus(DownloadStatus.idle);
    }
  }

  // Get download info
  Future<Map<String, dynamic>> getDownloadInfo(
      {bool isWholeQuran = false}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${appDir.path}/${isWholeQuran ? 'quran_full' : 'quran_juz'}');

    if (!dir.existsSync()) {
      return {
        'exists': false,
        'fileCount': 0,
        'totalSize': 0,
      };
    }

    final files = dir
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
}
