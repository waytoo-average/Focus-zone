import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;
import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Types of updates available
enum UpdateType {
  full,  // Full APK update
  patch, // Patch update (Dart code, assets)
  none,  // No update available
}

/// Information about an available update
class UpdateInfo {
  final String latestVersion;
  final String? apkUrl;
  final String? patchUrl;
  final String changelog;
  final bool mandatory;
  final UpdateType updateType;
  final double sizeMb;
  final String? minRequiredVersion;
  final Map<String, String>? releaseNotes;

  UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    this.patchUrl,
    required this.changelog,
    required this.mandatory,
    this.updateType = UpdateType.full,
    this.sizeMb = 0,
    this.minRequiredVersion,
    this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'] ?? json['latestVersion'] ?? '1.0.0',
      apkUrl: json['apk_url'] ?? json['apkUrl'],
      patchUrl: json['patch_url'] ?? json['patchUrl'],
      changelog: json['changelog'] ?? 'Bug fixes and improvements',
      mandatory: json['is_mandatory'] ?? json['isMandatory'] ?? json['mandatory'] ?? false,
      updateType: _parseUpdateType(json['update_type'] ?? json['updateType']),
      sizeMb: (json['size_mb'] ?? json['sizeMb'] ?? 0).toDouble(),
      minRequiredVersion: json['min_required_version'] ?? json['minRequiredVersion'],
      releaseNotes: json['release_notes'] != null 
          ? Map<String, String>.from(json['release_notes']) 
          : null,
    );
  }

  static UpdateType _parseUpdateType(dynamic type) {
    if (type == null) return UpdateType.full;
    if (type is String) {
      return UpdateType.values.firstWhere(
        (e) => e.toString().split('.').last == type.toLowerCase(),
        orElse: () => UpdateType.full,
      );
    }
    return UpdateType.full;
  }

  /// Whether this is a patch update
  bool get isPatchUpdate => updateType == UpdateType.patch && patchUrl != null;
  
  /// Alias for mandatory to maintain backward compatibility
  bool get isMandatory => mandatory;

  /// Gets the release notes for the current locale
  String? getLocalizedReleaseNotes([String? languageCode]) {
    final locale = languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    return releaseNotes?[locale] ?? releaseNotes?['en'] ?? changelog;
  }
}

class UpdateHelper {
  static const String _updateJsonUrl = 'https://waytoo-average.github.io/app_updates/update.json';
  // Base URL for updates (kept for future use)
  // ignore: unused_field
  static const String _updateBaseUrl = 'https://waytoo-average.github.io/app_updates/';
  
  // Cache for the current update info
  static UpdateInfo? _cachedUpdateInfo;
  static DateTime? _lastUpdateCheck;
  
  /// Checks for available updates
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      // Use cache if last check was less than 30 minutes ago
      if (_cachedUpdateInfo != null && 
          _lastUpdateCheck != null &&
          DateTime.now().difference(_lastUpdateCheck!) < const Duration(minutes: 30)) {
        return _cachedUpdateInfo;
      }
      
      final response = await http.get(Uri.parse(_updateJsonUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final updateInfo = UpdateInfo.fromJson(jsonData);
        final packageInfo = await PackageInfo.fromPlatform();
        
        // Check if update is needed
        if (_isNewerVersion(updateInfo.latestVersion, packageInfo.version)) {
          _cachedUpdateInfo = updateInfo;
          _lastUpdateCheck = DateTime.now();
          return updateInfo;
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  /// Compares version strings (format: x.y.z)
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();
      
      // Ensure both version have the same number of parts
      final maxLength = latestParts.length > currentParts.length 
          ? latestParts.length 
          : currentParts.length;
          
      for (int i = 0; i < maxLength; i++) {
        final latestPart = i < latestParts.length ? latestParts[i] : 0;
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        
        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
    } catch (e) {
      debugPrint('Version comparison failed: $e');
      return false;
    }
    return false;
  }

  /// Downloads a file with progress tracking
  static Future<String?> downloadFile(
    String url, 
    String fileName, 
    void Function(double) onProgress
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      
      // Ensure the directory exists
      await Directory(dir.path).create(recursive: true);
      
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );
      
      // Verify the file exists and is not empty
      final file = File(filePath);
      if (!await file.exists() || await file.length() <= 0) {
        return null;
      }
      
      return filePath;
    } catch (e) {
      debugPrint('File download failed ($url): $e');
      return null;
    }
  }

