import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String latestVersion;
  final String apkUrl;
  final String changelog;
  final bool mandatory;

  UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.changelog,
    required this.mandatory,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'],
      apkUrl: json['apk_url'],
      changelog: json['changelog'],
      mandatory: json['mandatory'] ?? false,
    );
  }
}

class UpdateHelper {
  static const String updateJsonUrl =
      'https://yourusername.github.io/myapp-updates/update.json'; // TODO: Replace with your actual URL

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(Uri.parse(updateJsonUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final updateInfo = UpdateInfo.fromJson(jsonData);
        final packageInfo = await PackageInfo.fromPlatform();
        if (_isNewerVersion(updateInfo.latestVersion, packageInfo.version)) {
          return updateInfo;
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();
    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i])
        return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static Future<String?> downloadApk(
      String url, void Function(double)? onProgress) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;
      final filePath = '${dir.path}/update.apk';
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );
      return filePath;
    } catch (e) {
      debugPrint('APK download failed: $e');
      return null;
    }
  }

  static Future<void> installApk(String filePath) async {
    await OpenFile.open(filePath);
  }
}
