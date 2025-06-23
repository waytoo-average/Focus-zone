import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleDriveHelper {
  static const String apiKey = 'AIzaSyA9PZz-Mbpt-LrTrWKsUBaeYdKTlBnb8H0';

  static Future<List<DriveFile>> listFilesInFolder(String folderId) async {
    List<DriveFile> allFiles = [];
    String? nextPageToken;

    do {
      final url = Uri.parse('https://www.googleapis.com/drive/v3/files')
          .replace(queryParameters: {
        'q': "'$folderId' in parents and trashed=false",
        'key': apiKey,
        'fields': 'files(id,name,mimeType,size),nextPageToken',
        'pageSize': '1000', // Maximum allowed
        if (nextPageToken != null) 'pageToken': nextPageToken,
      });

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files =
            (data['files'] as List).map((f) => DriveFile.fromJson(f)).toList();
        allFiles.addAll(files);

        // Check if there are more pages
        nextPageToken = data['nextPageToken'];
      } else {
        throw Exception('Failed to list files: ${response.body}');
      }
    } while (nextPageToken != null);

    return allFiles;
  }

  static String getDownloadUrl(String fileId) {
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }

  // List all subfolders (Juz folders) in a parent folder
  static Future<List<DriveFile>> listSubfolders(String parentFolderId) async {
    final url =
        'https://www.googleapis.com/drive/v3/files?q=\'$parentFolderId\'+in+parents+and+trashed=false+and+mimeType="application/vnd.google-apps.folder"&key=$apiKey&fields=files(id,name)';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final files =
          (data['files'] as List).map((f) => DriveFile.fromJson(f)).toList();
      return files;
    } else {
      throw Exception('Failed to list subfolders: ${response.body}');
    }
  }
}

class DriveFile {
  final String id;
  final String name;
  final String mimeType;
  final int? size; // File size in bytes, null for folders

  DriveFile(
      {required this.id,
      required this.name,
      required this.mimeType,
      this.size});

  factory DriveFile.fromJson(Map<String, dynamic> json) {
    return DriveFile(
      id: json['id'],
      name: json['name'],
      mimeType: json['mimeType'],
      size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
    );
  }

  // Get formatted size string
  String get formattedSize {
    if (size == null) return 'Unknown';
    if (size! < 1024) return '${size}B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)}KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