  /// Installs an APK file
  static Future<bool> installApk(String apkPath) async {
    try {
      // Check if we have the installation permission
      if (!await _checkInstallPermission()) {
        return false;
      }

      // Open the APK file
      final result = await OpenFilex.open(apkPath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('APK installation failed: $e');
      return false;
    }
  }

  /// Checks if we have permission to install APKs
  static Future<bool> _checkInstallPermission() async {
    if (Platform.isAndroid) {
      // On Android 8.0+, we need to request the install permission
      if (await Permission.requestInstallPackages.request().isGranted) {
        return true;
      }
      
      // For older Android versions, check if we can install from unknown sources
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    }
    return false;
  }

  // This method was a duplicate and has been removed

  /// Checks for and applies available updates
  static Future<bool> checkAndApplyUpdates() async {
    try {
      final updateInfo = await checkForUpdate();
      if (updateInfo == null) return false;
      
      if (updateInfo.isPatchUpdate && updateInfo.patchUrl != null) {
        // Try patch update first
        final patchPath = await downloadFile(
          updateInfo.patchUrl!,
          'update_${updateInfo.latestVersion}.zip',
          (progress) {}, // Empty progress callback since we're not using it here
        );
        
        if (patchPath != null) {
          final success = await applyPatchUpdate(updateInfo, (progress) {
            // Progress callback for patch application
            debugPrint('Patch apply progress: ${(progress * 100).toStringAsFixed(1)}%');
          });
          if (success) return true;
          
          // Fall back to full APK if patch fails
          debugPrint('Patch update failed, falling back to full APK');
        }
      }
      
      // Full APK update
      if (updateInfo.apkUrl != null) {
        final apkPath = await downloadFile(
          updateInfo.apkUrl!,
          'app_${updateInfo.latestVersion}.apk',
          (progress) {}, // Empty progress callback since we're not using it here
        );
        
        if (apkPath != null) {
          return await installApk(apkPath);
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Update process failed: $e');
      return false;
    }
  }
  
  /// Downloads and installs an APK update
  static Future<bool> installApkUpdate(UpdateInfo updateInfo, void Function(double) onProgress) async {
    if (updateInfo.apkUrl == null) return false;
    
    try {
      // Download the APK
      final apkPath = await downloadFile(
        updateInfo.apkUrl!,
        'app_${updateInfo.latestVersion}.apk',
        (progress) => onProgress(0.6 + (progress * 0.4)),
      );
      if (apkPath == null) return false;
      
      // Request install permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.requestInstallPackages.request();
        if (!status.isGranted) {
          debugPrint('Install unknown apps permission not granted');
          return false;
        }
      }
      
      // Open the APK file
      final result = await OpenFilex.open(apkPath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('APK installation failed: $e');
      return false;
    }
  }
  
  /// Applies a patch update
  static Future<bool> applyPatchUpdate(UpdateInfo updateInfo, void Function(double) onProgress) async {
    if (updateInfo.patchUrl == null) return false;
    
    try {
      // Download the patch file
      final patchPath = await downloadFile(
        updateInfo.patchUrl!,
        'update_${updateInfo.latestVersion}.zip',
        (progress) => onProgress(0.1 + (progress * 0.4)),
      );
      if (patchPath == null) return false;
      
      // Extract and apply the patch
      final success = await _applyPatch(patchPath);
      
      // Clean up the downloaded file
      try {
        await File(patchPath).delete();
      } catch (e) {
        debugPrint('Failed to clean up patch file: $e');
      }
      
      return success;
    } catch (e) {
      debugPrint('Patch application failed: $e');
      return false;
    }
  }
  
  /// Applies a patch from a zip file
  /// Note: For Flutter apps, patch updates are limited to assets and configuration files
  /// Code changes still require a full APK update due to Flutter's compilation model
  static Future<bool> _applyPatch(String zipPath) async {
    try {
      // Read the zip file
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      // Get the application documents directory for storing patch files
      final appDocDir = await getApplicationDocumentsDirectory();
      final patchDir = Directory('${appDocDir.path}/patches');
      await patchDir.create(recursive: true);
      
      List<String> updatedFiles = [];
      
      // Extract and categorize files from the zip
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          
          // Only allow updating certain file types for security
          if (_isPatchableFile(filename)) {
            final outputFile = File('${patchDir.path}/$filename');
            
            // Ensure the directory exists
            await outputFile.parent.create(recursive: true);
            
            // Write the file
            await outputFile.writeAsBytes(data);
            updatedFiles.add(filename);
            
            debugPrint('Patched file: $filename');
          } else {
            debugPrint('Skipped non-patchable file: $filename');
          }
        }
      }
      
      if (updatedFiles.isEmpty) {
        debugPrint('No patchable files found in update');
        return false;
      }
      
      // Store patch metadata
      final patchInfo = {
        'applied_at': DateTime.now().toIso8601String(),
        'files': updatedFiles,
        'patch_source': zipPath,
      };
      
      final metadataFile = File('${patchDir.path}/patch_metadata.json');
      await metadataFile.writeAsString(json.encode(patchInfo));
      
      debugPrint('Patch applied successfully. ${updatedFiles.length} files updated.');
      debugPrint('Note: App restart may be required for some changes to take effect.');
      
      return true;
    } catch (e) {
      debugPrint('Failed to apply patch: $e');
      return false;
    }
  }
  
  /// Checks if a file can be safely patched
  static bool _isPatchableFile(String filename) {
    // Only allow certain file types to be patched for security
    final allowedExtensions = ['.json', '.txt', '.md', '.yaml', '.yml'];
    final allowedPaths = ['assets/', 'lib/assets/', 'config/'];
    
    // Check file extension
    for (final ext in allowedExtensions) {
      if (filename.toLowerCase().endsWith(ext)) return true;
    }
    
    // Check if it's in an allowed directory
    for (final path in allowedPaths) {
      if (filename.startsWith(path)) return true;
    }
    
    return false;
  }

  /// Tries to open the app settings where user can enable "Install unknown apps"
  static Future<bool> openInstallUnknownSourcesSettings() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Try to open the app's settings page where user can find the option
      return await openAppSettings();
    } catch (e) {
      debugPrint('Failed to open app settings: $e');
      return false;
    }
  }
  
  /// Gets the appropriate update URL based on the update type
  static String getUpdateUrl(UpdateInfo updateInfo) {
    if (updateInfo.isPatchUpdate && updateInfo.patchUrl != null) {
      return updateInfo.patchUrl!;
    }
    return updateInfo.apkUrl ?? '';
  }
  
  /// Gets the update size in a human-readable format
  static String getUpdateSize(UpdateInfo updateInfo) {
    if (updateInfo.sizeMb > 0) {
      return '${updateInfo.sizeMb.toStringAsFixed(1)} MB';
    }
    return updateInfo.isPatchUpdate ? 'Small update' : 'Update';
  }
}
