// Imports specific to study features
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // For File operations
import 'package:intl/intl.dart'; // For date formatting
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
// For permissions
import 'package:open_filex/open_filex.dart';
import 'helper.dart'; // For MaterialUploadHelper and ContentManager
import 'package:google_sign_in/google_sign_in.dart'; // For leader authentication
import 'dart:developer' as developer;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:googleapis/drive/v3.dart' as drive_write;

// Core app imports (from app_core.dart)
import 'package:app/app_core.dart';
import 'package:app/src/utils/app_animations.dart';

import 'l10n/app_localizations.dart'; // For AcademicContext, SignInProvider, DownloadPathProvider, AppLocalizations, ErrorScreen, showAppSnackBar, formatBytesSimplified

// --- Dynamic Academic Content System ---
// Semester root folder IDs - subjects will be discovered dynamically using public Drive API
const Map<String, String> semesterRootFolders = {
  // First Grade
  'First Grade Communication Current Year Semester 1':
      '1F-aqh6UK5x8Cbva6Zr0UvnchyV8hDGp2',
  'First Grade Communication Current Year Semester 2':
      '1Xl2tlH1leBqoY10nwZvt_Hs4qsCMSNeL',
  'First Grade Communication Last Year Semester 1':
      '11YuvupTtPcZuTKAQOm9onpDrq6HwUTQS',
  'First Grade Communication Last Year Semester 2':
      '12g0GqJ__VAOwwr9Skqy7DHhfAAumstxl',
  'First Grade Electronics Current Year Semester 1':
      '1PR7sqZwA_4LgumJC0k3Af0aZ_ba2Zl30',
  'First Grade Electronics Current Year Semester 2':
      '1N7EiilaFCKUEE_O7Dy3P71FAcuREylXo',
  'First Grade Electronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'First Grade Electronics Last Year Semester 2':
      '', // Empty - no folder ID provided
  'First Grade Mechatronics Current Year Semester 1':
      '1xthA_-KhZ5Edi3jloRkwRAIMM6ljpoIS',
  'First Grade Mechatronics Current Year Semester 2':
      '1rVnXee3-ELWNBJ8OSoOILw0DbmuKjGxo',
  'First Grade Mechatronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'First Grade Mechatronics Last Year Semester 2':
      '', // Empty - no folder ID provided

  // Second Grade
  'Second Grade Communication Current Year Semester 1':
      '1Ps1L5YOmU_LXfnb9sqwVtILVP5T3LjB9',
  'Second Grade Communication Current Year Semester 2':
      '1VUro5liVUNKtYG247Hwmq2fDQqkHqOhH',
  'Second Grade Communication Last Year Semester 1':
      '1bm4KMv65KpJqFPLNFcSMf4DItNq-H0WS',
  'Second Grade Communication Last Year Semester 2':
      '1rsfY18ebWzQPfYQIhhB_UAv0MIW_Q7Ot',
  'Second Grade Electronics Current Year Semester 1':
      '1q4FTG3ACwiu9z_n653kKkxx3DuZVJ2iV',
  'Second Grade Electronics Current Year Semester 2':
      '1XuYkkqZc1APLemfyKRuq_30Imzy_Hi4-',
  'Second Grade Electronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'Second Grade Electronics Last Year Semester 2':
      '', // Empty - no folder ID provided
  'Second Grade Mechatronics Current Year Semester 1':
      '1JKca-qZKuFN_S8wW0cNLYZqtJfuHyRJd',
  'Second Grade Mechatronics Current Year Semester 2':
      '1PL--naKlzPEehYLt4TbT9on4IG7szwmi',
  'Second Grade Mechatronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'Second Grade Mechatronics Last Year Semester 2':
      '', // Empty - no folder ID provided

  // Third Grade
  'Third Grade Communication Current Year Semester 1':
      '1LfORh3S9XzjmgeiPXpAHGs_78utNUznc',
  'Third Grade Communication Current Year Semester 2':
      '12edu3L3lWkiQTWqXkAWxzLaUo_4jXkXV',
  'Third Grade Communication Last Year Semester 1':
      '1dnZ-B3w0eho4DLQuaUjcu_gYRxQVUh27',
  'Third Grade Communication Last Year Semester 2':
      '1sHx6GHS5GGNfUWcAzJdDLXoxm5dJQUW5',
  'Third Grade Electronics Current Year Semester 1':
      '18s3_6cK3XaCGswmaaM3BqyqyWiE9adq0',
  'Third Grade Electronics Current Year Semester 2':
      '1g9QQto6aulAGb1s6jjBXStqnwyR3lWrI',
  'Third Grade Electronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'Third Grade Electronics Last Year Semester 2':
      '', // Empty - no folder ID provided
  'Third Grade Mechatronics Current Year Semester 1':
      '1pWHRg_DNnWHefQer6yfxf5SnNd4PFKVV',
  'Third Grade Mechatronics Current Year Semester 2':
      '16QAM_Dcbm9GPYOk5O5wi-Vo3WcS70Bus',
  'Third Grade Mechatronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'Third Grade Mechatronics Last Year Semester 2':
      '', // Empty - no folder ID provided

  // Fourth Grade
  'Fourth Grade Communication Current Year Semester 1':
      '1I353V2Dd1END87jCYcZb33fOmhjjKnGJ',
  'Fourth Grade Communication Current Year Semester 2':
      '1oJaBS3_nLYjCXIYOgqM5enjYxymw5h59',
  'Fourth Grade Communication Last Year Semester 1':
      '', // Empty - no folder ID provided
  'Fourth Grade Communication Last Year Semester 2':
      '', // Empty - no folder ID provided
  'Fourth Grade Electronics Current Year Semester 1':
      '1KOX51U4QKDJ3plORY7c__YVh7j4A26SH',
  'Fourth Grade Electronics Current Year Semester 2':
      '11I6Q4nEoiXC6lxpo3vTEsalbblIqRIqU',
  'Fourth Grade Electronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'Fourth Grade Electronics Last Year Semester 2':
      '', // Empty - no folder ID provided
  'Fourth Grade Mechatronics Current Year Semester 1':
      '1x_uNebUvo3ZlqpciawuBnu0ooAg_pdfV',
  'Fourth Grade Mechatronics Current Year Semester 2':
      '1p5Y6tooBY9TVaz55mdYL7_xcJYzqY3nY',
  'Fourth Grade Mechatronics Last Year Semester 1':
      '', // Empty - no folder ID provided
  'Fourth Grade Mechatronics Last Year Semester 2':
      '', // Empty - no folder ID provided
};

// --- Leader Mode Authentication System ---
class LeaderModeProvider extends ChangeNotifier {
  // SharedPreferences keys for persistent storage
  static const String _keyIsLeaderMode = 'leader_mode_is_active';
  static const String _keyLeaderEmail = 'leader_mode_email';

  // Department-specific leader accounts mapping
  // Structure: Grade -> Department -> Leader Email
  // Each leader manages both current year and last year for their department
  static const Map<String, Map<String, String>> _departmentLeaders = {
    'First Grade': {
      'Communication': 'eccatcommgrade1.2026@gmail.com',
      'Electronics': 'eccatelectrograde1.2026@gmail.com',
      'Mechatronics': 'eccatmechagrade1.2026@gmail.com',
    },
    'Second Grade': {
      'Communication': 'eccatcommgrade2.2026@gmail.com',
      'Electronics': 'eccatelectrograde2.2026@gmail.com',
      'Mechatronics': 'eccatmechagrade2.2026@gmail.com',
    },
    'Third Grade': {
      'Communication': 'eccatcommgrade3.2026@gmail.com',
      'Electronics': 'eccatelectrograde3.2026@gmail.com',
      'Mechatronics': 'eccatmechagrade3.2026@gmail.com',
    },
    'Fourth Grade': {
      'Communication': 'eccatcommgrade4.2026@gmail.com',
      'Electronics': 'eccatelectrograde4.2026@gmail.com',
      'Mechatronics': 'eccatmechagrade4.2026@gmail.com',
    },
  };

  // Doctor accounts with full access (fetched from remote JSON)
  static List<String> _doctorAccounts = [];

  // Fetch doctor accounts from GitHub repository
  static Future<bool> fetchDoctorAccounts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://raw.githubusercontent.com/waytoo-average/app_updates/main/doctor_accounts.json'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> accounts = data['doctor_accounts'] ?? [];
        _doctorAccounts = accounts.cast<String>();
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error fetching doctor accounts: $e',
          name: 'LeaderModeProvider');
      return false;
    }
  }

  // Get all authorized emails as a flat list
  static List<String> get _allAuthorizedEmails {
    final List<String> emails = [];
    _departmentLeaders.forEach((grade, departments) {
      departments.forEach((department, leader) {
        emails.add(leader);
      });
    });
    emails.addAll(_doctorAccounts); // Add doctor accounts with full access
    return emails.toSet().toList(); // Remove duplicates
  }

  // Separate GoogleSignIn instance for leaders with write permissions
  final GoogleSignIn _leaderGoogleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file', // Write access to files created by the app
    ],
  );

  bool _isLeaderMode = false;
  String? _leaderEmail;
  GoogleSignInAccount? _leaderAccount;
  bool _isAuthenticating = false;
  bool _isInitialized = false;

  bool get isLeaderMode => _isLeaderMode;
  String? get leaderEmail => _leaderEmail;
  bool get isAuthenticating => _isAuthenticating;
  bool get isInitialized => _isInitialized;

  /// Initialize the provider and restore authentication state if available
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if there's a saved authentication state
      final savedIsLeaderMode = prefs.getBool(_keyIsLeaderMode) ?? false;
      final savedLeaderEmail = prefs.getString(_keyLeaderEmail);

      if (savedIsLeaderMode && savedLeaderEmail != null) {
        // Fetch doctor accounts to ensure we have the latest list
        await fetchDoctorAccounts();
        
        // Verify the email is still authorized
        if (_allAuthorizedEmails.contains(savedLeaderEmail)) {
          // Attempt silent sign-in to restore Google account
          final account = await _leaderGoogleSignIn.signInSilently();
          
          if (account != null && account.email == savedLeaderEmail) {
            _leaderAccount = account;
            _leaderEmail = savedLeaderEmail;
            _isLeaderMode = true;
            
            developer.log('Leader mode restored for: $savedLeaderEmail', 
                name: 'LeaderModeProvider');
          } else {
            // Silent sign-in failed, clear saved state
            await _clearSavedAuthState();
          }
        } else {
          // Email no longer authorized, clear saved state
          await _clearSavedAuthState();
        }
      }
    } catch (e) {
      developer.log('Error initializing leader mode: $e', name: 'LeaderModeProvider');
      await _clearSavedAuthState();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Clear saved authentication state
  Future<void> _clearSavedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLeaderMode);
      await prefs.remove(_keyLeaderEmail);
      
      _isLeaderMode = false;
      _leaderEmail = null;
      _leaderAccount = null;
    } catch (e) {
      developer.log('Error clearing saved auth state: $e', name: 'LeaderModeProvider');
    }
  }

  /// Save authentication state to persistent storage
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLeaderMode, _isLeaderMode);
      if (_leaderEmail != null) {
        await prefs.setString(_keyLeaderEmail, _leaderEmail!);
      }
    } catch (e) {
      developer.log('Error saving auth state: $e', name: 'LeaderModeProvider');
    }
  }

  /// Authenticate leader and enable leader mode
  Future<bool> authenticateLeader(BuildContext context,
      {bool isDoctorMode = false}) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      // Fetch doctor accounts if in doctor mode or if list is empty
      if (isDoctorMode || _doctorAccounts.isEmpty) {
        await fetchDoctorAccounts();
      }

      final GoogleSignInAccount? account = await _leaderGoogleSignIn.signIn();

      if (account != null && _allAuthorizedEmails.contains(account.email)) {
        _leaderAccount = account;
        _leaderEmail = account.email;
        _isLeaderMode = true;
        _isAuthenticating = false;
        
        // Save authentication state to persistent storage
        await _saveAuthState();
        
        notifyListeners();

        if (context.mounted) {
          final roleText = isDoctorMode ? AppLocalizations.of(context)!.doctor : AppLocalizations.of(context)!.leader;
          showAppSnackBar(
            context,
            AppLocalizations.of(context)!.modeActivatedFor(roleText, account.displayName ?? ''),
            icon: isDoctorMode
                ? Icons.school
                : Icons.admin_panel_settings,
            iconColor: Colors.green,
          );
        }
        return true;
      } else {
        await _leaderGoogleSignIn.signOut();
        _isAuthenticating = false;
        notifyListeners();

        if (context.mounted) {
          showAppSnackBar(
            context,
            AppLocalizations.of(context)!.accessDenied,
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
        return false;
      }
    } catch (e) {
      _isAuthenticating = false;
      notifyListeners();

      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.authenticationFailed(e.toString()),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    }
  }

  /// Sign out leader and disable leader mode
  Future<void> signOutLeader(BuildContext context) async {
    try {
      await _leaderGoogleSignIn.signOut();
      _leaderAccount = null;
      _leaderEmail = null;
      _isLeaderMode = false;
      
      // Clear saved authentication state
      await _clearSavedAuthState();
      
      notifyListeners();

      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.leaderModeDeactivated,
          icon: Icons.logout,
          iconColor: Colors.orange,
        );
      }
    } catch (e) {
      developer.log('Error signing out leader: $e', name: 'LeaderModeProvider');
    }
  }

  /// Get authenticated HTTP client for Drive API write operations
  Future<http.Client?> get authenticatedHttpClient async {
    if (_leaderAccount == null) return null;

    try {
      final Map<String, String> headers = await _leaderAccount!.authHeaders;
      return GoogleHttpClient(headers);
    } catch (e) {
      developer.log('Error getting authenticated client: $e',
          name: 'LeaderModeProvider');
      return null;
    }
  }

  // Check if the current leader can upload to specific grade/department/year
  bool canUploadTo(String grade, String department, String year) {
    if (_leaderEmail == null) return false;

    // Doctors have full access to everything
    if (_doctorAccounts.contains(_leaderEmail)) return true;

    final departmentLeaders = _departmentLeaders[grade];
    if (departmentLeaders == null) return false;

    // Normalize department name for flexible matching
    String normalizedDepartment = department.toLowerCase()
        .replaceAll(' department', '')
        .replaceAll(' departments', '')
        .replaceAll('department ', '')
        .replaceAll('departments ', '')
        .trim();

    // Try to find a matching department leader with flexible name matching
    for (final entry in departmentLeaders.entries) {
      String normalizedKey = entry.key.toLowerCase()
          .replaceAll(' department', '')
          .replaceAll(' departments', '')
          .replaceAll('department ', '')
          .replaceAll('departments ', '')
          .trim();
      
      if (normalizedKey == normalizedDepartment && entry.value.toLowerCase() == _leaderEmail!.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Get leader's authorized areas
  Map<String, List<String>> getLeaderAuthorizations() {
    if (_leaderEmail == null) return {};

    // Doctors have full access
    if (_doctorAccounts.contains(_leaderEmail)) {
      return {
        'All Grades': ['Full Access']
      };
    }

    final Map<String, List<String>> authorizations = {};
    _departmentLeaders.forEach((grade, departments) {
      departments.forEach((department, leader) {
        if (leader == _leaderEmail) {
          final key = '$grade - $department';
          authorizations
              .putIfAbsent(key, () => [])
              .addAll(['Current Year', 'Last Year']);
        }
      });
    });
    return authorizations;
  }

  /// Create folder in Google Drive
  Future<bool> createFolderInDrive({
    required String parentFolderId,
    required String folderName,
    required BuildContext context,
  }) async {
    final client = await authenticatedHttpClient;
    if (client == null) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.authenticationRequired,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    }

    try {
      final driveApi = drive_write.DriveApi(client);

      // Create folder metadata
      final folderMetadata = drive_write.File()
        ..name = folderName
        ..parents = [parentFolderId]
        ..mimeType = 'application/vnd.google-apps.folder';

      // Create folder
      final createdFolder = await driveApi.files.create(folderMetadata);

      if (createdFolder.id != null) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            AppLocalizations.of(context)!.folderCreatedSuccessfully(folderName),
            icon: Icons.folder,
            iconColor: Colors.green,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error creating folder: $e', name: 'LeaderModeProvider');
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.folderCreationFailed(e.toString()),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    } finally {
      client.close();
    }
  }

  /// Rename file or folder in Google Drive
  Future<bool> renameFileOrFolder({
    required String fileId,
    required String newName,
    required String grade,
    required String department,
    required String year,
    required BuildContext context,
  }) async {
    // Check if leader has permission for this grade/department/year
    if (!canUploadTo(grade, department, year)) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.accessDenied,
          icon: Icons.security,
          iconColor: Colors.red,
        );
      }
      return false;
    }
    
    final client = await authenticatedHttpClient;
    if (client == null) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.authenticationRequired,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    }

    try {
      final driveApi = drive_write.DriveApi(client);

      // Update file metadata with new name
      final fileMetadata = drive_write.File()..name = newName;

      await driveApi.files.update(fileMetadata, fileId);

      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.itemRenamed,
          icon: Icons.edit,
          iconColor: Colors.green,
        );
      }
      return true;
    } catch (e) {
      developer.log('Error renaming file: $e', name: 'LeaderModeProvider');
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.renameFailed(e.toString()),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    } finally {
      client.close();
    }
  }

  /// Delete file or folder from Google Drive
  Future<bool> deleteFileOrFolder({
    required String fileId,
    required String fileName,
    required String grade,
    required String department,
    required String year,
    required BuildContext context,
  }) async {
    // Check if leader has permission for this grade/department/year
    if (!canUploadTo(grade, department, year)) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.accessDenied,
          icon: Icons.security,
          iconColor: Colors.red,
        );
      }
      return false;
    }
    
    final client = await authenticatedHttpClient;
    if (client == null) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.authenticationRequired,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    }

    try {
      final driveApi = drive_write.DriveApi(client);

      // Delete the file/folder
      await driveApi.files.delete(fileId);

      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.itemDeleted,
          icon: Icons.delete,
          iconColor: Colors.green,
        );
      }
      return true;
    } catch (e) {
      developer.log('Error deleting file: $e', name: 'LeaderModeProvider');
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.deleteFailed(e.toString()),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    } finally {
      client.close();
    }
  }

  /// Upload file to specific Drive folder
  Future<bool> uploadFileToFolder({
    required String folderId,
    required File file,
    required String fileName,
    required String grade,
    required String department,
    required String year,
    required Function(double) onProgress,
    required BuildContext context,
  }) async {
    // Check if leader has permission for this grade/department/year
    if (!canUploadTo(grade, department, year)) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.accessDenied,
          icon: Icons.security,
          iconColor: Colors.red,
        );
      }
      return false;
    }
    final client = await authenticatedHttpClient;
    if (client == null) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.authenticationRequired,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    }

    try {
      final driveApi = drive_write.DriveApi(client);

      // Create file metadata
      final fileMetadata = drive_write.File()
        ..name = fileName
        ..parents = [folderId];

      // Read file content
      final fileContent = await file.readAsBytes();
      final media =
          drive_write.Media(Stream.value(fileContent), fileContent.length);

      // Upload file
      final uploadedFile = await driveApi.files.create(
        fileMetadata,
        uploadMedia: media,
      );

      if (uploadedFile.id != null) {
        if (context.mounted) {
          showAppSnackBar(
            context,
            AppLocalizations.of(context)!.fileUploadedSuccessfully(fileName),
            icon: Icons.cloud_upload,
            iconColor: Colors.green,
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error uploading file: $e', name: 'LeaderModeProvider');
      if (context.mounted) {
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.uploadFailed(e.toString()),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
      return false;
    } finally {
      client.close();
    }
  }
}

// Google HTTP Client for authenticated requests
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

// Dynamic folder provider for discovering subjects within semester folders
class DynamicFolderProvider extends ChangeNotifier {
  static const String _cachePrefix = 'dynamic_folders_';
  static const Duration _cacheValidDuration = Duration(hours: 6);

  Map<String, Map<String, String>> _cachedSubjects = {};
  Map<String, DateTime> _cacheTimestamps = {};

  // API key for public Drive access (same as existing implementation)
  static const String _apiKey = 'AIzaSyA9PZz-Mbpt-LrTrWKsUBaeYdKTlBnb8H0';

  /// Discover all subject folders within a semester folder using public Drive API
  Future<Map<String, String>> discoverSemesterSubjects(
      String semesterKey) async {
    // Check in-memory cache first
    if (_cachedSubjects.containsKey(semesterKey) &&
        _cacheTimestamps.containsKey(semesterKey)) {
      final cacheTime = _cacheTimestamps[semesterKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheValidDuration) {
        return _cachedSubjects[semesterKey]!;
      }
    }

    // Check persistent cache for offline access
    final cachedData = await _loadFromCache(semesterKey);
    if (cachedData != null) {
      _cachedSubjects[semesterKey] = cachedData;
      return cachedData;
    }

    final semesterFolderId = semesterRootFolders[semesterKey];

    if (semesterFolderId == null || semesterFolderId.isEmpty) {
      return {}; // Return empty if no valid folder ID
    }

    try {
      // Use public Drive API to list folders within the semester folder
      final url = 'https://www.googleapis.com/drive/v3/files'
          '?q=\'$semesterFolderId\'+in+parents+and+mimeType=\'application/vnd.google-apps.folder\''
          '&fields=files(id,name)'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = data['files'] as List<dynamic>;

        final subjects = <String, String>{};
        for (final file in files) {
          final name = file['name'] as String;
          final id = file['id'] as String;
          subjects[name] = id;
        }

        // Cache the results
        _cachedSubjects[semesterKey] = subjects;
        _cacheTimestamps[semesterKey] = DateTime.now();

        // Persist cache to SharedPreferences
        await _persistCache(semesterKey, subjects);

        return subjects;
      } else {
        developer.log(
            'Failed to fetch semester subjects: ${response.statusCode}',
            name: 'DynamicFolderProvider');
        return {};
      }
    } catch (e) {
      developer.log('Error discovering semester subjects: $e',
          name: 'DynamicFolderProvider');
      return {};
    }
  }

  /// Get subjects for a specific semester (with fallback to hardcoded data)
  Future<Map<String, String>> getSubjectsForSemester(
      String grade, String department, String year, String semester) async {
    final semesterKey = '$grade $department $year $semester';
    return await discoverSemesterSubjects(semesterKey);
  }

  /// Load subjects from persistent cache
  Future<Map<String, String>?> _loadFromCache(String semesterKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_cachePrefix$semesterKey');
      final cacheTime = prefs.getInt('${_cachePrefix}time_$semesterKey');

      if (cachedData != null && cacheTime != null) {
        final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        // Use longer cache duration for offline access (24 hours)
        if (DateTime.now().difference(cacheDateTime) <
            const Duration(hours: 24)) {
          final subjects = Map<String, String>.from(json.decode(cachedData));
          _cacheTimestamps[semesterKey] = cacheDateTime;
          return subjects;
        }
      }
    } catch (e) {
      developer.log('Error loading cache: $e', name: 'DynamicFolderProvider');
    }
    return null;
  }

  /// Persist subjects cache to SharedPreferences
  Future<void> _persistCache(
      String semesterKey, Map<String, String> subjects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cachePrefix$semesterKey', json.encode(subjects));
      await prefs.setInt('${_cachePrefix}time_$semesterKey',
          DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      developer.log('Error persisting cache: $e',
          name: 'DynamicFolderProvider');
    }
  }

  /// Preload all cached subjects for offline access
  Future<void> preloadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
          (key) => key.startsWith(_cachePrefix) && !key.contains('time_'));

      for (final key in keys) {
        final semesterKey = key.substring(_cachePrefix.length);
        final cachedData = await _loadFromCache(semesterKey);
        if (cachedData != null) {
          _cachedSubjects[semesterKey] = cachedData;
        }
      }

      notifyListeners();
    } catch (e) {
      developer.log('Error preloading cache: $e',
          name: 'DynamicFolderProvider');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    _cachedSubjects.clear();
    _cacheTimestamps.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      developer.log('Error clearing cache: $e', name: 'DynamicFolderProvider');
    }

    notifyListeners();
  }
}

// Backward compatibility// Helper function to get semester key for dynamic folder lookup
String _getSemesterKey(
    String grade, String department, String year, String semester) {
  // Normalize all values to English to match semesterRootFolders keys
  
  // Normalize grade names
  String normalizedGrade = grade;
  if (grade == 'الفرقة الأولى' || grade == 'First Grade') {
    normalizedGrade = 'First Grade';
  } else if (grade == 'الفرقة الثانية' || grade == 'Second Grade') {
    normalizedGrade = 'Second Grade';
  } else if (grade == 'الفرقة الثالثة' || grade == 'Third Grade') {
    normalizedGrade = 'Third Grade';
  } else if (grade == 'الفرقة الرابعة' || grade == 'Fourth Grade') {
    normalizedGrade = 'Fourth Grade';
  }
  
  // Normalize department names
  String normalizedDepartment = department;
  if (department == 'قسم الاتصالات' || department == 'Communication Department' || department == 'Communication') {
    normalizedDepartment = 'Communication';
  } else if (department == 'قسم الإلكترونيات' || department == 'Electronics Department' || department == 'Electronics') {
    normalizedDepartment = 'Electronics';
  } else if (department == 'قسم الميكاترونيكس' || department == 'Mechatronics Department' || department == 'Mechatronics') {
    normalizedDepartment = 'Mechatronics';
  }
  
  // Normalize year names
  String normalizedYear = year;
  if (year == 'العام الحالي' || year == 'Current Year') {
    normalizedYear = 'Current Year';
  } else if (year == 'العام الماضي' || year == 'Last Year') {
    normalizedYear = 'Last Year';
  }

  // Normalize semester names
  String normalizedSemester = semester;
  if (semester == 'First Semester' || semester == 'Semester 1' || semester == 'الفصل الأول') {
    normalizedSemester = 'Semester 1';
  } else if (semester == 'Second Semester' || semester == 'Semester 2' || semester == 'الفصل الثاني') {
    normalizedSemester = 'Semester 2';
  }

  return '$normalizedGrade $normalizedDepartment $normalizedYear $normalizedSemester';
}

// Helper functions to normalize individual academic context values
String _normalizeGrade(String grade) {
  if (grade == 'الفرقة الأولى' || grade == 'First Grade') {
    return 'First Grade';
  } else if (grade == 'الفرقة الثانية' || grade == 'Second Grade') {
    return 'Second Grade';
  } else if (grade == 'الفرقة الثالثة' || grade == 'Third Grade') {
    return 'Third Grade';
  } else if (grade == 'الفرقة الرابعة' || grade == 'Fourth Grade') {
    return 'Fourth Grade';
  }
  return grade;
}

String _normalizeDepartment(String department) {
  if (department == 'قسم الاتصالات' || department == 'Communication Department' || department == 'Communication') {
    return 'Communication';
  } else if (department == 'قسم الإلكترونيات' || department == 'Electronics Department' || department == 'Electronics') {
    return 'Electronics';
  } else if (department == 'قسم الميكاترونيكس' || department == 'Mechatronics Department' || department == 'Mechatronics') {
    return 'Mechatronics';
  }
  return department;
}

String _normalizeYear(String year) {
  if (year == 'العام الحالي' || year == 'Current Year') {
    return 'Current Year';
  } else if (year == 'العام الماضي' || year == 'Last Year') {
    return 'Last Year';
  }
  return year;
}

// Helper function to get subjects for a semester using dynamic discovery
Future<Map<String, String>> getSubjectsForSemester(
    String grade, String department, String year, String semester) async {
  final semesterKey = _getSemesterKey(grade, department, year, semester);
  final folderId = semesterRootFolders[semesterKey];

  // If no folder ID is available, return empty map
  if (folderId == null || folderId.isEmpty) {
    return <String, String>{};
  }

  // Use dynamic folder provider to discover subjects
  final provider = DynamicFolderProvider();
  return await provider.discoverSemesterSubjects(semesterKey);
}

// --- Grade Selection UI ---
// GradeSelectionScreen - NO LONGER HAS ITS OWN SCAFFOLD OR APPBAR
class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key});

  /// Show enhanced authentication dialog with doctor and leader options
  void _showEnhancedAuthenticationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.authenticationRequired,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                 AppLocalizations.of(context)!.chooserole,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Sign in as Doctor button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      final leaderProvider = Provider.of<LeaderModeProvider>(
                          context,
                          listen: false);
                      await leaderProvider.authenticateLeader(context,
                          isDoctorMode: true);
                    },
                    icon: const Icon(Icons.school),
                    label: Text(AppLocalizations.of(context)!.signInAsDoctor),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Sign in as Leader button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      final leaderProvider = Provider.of<LeaderModeProvider>(
                          context,
                          listen: false);
                      await leaderProvider.authenticateLeader(context,
                          isDoctorMode: false);
                    },
                    icon: const Icon(Icons.school),
                    label: Text(AppLocalizations.of(context)!.signInAsLeader),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show material upload bottom sheet
  void _showMaterialUploadBottomSheet(BuildContext context) {
    MaterialUploadHelper.showMaterialUploadBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final grades = [
      (s.firstGrade, Icons.looks_one),
      (s.secondGrade, Icons.looks_two),
      (s.thirdGrade, Icons.looks_3),
      (s.fourthGrade, Icons.looks_4),
    ];

    return Column(
      children: [
        AppBar(
          title: Text(s.appTitle),
          automaticallyImplyLeading: false,
          actions: [
            // Leader Mode Button
            Consumer<LeaderModeProvider>(
              builder: (context, leaderProvider, child) {
                if (leaderProvider.isLeaderMode) {
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.admin_panel_settings,
                        color: Colors.green),
                    tooltip: s.leaderModeActive,
                    onSelected: (value) async {
                      if (value == 'signout') {
                        await leaderProvider.signOutLeader(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.red),
                            const SizedBox(width: 8),
                            Text (s.signOut,
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    tooltip: AppLocalizations.of(context)!.leaderMode,
                    onPressed: leaderProvider.isAuthenticating
                        ? null
                        : () => _showEnhancedAuthenticationDialog(context),
                  );
                }
              },
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(
              children: [
                StaggeredListView(
                  children: grades.map((grade) {
                    return AnimatedCard(
                      child: AnimatedButton(
                        onPressed: () => Future.microtask(() =>
                            Navigator.of(context).pushNamed('/departments',
                                arguments: AcademicContext(grade: grade.$1))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Icon(grade.$2, size: 32),
                            title: Text(
                              grade.$1,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

// DepartmentSelectionScreen
class DepartmentSelectionScreen extends StatelessWidget {
  final AcademicContext academicContext;
  const DepartmentSelectionScreen({super.key, required this.academicContext});
  List<String> _getDepartmentStrings(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return [s.communication, s.electronics, s.mechatronics];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final List<String> departmentOptions = _getDepartmentStrings(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: departmentOptions.isEmpty
          ? Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    s.notAvailableNow,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: departmentOptions.length,
              itemBuilder: (context, index) {
                final String localizedDepartment = departmentOptions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Text(localizedDepartment,
                        style: theme.textTheme.titleMedium),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => Navigator.of(context).pushNamed('/years',
                        arguments: academicContext.copyWith(
                            department: localizedDepartment)),
                  ),
                );
              },
            ),
    );
  }
}

// YearSelectionScreen
class YearSelectionScreen extends StatelessWidget {
  final AcademicContext academicContext;
  const YearSelectionScreen({super.key, required this.academicContext});
  List<String> _getYearStrings(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return [s.currentYear, s.lastYear];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final List<String> yearOptions = _getYearStrings(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: yearOptions.isEmpty
          ? Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    s.notAvailableNow,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: yearOptions.length,
              itemBuilder: (context, index) {
                final String localizedYear = yearOptions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title:
                        Text(localizedYear, style: theme.textTheme.titleMedium),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () => Navigator.of(context).pushNamed('/semesters',
                        arguments:
                            academicContext.copyWith(year: localizedYear)),
                  ),
                );
              },
            ),
    );
  }
}

// SemesterSelectionScreen
class SemesterSelectionScreen extends StatefulWidget {
  final AcademicContext academicContext;
  const SemesterSelectionScreen({super.key, required this.academicContext});

  @override
  State<SemesterSelectionScreen> createState() =>
      _SemesterSelectionScreenState();
}

class _SemesterSelectionScreenState extends State<SemesterSelectionScreen> {
  Map<String, String> semester1Subjects = {};
  Map<String, String> semester2Subjects = {};
  bool isLoading = true;

  /// Show material upload bottom sheet - enabled for semester level uploads
  void _showMaterialUploadBottomSheet(BuildContext context) {
    // Show dialog to choose which semester to upload to
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.upload_file, color: Colors.blue),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.uploadToSemester),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.chooseSemesterToUpload),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _uploadToSemester(context, 'Semester 1');
            },
            child: Text(AppLocalizations.of(context)!.semester1),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _uploadToSemester(context, 'Semester 2');
            },
            child: Text(AppLocalizations.of(context)!.semester2),
          ),
        ],
      ),
    );
  }

  /// Upload materials to specific semester folder
  void _uploadToSemester(BuildContext context, String semester) {
    final grade = widget.academicContext.grade;
    final department = widget.academicContext.department;
    final year = widget.academicContext.year;
    
    if (grade == null || department == null || year == null) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.incompleteAcademicContext,
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    
    final semesterKey = _getSemesterKey(grade, department, year, semester);
    final semesterFolderId = semesterRootFolders[semesterKey];
    
    if (semesterFolderId == null || semesterFolderId.isEmpty) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.semesterFolderNotAvailable,
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    
    // Use the MaterialUploadHelper with explicit context
    MaterialUploadHelper.showMaterialUploadBottomSheetWithContext(
      context,
      semesterFolderId,
      widget.academicContext,
    );
  }

  Future<Map<String, String>> _getSubjectsForContext(
      BuildContext context, AcademicContext contextToLookup) async {
    final String? canonicalGrade = contextToLookup.grade;
    final String? canonicalDepartment = contextToLookup.department;
    final String? canonicalYear = contextToLookup.year;
    final String? canonicalSemester = contextToLookup.semester;

    if (canonicalGrade == null ||
        canonicalGrade.isEmpty ||
        canonicalDepartment == null ||
        canonicalDepartment.isEmpty ||
        canonicalYear == null ||
        canonicalYear.isEmpty ||
        canonicalSemester == null ||
        canonicalSemester.isEmpty) {
      developer.log(
          'Incomplete Canonical AcademicContext for subject lookup: $contextToLookup',
          name: 'SemesterSelectionScreen');
      return {};
    }

    // Use dynamic folder discovery
    return await getSubjectsForSemester(
        canonicalGrade, canonicalDepartment, canonicalYear, canonicalSemester);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isLoading) {
      _loadSubjects();
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final context1 = widget.academicContext.copyWith(semester: 'Semester 1');
      final context2 = widget.academicContext.copyWith(semester: 'Semester 2');
      
      final results = await Future.wait([
        _getSubjectsForContext(context, context1),
        _getSubjectsForContext(context, context2),
      ]);

      setState(() {
        semester1Subjects = results[0];
        semester2Subjects = results[1];
        isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading subjects: $e',
          name: 'SemesterSelectionScreen');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshSubjects() async {
    setState(() {
      isLoading = true;
    });

    // Clear the dynamic folder cache to force refetch
    final dynamicFolderProvider =
        Provider.of<DynamicFolderProvider>(context, listen: false);
    await dynamicFolderProvider.clearCache();

    // Reload subjects
    await _loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final bool hasSem1 = semester1Subjects.isNotEmpty;
    final bool hasSem2 = semester2Subjects.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.academicContext.titleString,
            softWrap: true, maxLines: 2),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshSubjects,
            tooltip: 'Refresh folders',
          ),
        ],
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      // No floating action button for semester selection screen
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : (!hasSem1 && !hasSem2)
              ? Center(
                  child: Card(
                    margin: const EdgeInsets.all(32),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        s.notAvailableNow,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    if (hasSem1)
                      Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: ListTile(
                          title: Text(s.semester1,
                              style: theme.textTheme.titleMedium),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/subjects',
                              arguments: {
                                'subjects': semester1Subjects,
                                'context': widget.academicContext
                                    .copyWith(semester: 'Semester 1'),
                              },
                            );
                          },
                        ),
                      ),
                    if (hasSem2)
                      Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: ListTile(
                          title: Text(s.semester2,
                              style: theme.textTheme.titleMedium),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/subjects',
                              arguments: {
                                'subjects': semester2Subjects,
                                'context': widget.academicContext
                                    .copyWith(semester: 'Semester 2'),
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
    );
  }
}

// SubjectSelectionScreen
class SubjectSelectionScreen extends StatefulWidget {
  final Map<String, String> subjects;
  final AcademicContext academicContext;
  const SubjectSelectionScreen(
      {super.key, required this.subjects, required this.academicContext});

  @override
  State<SubjectSelectionScreen> createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  Map<String, String> _subjects = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _subjects = Map.from(widget.subjects);
  }

  /// Refresh subjects list from parent provider
  Future<void> _refreshSubjects() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Trigger refresh in parent by popping and letting parent rebuild
      // For now, we'll just reload from widget.subjects
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for UX
      
      if (mounted) {
        setState(() {
          _subjects = Map.from(widget.subjects);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show material upload bottom sheet - enabled for semester level uploads
  void _showMaterialUploadBottomSheet(BuildContext context) {
    final grade = widget.academicContext.grade;
    final department = widget.academicContext.department;
    final year = widget.academicContext.year;
    final semester = widget.academicContext.semester;
    
    if (grade == null || department == null || year == null || semester == null) {
      showAppSnackBar(
        context,
        'Incomplete academic context for upload',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    
    final semesterKey = _getSemesterKey(grade, department, year, semester);
    final semesterFolderId = semesterRootFolders[semesterKey];
    
    if (semesterFolderId == null || semesterFolderId.isEmpty) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.semesterFolderNotAvailable,
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    
    // Use the MaterialUploadHelper with explicit context
    MaterialUploadHelper.showMaterialUploadBottomSheetWithContext(
      context,
      semesterFolderId,
      widget.academicContext,
    );
  }

  /// Handle leader mode actions for subject folders (rename/delete)
  void _handleSubjectLeaderAction(String action, String subjectName, String folderId) {
    if (action == 'rename') {
      _showSubjectRenameDialog(subjectName, folderId);
    } else if (action == 'delete') {
      _showSubjectDeleteConfirmation(subjectName, folderId);
    }
  }

  /// Show rename dialog for subject folder
  void _showSubjectRenameDialog(String currentName, String folderId) {
    final TextEditingController controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Icon(Icons.folder, color: Colors.blue, size: 28),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.renameSubject, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && value.trim() != currentName) {
                  Navigator.pop(context);
                  _performSubjectRename(folderId, value.trim());
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty && newName != currentName) {
                      Navigator.pop(context);
                      _performSubjectRename(folderId, newName);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.rename, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog for subject folder
  void _showSubjectDeleteConfirmation(String subjectName, String folderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.deleteSubject, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Are you sure you want to delete the subject "$subjectName"?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            const Text(
              'This will delete the entire subject folder and all its contents. This action cannot be undone.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performSubjectDelete(folderId, subjectName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Perform rename operation for subject folder
  Future<void> _performSubjectRename(String folderId, String newName) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    // Normalize academic context values to English for permission checks
    final normalizedGrade = _normalizeGrade(widget.academicContext.grade ?? 'Unknown');
    final normalizedDepartment = _normalizeDepartment(widget.academicContext.department ?? 'Unknown');
    final normalizedYear = _normalizeYear(widget.academicContext.year ?? 'Unknown');
    
    final success = await leaderProvider.renameFileOrFolder(
      fileId: folderId,
      newName: newName,
      grade: normalizedGrade,
      department: normalizedDepartment,
      year: normalizedYear,
      context: context,
    );

    if (success) {
      // Refresh the subjects list to show updated name
      await _refreshSubjects();
    }
  }

  /// Perform delete operation for subject folder
  Future<void> _performSubjectDelete(String folderId, String subjectName) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    // Normalize academic context values to English for permission checks
    final normalizedGrade = _normalizeGrade(widget.academicContext.grade ?? 'Unknown');
    final normalizedDepartment = _normalizeDepartment(widget.academicContext.department ?? 'Unknown');
    final normalizedYear = _normalizeYear(widget.academicContext.year ?? 'Unknown');
    
    final success = await leaderProvider.deleteFileOrFolder(
      fileId: folderId,
      fileName: subjectName,
      grade: normalizedGrade,
      department: normalizedDepartment,
      year: normalizedYear,
      context: context,
    );

    if (success) {
      // Refresh the subjects list to show updated name
      await _refreshSubjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> subjectsList =
        _subjects.entries.toList();
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.academicContext.titleString, softWrap: true, maxLines: 3),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      floatingActionButton: Consumer<LeaderModeProvider>(
        builder: (context, leaderProvider, child) {
          if (leaderProvider.isLeaderMode) {
            return FloatingActionButton(
              onPressed: () => _showMaterialUploadBottomSheet(context),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: subjectsList.isEmpty
          ? Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    s.notAvailableNow,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: subjectsList.length,
              itemBuilder: (context, index) {
                final entry = subjectsList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Text(entry.key, style: theme.textTheme.titleMedium),
                    trailing: Consumer<LeaderModeProvider>(
                      builder: (context, leaderProvider, child) {
                        if (leaderProvider.isLeaderMode) {
                          return PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) => _handleSubjectLeaderAction(value, entry.key, entry.value),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'rename',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.renameSubject),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(AppLocalizations.of(context)!.deleteSubject, style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return const Icon(Icons.arrow_forward_ios, size: 18);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectContentScreen(
                            subjectName: entry.key,
                            rootFolderId: entry.value,
                            academicContext: widget.academicContext,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// SubjectContentScreen
class SubjectContentScreen extends StatelessWidget {
  final String subjectName;
  final String rootFolderId;
  final AcademicContext academicContext;
  const SubjectContentScreen(
      {super.key,
      required this.subjectName,
      required this.rootFolderId,
      required this.academicContext});

  /// Show material upload bottom sheet
  void _showMaterialUploadBottomSheet(BuildContext context) {
    MaterialUploadHelper.showMaterialUploadBottomSheetWithContext(
      context,
      rootFolderId,
      academicContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Consumer<LeaderModeProvider>(
        builder: (context, leaderProvider, child) {
          if (leaderProvider.isLeaderMode) {
            return FloatingActionButton(
              onPressed: () => _showMaterialUploadBottomSheet(context),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: LectureFolderBrowserScreen(
        initialFolderId: rootFolderId,
        academicContext: academicContext,
        subjectName: subjectName,
      ),
    );
  }
}

// PDF Viewer Screen
class PdfViewerScreen extends StatefulWidget {
  final String? fileUrl;
  final String fileId;
  final String? fileName;
  final String? localPath; // new: open a local PDF directly

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileId,
    this.fileName,
    this.localPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoadingFromServer = false;
  bool _isCheckingCache = true;
  double _downloadProgress = 0.0;
  String? _localFilePath;
  String? _loadingError;
  CancelToken _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    developer.log(
        "PdfViewerScreen initState: fileId='${widget.fileId}', fileUrl='${widget.fileUrl}'",
        name: 'PdfViewerScreen');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndLoadPdf();
      }
    });
  }

  @override
  void dispose() {
    developer.log(
        "PdfViewerScreen dispose: Cancelling download if active for ${widget.fileId}",
        name: 'PdfViewerScreen');
    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel("PDF viewer disposed for ${widget.fileId}");
    }
    super.dispose();
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String fileId) async {
    final path = await _localPath;
    final filename = 'pdf_cache_$fileId.pdf';
    return File('$path/$filename');
  }

  Future<void> _checkAndLoadPdf() async {
    if (!mounted) {
      developer.log("_checkAndLoadPdf (${widget.fileId}): Unmounted, exiting.",
          name: 'PdfViewerScreen');
      return;
    }
    _cancelToken = CancelToken();
    developer.log("_checkAndLoadPdf (${widget.fileId}): Starting.",
        name: 'PdfViewerScreen');

    if (!_isLoadingFromServer && mounted) {
      setState(() {
        _isCheckingCache = true;
        _loadingError = null;
        _localFilePath = null;
      });
    }

    final s = AppLocalizations.of(context);
    if (s == null) {
      developer.log(
          "_checkAndLoadPdf (${widget.fileId}): Localizations not available yet.",
          name: 'PdfViewerScreen');
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _loadingError = "Error: Localizations not ready.";
          _isCheckingCache = false;
        });
      }
      return;
    }

    // If a localPath is provided, display it directly without needing url/id
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _localFilePath = widget.localPath;
          _isCheckingCache = false;
          _isLoadingFromServer = false;
          _loadingError = null;
        });
      }
      return;
    }

    if (widget.fileUrl == null ||
        widget.fileUrl!.isEmpty ||
        widget.fileId.isEmpty) {
      developer.log(
          "_checkAndLoadPdf (${widget.fileId}): Missing fileUrl or fileId.",
          name: 'PdfViewerScreen');
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _loadingError = s.errorNoUrlProvided;
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
      return;
    }

    final localFile = await _getLocalFile(widget.fileId);

    try {
      if (await localFile.exists()) {
        developer.log(
            "_checkAndLoadPdf (${widget.fileId}): File found in cache at ${localFile.path}",
            name: 'PdfViewerScreen');
        if (mounted) {
          // Ensure mounted before setState
          setState(() {
            _localFilePath = localFile.path;
            _isCheckingCache = false;
            _isLoadingFromServer = false;
            _loadingError = null;
          });
          // Add to recent files
          if (mounted) {
            // Ensure mounted before Provider.of
            Provider.of<RecentFilesProvider>(context, listen: false)
                .addRecentFile(
              RecentFile(
                id: widget.fileId,
                name: widget.fileName ?? 'PDF Document',
                url: widget.fileUrl,
                mimeType: 'application/pdf',
                accessTime: DateTime.now(),
              ),
            );
          }
        }
      } else {
        developer.log(
            "_checkAndLoadPdf (${widget.fileId}): File not in cache. Preparing to download.",
            name: 'PdfViewerScreen');
        if (mounted) {
          // Ensure mounted before setState
          setState(() {
            _isCheckingCache = false;
            _isLoadingFromServer = true;
            _downloadProgress = 0.0;
            _loadingError = null;
          });
        }
        await _downloadPdf(localFile, s);
      }
    } catch (e) {
      developer.log(
          "_checkAndLoadPdf (${widget.fileId}): Error during cache check or initiating download: $e",
          name: 'PdfViewerScreen');
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _loadingError = s.failedToLoadPdf(e.toString());
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
    }
  }

  Future<void> _downloadPdf(File localFile, AppLocalizations s) async {
    if (!mounted) {
      developer.log("_downloadPdf (${widget.fileId}): Unmounted, exiting.",
          name: 'PdfViewerScreen');
      return;
    }
    developer.log(
        "_downloadPdf (${widget.fileId}): Starting Dio download from ${widget.fileUrl} to ${localFile.path}",
        name: 'PdfViewerScreen');
    final dio = Dio();
    try {
      await dio.download(
        widget.fileUrl!,
        localFile.path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            // Ensure mounted before setState
            final progress = received / total;
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );
      developer.log("_downloadPdf (${widget.fileId}): Download complete.",
          name: 'PdfViewerScreen');
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _localFilePath = localFile.path;
          _isLoadingFromServer = false;
          _loadingError = null;
        });
        // Add to recent files after successful download
        if (mounted) {
          // Ensure mounted before Provider.of
          Provider.of<RecentFilesProvider>(context, listen: false)
              .addRecentFile(
            RecentFile(
              id: widget.fileId,
              name: widget.fileName ?? 'PDF Document',
              url: widget.fileUrl,
              mimeType: 'application/pdf',
              accessTime: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        developer.log(
            '_downloadPdf (${widget.fileId}): Download cancelled: ${e.message}',
            name: 'PdfViewerScreen');
        if (mounted) {
          // Ensure mounted before setState
          setState(() {
            _isLoadingFromServer = false;
            if (_loadingError == null && _localFilePath == null) {
              _loadingError = s.errorDownloadCancelled;
            }
          });
        }
      } else {
        developer.log('_downloadPdf (${widget.fileId}): Download error: $e',
            name: 'PdfViewerScreen');
        if (mounted) {
          // Ensure mounted
          final partialFile =
              File(localFile.path); // Use localFile.path directly
          if (await partialFile.exists()) {
            try {
              await partialFile.delete();
              developer.log("Error deleting partial file: $e",
                  name: 'PdfViewerScreen');
            } catch (delErr) {
              developer.log(
                  "Error deleting partial file during exception handling: $delErr",
                  name: 'PdfViewerScreen');
            }
          }
          setState(() {
            _loadingError = s.failedToLoadPdf(e.toString());
            _isLoadingFromServer = false;
          });
        }
      }
    }
  }

  Future<void> _deleteAndRetry() async {
    if (!mounted) {
      developer.log("_deleteAndRetry (${widget.fileId}): Unmounted.",
          name: 'PdfViewerScreen');
      return;
    }
    developer.log("_deleteAndRetry (${widget.fileId}): Initiated.",
        name: 'PdfViewerScreen');

    if (!_cancelToken.isCancelled) {
      _cancelToken.cancel("Retrying download for ${widget.fileId}");
    }

    final s = AppLocalizations.of(context);
    if (s == null) {
      developer.log(
          "_deleteAndRetry (${widget.fileId}): Localizations null, cannot proceed.",
          name: 'PdfViewerScreen');
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _loadingError = "Localization error during retry.";
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
      return;
    }

    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      // For localPath sessions, just re-render; nothing to delete from cache
      if (mounted) {
        setState(() {
          _isCheckingCache = false;
          _loadingError = null;
        });
      }
      return;
    } else if (widget.fileId.isNotEmpty) {
      final localFile = await _getLocalFile(widget.fileId);
      if (await localFile.exists()) {
        try {
          await localFile.delete();
          developer.log("Deleted cached PDF: ${localFile.path}",
              name: "PdfViewerScreen");
        } catch (e) {
          developer.log("Error deleting cached PDF: $e",
              name: 'PdfViewerScreen');
        }
      }
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _isCheckingCache = true;
          _localFilePath = null;
          _loadingError = null;
          _isLoadingFromServer = false;
          _downloadProgress = 0.0;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _checkAndLoadPdf();
          }
        });
      }
    } else {
      developer.log(
          "_deleteAndRetry (${widget.fileId}): fileId is empty, cannot retry.",
          name: 'PdfViewerScreen');
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _loadingError = s.errorFileIdMissing;
          _isCheckingCache = false;
          _isLoadingFromServer = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final String appBarTitle =
        widget.fileName ?? s?.lectureContent ?? "PDF Viewer";

    if (s == null && _isCheckingCache) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: Center(
            child: Text(AppLocalizations.of(context)?.loadingLocalizations ??
                "Loading localizations...")),
      );
    }

    if (_isCheckingCache) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadingError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(_loadingError!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (s != null &&
                    _loadingError != s.errorNoUrlProvided &&
                    _loadingError != s.errorDownloadCancelled)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    onPressed: _deleteAndRetry,
                    label: Text(s.retry),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingFromServer) {
      final String downloadingText = s?.downloading ?? "Downloading";
      final String statusText = _downloadProgress > 0.001
          ? "$downloadingText (${(_downloadProgress * 100).toStringAsFixed(0)}%)"
          : "$downloadingText...";

      return Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                    value:
                        _downloadProgress > 0.001 ? _downloadProgress : null),
                const SizedBox(height: 20),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_localFilePath != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
        ),
        body: SfPdfViewer.file(
          File(_localFilePath!),
          key: _pdfViewerKey,
          onDocumentLoadFailed: (details) {
            developer.log(
                'Local PDF load failed for $_localFilePath (${widget.fileId}): ${details.description}',
                name: 'PdfViewerScreen');
            if (mounted && s != null) {
              // Ensure mounted
              _deleteAndRetry();
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Center(child: Text(s?.notAvailableNow ?? "Content not available.")),
    );
  }
}

// Simple local image viewer (in-app) for offline/local images
class LocalImageViewerScreen extends StatelessWidget {
  final String imagePath;
  final String? title;
  const LocalImageViewerScreen(
      {super.key, required this.imagePath, this.title});

  @override
  Widget build(BuildContext context) {
    final t = title ?? AppLocalizations.of(context)?.lectureContent ?? 'Image';
    return Scaffold(
      appBar: AppBar(title: Text(t)),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)
                        ?.errorLoadingContent(err.toString()) ??
                    'Failed to load image: $err',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Video Player Screen for MP4/video files
class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String? title;
  final bool isLocalFile;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    this.title,
    this.isLocalFile = true,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.isLocalFile) {
        _videoController = VideoPlayerController.file(File(widget.videoPath));
      } else {
        _videoController =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      }

      await _videoController.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: false,
          looping: false,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Theme.of(context).primaryColor,
            handleColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.lightGreen,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final title = widget.title ?? s?.lectureContent ?? 'Video Player';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      s?.errorLoadingContent(_error!) ??
                          'Error loading video: $_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _chewieController != null
                  ? Chewie(controller: _chewieController!)
                  : Center(child: Text(AppLocalizations.of(context)!.videoPlayerNotAvailable)),
    );
  }
}

// Audio Player Screen for MP3/audio files
class AudioPlayerScreen extends StatefulWidget {
  final String audioPath;
  final String? title;
  final bool isLocalFile;

  const AudioPlayerScreen({
    super.key,
    required this.audioPath,
    this.title,
    this.isLocalFile = true,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isLoading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.isLocalFile) {
        await _audioPlayer.setFilePath(widget.audioPath);
      } else {
        await _audioPlayer.setUrl(widget.audioPath);
      }

      _audioPlayer.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() {
            _duration = duration;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final title = widget.title ?? s?.lectureContent ?? 'Audio Player';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      s?.errorLoadingContent(_error!) ??
                          'Error loading audio: $_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Audio icon
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Icon(
                            Icons.music_note,
                            size: 100,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // File name
                        Text(
                          widget.title ?? widget.audioPath.split('/').last,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Progress slider
                        Slider(
                          value: _position.inSeconds.toDouble(),
                          max: _duration.inSeconds.toDouble(),
                          onChanged: (value) {
                            _audioPlayer.seek(Duration(seconds: value.toInt()));
                          },
                        ),

                        // Time display
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position)),
                              Text(_formatDuration(_duration)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Play controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                final newPosition =
                                    _position - const Duration(seconds: 10);
                                _audioPlayer.seek(newPosition < Duration.zero
                                    ? Duration.zero
                                    : newPosition);
                              },
                              icon: const Icon(Icons.replay_10),
                              iconSize: 32,
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                if (_isPlaying) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.play();
                                }
                              },
                              icon: Icon(_isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle),
                              iconSize: 64,
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                final newPosition =
                                    _position + const Duration(seconds: 10);
                                _audioPlayer.seek(newPosition > _duration
                                    ? _duration
                                    : newPosition);
                              },
                              icon: const Icon(Icons.forward_10),
                              iconSize: 32,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// Office Document Viewer Screen for Word/Excel/PowerPoint files
class OfficeDocumentViewerScreen extends StatefulWidget {
  final String documentPath;
  final String? title;
  final bool isLocalFile;

  const OfficeDocumentViewerScreen({
    super.key,
    required this.documentPath,
    this.title,
    this.isLocalFile = true,
  });

  @override
  State<OfficeDocumentViewerScreen> createState() =>
      _OfficeDocumentViewerScreenState();
}

class _OfficeDocumentViewerScreenState
    extends State<OfficeDocumentViewerScreen> {
  bool _isLoading = true;
  String? _error;
  Uint8List? _documentData;

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
  }

  Future<void> _loadDocumentData() async {
    try {
      Uint8List data;
      if (widget.isLocalFile) {
        final file = File(widget.documentPath);
        data = await file.readAsBytes();
      } else {
        final response = await http.get(Uri.parse(widget.documentPath));
        if (response.statusCode == 200) {
          data = response.bodyBytes;
        } else {
          throw Exception('Failed to load document: ${response.statusCode}');
        }
      }

      if (mounted) {
        setState(() {
          _documentData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final title = widget.title ?? s?.lectureContent ?? 'Document Viewer';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          s?.errorLoadingContent(_error!) ??
                              'Error loading document: $_error',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Fallback to external app
                            OpenFilex.open(widget.documentPath);
                          },
                          child: Text(AppLocalizations.of(context)!.openWithExternalApp),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildDocumentViewer(),
    );
  }

  IconData _getOfficeIcon(String extension) {
    switch (extension) {
      case 'docx':
        return Icons.description; // Word document
      case 'xlsx':
        return Icons.table_chart; // Excel spreadsheet
      case 'pptx':
        return Icons.slideshow; // PowerPoint presentation
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildDocumentViewer() {
    try {
      // Extract extension from title or path more reliably
      String fileName =
          widget.title ?? widget.documentPath.split('/').last.split('\\').last;
      final String extension = fileName.toLowerCase().contains('.')
          ? fileName.toLowerCase().split('.').last
          : '';

      switch (extension) {
        case 'docx':
        case 'xlsx':
        case 'pptx':
          return Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Header with document info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getOfficeIcon(extension),
                        size: 32,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title ??
                                  widget.documentPath.split('/').last,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '.${extension.toUpperCase()} Document',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (widget.isLocalFile) {
                            OpenFilex.open(widget.documentPath);
                          } else {
                            // For network files, we need to download first or show message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please download the file first to open with external app'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new),
                        tooltip: 'Open with external app',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Microsoft Viewer
                Expanded(
                  child: _documentData != null
                      ? Container(
                          width: double.infinity,
                          height: double.infinity,
                          child: MicrosoftViewer(_documentData!, true),
                        )
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),
              ],
            ),
          );
        default:
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unsupported document format: .$extension',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    if (widget.isLocalFile) {
                      OpenFilex.open(widget.documentPath);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Please download the file first to open with external app'),
                        ),
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.openWithExternalApp),
                ),
              ],
            ),
          );
      }
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error displaying document: $e',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (widget.isLocalFile) {
                  OpenFilex.open(widget.documentPath);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please download the file first to open with external app'),
                    ),
                  );
                }
              },
              child: Text(AppLocalizations.of(context)?.openWithExternalApp ??
                  'Open with external app'),
            ),
          ],
        ),
      );
    }
  }
}

// Google Drive Viewer Screen (Unchanged from previous provided code)
class GoogleDriveViewerScreen extends StatefulWidget {
  final String? embedUrl;
  final String? fileId; // Added for recent files
  final String? fileName; // Added for recent files
  final String? mimeType; // Added for recent files

  const GoogleDriveViewerScreen({
    super.key,
    this.embedUrl,
    this.fileId,
    this.fileName,
    this.mimeType,
  });
  @override
  State<GoogleDriveViewerScreen> createState() =>
      _GoogleDriveViewerScreenState();
}

class _GoogleDriveViewerScreenState extends State<GoogleDriveViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{});
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (mounted) {
              // Ensure mounted before setState
              setState(() => _isLoading = false);
              // Add to recent files after page finishes loading
              if (widget.fileId != null && widget.fileName != null) {
                if (mounted) {
                  // Ensure mounted before Provider.of
                  Provider.of<RecentFilesProvider>(context, listen: false)
                      .addRecentFile(
                    RecentFile(
                      id: widget.fileId!,
                      name: widget.fileName!,
                      url: widget.embedUrl,
                      mimeType: widget.mimeType ??
                          'application/octet-stream', // Default if not provided
                      accessTime: DateTime.now(),
                    ),
                  );
                }
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            developer.log(
                'Page resource error in WebView: URL: ${error.url}, code: ${error.errorCode}, description: ${error.description}',
                name: 'GoogleDriveViewer');
            if (mounted) {
              // Ensure mounted
              final s = AppLocalizations.of(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(s?.errorLoadingContent(error.description) ??
                      "Error loading content: ${error.description}")));
            }
          },
          onNavigationRequest: (NavigationRequest request) =>
              NavigationDecision.navigate,
        ),
      );
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setTextZoom(100);
    }
    _controller = controller;
    if (widget.embedUrl != null && widget.embedUrl!.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.embedUrl!));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure mounted
          final s = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(s?.errorNoUrlProvided ?? "Error: No URL provided")));
          setState(() => _isLoading = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final String appBarTitle =
        widget.fileName ?? s?.lectureContent ?? "Content Viewer";
    return Scaffold(
      appBar: AppBar(
          title: Text(appBarTitle),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context))),
      body: Stack(
        children: [
          if (widget.embedUrl != null && widget.embedUrl!.isNotEmpty)
            WebViewWidget(controller: _controller)
          else if (!_isLoading && s != null)
            Center(child: Text(s.errorNoUrlProvided)),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

// Lecture Folder Browser Screen (MODIFIED FOR SELECTION, DOWNLOAD, DETAILS)
class LectureFolderBrowserScreen extends StatefulWidget {
  final String? initialFolderId;
  final AcademicContext? academicContext;
  final String? subjectName;

  const LectureFolderBrowserScreen({super.key, this.initialFolderId, this.academicContext, this.subjectName});
  
  // Method to get current folder ID from anywhere in the widget tree
  static String? getCurrentFolderId(BuildContext context) {
    // Find the LectureFolderBrowserScreen widget and get its current state
    String? currentFolderId;
    context.visitAncestorElements((element) {
      if (element.widget is LectureFolderBrowserScreen) {
        final browserWidget = element.widget as LectureFolderBrowserScreen;
        if (element is StatefulElement && element.state is _LectureFolderBrowserScreenState) {
          final state = element.state as _LectureFolderBrowserScreenState;
          currentFolderId = state._currentFolderId ?? browserWidget.initialFolderId;
        } else {
          currentFolderId = browserWidget.initialFolderId;
        }
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    
    return currentFolderId;
  }

  @override
  State<LectureFolderBrowserScreen> createState() =>
      _LectureFolderBrowserScreenState();
}

class _LectureFolderBrowserScreenState
    extends State<LectureFolderBrowserScreen> {
  List<drive.File>? _files;
  bool _isLoading = true;
  String? _error;
  String? _currentFolderId;
  AppLocalizations? s;

  // --- Search and Sort State ---
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.nameAsc;

  bool _isSelectionMode = false;
  final Set<drive.File> _selectedFiles =
      <drive.File>{}; // Store full File objects for details

  Map<String, double> _downloadProgressMap =
      {}; // fileId -> progress (0.0 to 1.0)
  Map<String, CancelToken> _cancelTokens = {}; // fileId -> CancelToken
  bool _isDownloadingMultiple = false;

  // --- Pagination & Caching (global across instances) ---
  // Cache folder listings to improve perceived performance and enable basic offline reuse.
  static final Map<String, List<drive.File>> _globalFolderCache = {};
  // Track nextPageToken per folder; null means no further pages.
  static final Map<String, String?> _globalNextPageToken = {};
  // Local flag for load-more state
  bool _isLoadingMore = false;

  // --- Offline support ---
  // In-memory index of filenames downloaded per Drive folderId (lives for app session only)
  static final Map<String, Set<String>> _globalFolderDownloadedNames = {};
  bool _offlineMode = false;
  static const String _prefsKeyDownloadedIndex =
      'lecture_folder_downloaded_names_v1';

  // --- Search and Sort Logic ---
  List<drive.File> _filteredAndSortedFiles() {
    if (_files == null) return [];
    List<drive.File> filtered = _files!;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where((f) => (f.name ?? '').toLowerCase().contains(q))
          .toList();
    }
    filtered.sort((a, b) {
      switch (_sortMode) {
        case _SortMode.nameAsc:
          return (a.name ?? '')
              .toLowerCase()
              .compareTo((b.name ?? '').toLowerCase());
        case _SortMode.nameDesc:
          return (b.name ?? '')
              .toLowerCase()
              .compareTo((a.name ?? '').toLowerCase());
        case _SortMode.dateAsc:
          return (a.modifiedTime ?? DateTime(1970))
              .compareTo(b.modifiedTime ?? DateTime(1970));
        case _SortMode.dateDesc:
          return (b.modifiedTime ?? DateTime(1970))
              .compareTo(a.modifiedTime ?? DateTime(1970));
        case _SortMode.type:
          return (a.mimeType ?? '').compareTo(b.mimeType ?? '');
      }
    });
    return filtered;
  }

  // Build a minimal list of file entries from local downloads for current folder
  Future<List<drive.File>> _buildLocalFilesForCurrentFolder() async {
    final results = <drive.File>[];
    final folderId = _currentFolderId;
    if (folderId == null || !mounted) return results;

    try {
      final downloadPathProvider =
          Provider.of<DownloadPathProvider>(context, listen: false);
      final String dirPath =
          await downloadPathProvider.getEffectiveDownloadPath();
      final dir = Directory(dirPath);
      if (!await dir.exists() || !mounted) return results;

      final names = _globalFolderDownloadedNames[folderId] ?? <String>{};
      if (names.isEmpty) return results;

      final children = await dir.list(followLinks: false).toList();
      final Set<String> existingNames = children
          .whereType<File>()
          .map((f) => f.path.split(Platform.pathSeparator).last)
          .toSet();
      for (final name in names) {
        if (existingNames.contains(name)) {
          // Use synthetic local IDs to keep UI logic consistent
          results.add(drive.File()
            ..name = name
            ..mimeType = _inferMimeTypeFromName(name)
            ..id = 'local:' + name
            ..webViewLink = null
            ..webContentLink = null);
        }
      }
    } catch (e) {
      developer.log('Error building local files list or accessing provider: $e',
          name: 'LectureFolderBrowser');
    }
    return results;
  }

  String _inferMimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi')) return 'video/mp4';
    if (lower.endsWith('.mkv') || lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.m4a') || lower.endsWith('.aac')) return 'audio/aac';
    if (lower.endsWith('.ogg') || lower.endsWith('.flac')) return 'audio/ogg';
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx'))
      return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx'))
      return 'application/vnd.ms-excel';
    if (lower.endsWith('.doc') || lower.endsWith('.docx'))
      return 'application/msword';
    if (lower.endsWith('.txt')) return 'text/plain';
    if (lower.endsWith('.rtf')) return 'application/rtf';
    return 'application/octet-stream';
  }

  Future<void> _loadDownloadedNamesForFolder(String folderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = prefs.getStringList(_prefsKeyDownloadedIndex + ':keys') ?? [];
      if (!map.contains(folderId)) return;
      final values =
          prefs.getStringList('$_prefsKeyDownloadedIndex:$folderId') ?? [];
      _globalFolderDownloadedNames[folderId] = values.toSet();
    } catch (e) {
      developer.log('Failed to load downloaded index for $folderId: $e',
          name: 'LectureFolderBrowser');
    }
  }

  Future<void> _persistAddDownloadedName(String folderId, String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keyListKey = _prefsKeyDownloadedIndex + ':keys';
      final keys = prefs.getStringList(keyListKey) ?? [];
      if (!keys.contains(folderId)) {
        keys.add(folderId);
        await prefs.setStringList(keyListKey, keys);
      }
      final entryKey = '$_prefsKeyDownloadedIndex:$folderId';
      final current = prefs.getStringList(entryKey) ?? [];
      if (!current.contains(name)) {
        current.add(name);
        await prefs.setStringList(entryKey, current);
      }
    } catch (e) {
      developer.log('Failed to persist downloaded name: $e',
          name: 'LectureFolderBrowser');
    }
  }

  Future<bool> _hasInternetConnectivity() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) return false;
      // Shallow reachability check
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.initialFolderId;
  }

  @override
  void didUpdateWidget(LectureFolderBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update current folder ID if the widget's initialFolderId changes
    if (oldWidget.initialFolderId != widget.initialFolderId) {
      _currentFolderId = widget.initialFolderId;
    }
  }

  @override
  void dispose() {
    _cancelTokens.forEach((fileId, token) {
      if (!token.isCancelled) {
        token.cancel("Folder browser disposed");
      }
    });
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    s = AppLocalizations.of(context);
    if (s == null) {
      developer.log(
          "Localizations not ready in LectureFolderBrowserScreen.didChangeDependencies",
          name: 'LectureFolderBrowser');
    }

    // Preload persisted downloaded names for this folder (for offline listing)
    if (_currentFolderId != null) {
      _loadDownloadedNamesForFolder(_currentFolderId!);
    }

    // Automatically fetch files when dependencies change, no sign-in required
    if (_files == null && _error == null) {
      // If we have cached content for this folder, show it immediately.
      if (_currentFolderId != null &&
          _globalFolderCache[_currentFolderId!] != null) {
        setState(() {
          _files =
              List<drive.File>.from(_globalFolderCache[_currentFolderId!]!);
          _isLoading = false; // show cached instantly
        });
      }
      // Fetch from Drive (first page or refresh) to update/merge cache.
      _fetchDriveFiles();
    }
  }

  Future<void> _fetchDriveFiles({bool loadMore = false}) async {
    if (!mounted) return;

    if (s == null) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context)?.error ??
              "Localization service not available.";
          _isLoading = false;
        });
      }
      return;
    }

    if (loadMore) {
      // Load additional page
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    } else {
      // Initial load/refresh
      setState(() {
        _isLoading = true;
        _error = null;
        _isSelectionMode = false; // Reset selection on refresh/navigation
        _selectedFiles.clear();
      });
    }

    // If there's no internet connectivity, show local files for this folder
    final bool hasNet = await _hasInternetConnectivity();
    if (!hasNet) {
      final localFiles = await _buildLocalFilesForCurrentFolder();
      if (!mounted) return;
      setState(() {
        _offlineMode = true;
        _files = localFiles;
        _isLoading = false;
        _isLoadingMore = false;
      });
      return;
    }

    // Use API key for public Drive files - no authentication needed
    const String apiKey =
        'AIzaSyA9PZz-Mbpt-LrTrWKsUBaeYdKTlBnb8H0'; 

    if (_currentFolderId == null) {
      if (mounted) {
        setState(() {
          _error = s!.errorMissingFolderId;
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
        });
      }
      return;
    }

    try {
      final String? pageToken =
          loadMore ? _globalNextPageToken[_currentFolderId!] : null;

      // Build API URL for public Drive files
      final String baseUrl = 'https://www.googleapis.com/drive/v3/files';
      final Map<String, String> queryParams = {
        'q': "'$_currentFolderId' in parents and trashed = false",
        'fields':
            'nextPageToken, files(id, name, mimeType, webViewLink, iconLink, size, modifiedTime, webContentLink)',
        'orderBy': 'folder,name',
        'pageSize': '50',
        'key': apiKey,
      };

      if (pageToken != null) {
        queryParams['pageToken'] = pageToken;
      }

      final Uri uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load files: ${response.statusCode} ${response.reasonPhrase}');
      }

      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> filesJson = jsonData['files'] ?? [];
      final String? nextPageToken = jsonData['nextPageToken'];

      // Convert JSON to drive.File objects
      final List<drive.File> newFiles = filesJson.map((fileJson) {
        return drive.File.fromJson(fileJson);
      }).toList();

      if (!mounted) return;

      // Initialize existing lists
      final List<drive.File> existing = loadMore
          ? List<drive.File>.from(_globalFolderCache[_currentFolderId!] ?? [])
          : <drive.File>[];

      List<drive.File> merged;
      if (loadMore) {
        // Append while avoiding duplicate IDs
        final existingIds = existing.map((e) => e.id).toSet();
        merged = existing
          ..addAll(newFiles.where((f) => !existingIds.contains(f.id)));
      } else {
        merged = newFiles;
      }

      _globalFolderCache[_currentFolderId!] = merged;
      _globalNextPageToken[_currentFolderId!] = nextPageToken;

      if (mounted) {
        setState(() {
          _files = List<drive.File>.from(merged);
          _error = null;
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = s!.failedToLoadFiles(e.toString());
          _offlineMode = true;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      developer.log('Error fetching Drive files: $e',
          name: 'LectureFolderBrowser');
      // Fallback to any local files for the folder
      final localFiles = await _buildLocalFilesForCurrentFolder();
      if (mounted) {
        setState(() {
          _files = localFiles;
        });
      }
    }
  }

  bool _isFolder(drive.File file) {
    return file.mimeType == 'application/vnd.google-apps.folder';
  }

  void _toggleSelection(drive.File file) {
    if (!mounted) return;
    setState(() {
      if (_selectedFiles.any((selectedFile) => selectedFile.id == file.id)) {
        _selectedFiles
            .removeWhere((selectedFile) => selectedFile.id == file.id);
        if (_selectedFiles.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedFiles.add(file);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelectionMode() {
    if (!mounted) return;
    setState(() {
      _isSelectionMode = false;
      _selectedFiles.clear();
    });
  }

  void _onItemTap(drive.File file) {
    if (!mounted || s == null) return;
    if (_isSelectionMode) {
      _toggleSelection(file);
    } else {
      if (_isFolder(file)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LectureFolderBrowserScreen(
              initialFolderId: file.id!,
              academicContext: widget.academicContext,
            ),
          ),
        );
      } else {
        // Prefer opening a locally downloaded file (if present) to avoid re-downloading
        final String? fileName = file.name;
        if (fileName != null && fileName.isNotEmpty) {
          _tryOpenLocalFileIfExists(fileName).then((opened) {
            if (!opened) {
              // Fallback to normal online handling
              if (file.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s!.errorFileIdMissing)),
                );
                return;
              }

              final lower = fileName.toLowerCase();
              if (lower.endsWith('.pdf')) {
                final String directPdfUrl =
                    'https://drive.google.com/uc?export=download&id=${file.id!}';
                Navigator.of(context, rootNavigator: true).pushNamed(
                  '/pdfViewer',
                  arguments: {
                    'fileUrl': directPdfUrl,
                    'fileId': file.id!,
                    'fileName': fileName,
                  },
                );
              } else if (lower.endsWith('.mp4') ||
                  lower.endsWith('.mov') ||
                  lower.endsWith('.avi') ||
                  lower.endsWith('.mkv') ||
                  lower.endsWith('.webm')) {
                final String directVideoUrl =
                    'https://drive.google.com/uc?export=download&id=${file.id!}';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VideoPlayerScreen(
                      videoPath: directVideoUrl,
                      title: fileName,
                      isLocalFile: false,
                    ),
                  ),
                );
              } else if (lower.endsWith('.mp3') ||
                  lower.endsWith('.wav') ||
                  lower.endsWith('.m4a') ||
                  lower.endsWith('.aac') ||
                  lower.endsWith('.ogg') ||
                  lower.endsWith('.flac')) {
                final String directAudioUrl =
                    'https://drive.google.com/uc?export=download&id=${file.id!}';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AudioPlayerScreen(
                      audioPath: directAudioUrl,
                      title: fileName,
                      isLocalFile: false,
                    ),
                  ),
                );
              } else if (lower.endsWith('.docx') ||
                  lower.endsWith('.xlsx') ||
                  lower.endsWith('.pptx')) {
                final String directDocUrl =
                    'https://drive.google.com/uc?export=download&id=${file.id!}';
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OfficeDocumentViewerScreen(
                      documentPath: directDocUrl,
                      title: fileName,
                      isLocalFile: false,
                    ),
                  ),
                );
              } else if (file.webViewLink != null) {
                Navigator.of(context, rootNavigator: true).pushNamed(
                  '/googleDriveViewer',
                  arguments: {
                    'embedUrl': file.webViewLink,
                    'fileId': file.id,
                    'fileName': fileName,
                    'mimeType': file.mimeType,
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s!.cannotOpenFileType)),
                );
              }
            }
          });
        }
      }
    }
  }

  Future<bool> _tryOpenLocalFileIfExists(String fileName) async {
    try {
      final downloadPathProvider =
          Provider.of<DownloadPathProvider>(context, listen: false);
      final String dirPath =
          await downloadPathProvider.getEffectiveDownloadPath();
      final String filePath = '$dirPath${Platform.pathSeparator}$fileName';
      final f = File(filePath);
      if (await f.exists()) {
        final lower = fileName.toLowerCase();
        if (lower.endsWith('.pdf')) {
          if (!mounted) return true;
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/pdfViewer',
            arguments: {
              'localPath': filePath,
              'fileId': fileName,
              'fileName': fileName,
            },
          );
          return true;
        } else if (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.bmp')) {
          if (!mounted) return true;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LocalImageViewerScreen(
                imagePath: filePath,
                title: fileName,
              ),
            ),
          );
          return true;
        } else if (lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi') ||
            lower.endsWith('.mkv') ||
            lower.endsWith('.webm')) {
          if (!mounted) return true;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                videoPath: filePath,
                title: fileName,
                isLocalFile: true,
              ),
            ),
          );
          return true;
        } else if (lower.endsWith('.mp3') ||
            lower.endsWith('.wav') ||
            lower.endsWith('.m4a') ||
            lower.endsWith('.aac') ||
            lower.endsWith('.ogg') ||
            lower.endsWith('.flac')) {
          if (!mounted) return true;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AudioPlayerScreen(
                audioPath: filePath,
                title: fileName,
                isLocalFile: true,
              ),
            ),
          );
          return true;
        } else if (lower.endsWith('.docx') ||
            lower.endsWith('.xlsx') ||
            lower.endsWith('.pptx')) {
          if (!mounted) return true;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OfficeDocumentViewerScreen(
                documentPath: filePath,
                title: fileName,
                isLocalFile: true,
              ),
            ),
          );
          return true;
        }
        // For other types, keep returning false to fallback to online/open-file logic
        return false;
      }
    } catch (e) {
      developer.log('Error attempting to open local file: $e',
          name: 'LectureFolderBrowser');
    }
    return false;
  }

  void _onItemLongPress(drive.File file) {
    if (!mounted) return;
    if (file.id != null) {
      setState(() {
        _isSelectionMode = true;
        _toggleSelection(file);
      });
    }
  }

  Future<void> _downloadSelectedFiles() async {
    if (!mounted || s == null || _selectedFiles.isEmpty) return;

    final downloadPathProvider =
        Provider.of<DownloadPathProvider>(context, listen: false);
    // Request permissions using the centralized method
    bool granted =
        await downloadPathProvider.requestStoragePermissions(context, s!);
    if (!mounted) return; // Added mounted check after await
    if (!granted) {
      developer.log("Permission not granted, aborting download.",
          name: "DownloadFiles");
      return; // Stop if permissions are not granted
    }

    String effectiveDownloadPath =
        await downloadPathProvider.getEffectiveDownloadPath();
    if (!mounted) return; // Added mounted check after await

    final targetDirectory = Directory(effectiveDownloadPath);
    if (!await targetDirectory.exists()) {
      try {
        await targetDirectory.create(recursive: true);
        developer.log(
            "Created app-specific download directory: ${effectiveDownloadPath}",
            name: "DownloadFiles");
      } catch (e) {
        developer.log(
            "Failed to create app-specific directory ${effectiveDownloadPath}: $e",
            name: "DownloadFiles");
        if (mounted) {
          // Ensure mounted
          showAppSnackBar(context, s!.failedToCreateDirectory(e.toString()));
        }
        return;
      }
    }

    if (mounted) {
      // Ensure mounted before setState
      setState(() {
        _isDownloadingMultiple = true;
      });
    }

    if (mounted) {
      // Ensure mounted before showAppSnackBar
      showAppSnackBar(context, s!.downloadStarted(_selectedFiles.length));
    }

    int successCount = 0;
    final dio = Dio();

    for (var fileToDownload in _selectedFiles) {
      if (!mounted) {
        // Added mounted check inside loop
        developer.log("Widget unmounted during download loop.",
            name: "DownloadFiles");
        break; // Exit loop if widget is unmounted
      }
      if (_isFolder(fileToDownload)) continue;

      final fileName = fileToDownload.name ?? 'downloaded_file';
      final fileId = fileToDownload.id;
      if (fileId == null) {
        developer.log("Skipping download for file with null ID: $fileName",
            name: "DownloadFiles");
        continue;
      }

      final filePath = '${effectiveDownloadPath}/${fileName}';
      final String downloadUrl = fileToDownload.webContentLink ??
          'https://drive.google.com/uc?export=download&id=${fileId}';

      final cancelToken = CancelToken();
      _cancelTokens[fileId] = cancelToken;

      try {
        if (mounted) {
          // Ensure mounted before setState
          setState(() {
            _downloadProgressMap[fileId] = 0.0;
          });
        }

        developer.log(
            "Starting download for ${fileToDownload.name} to ${filePath} (app-specific) from ${downloadUrl}",
            name: "DownloadFiles");

        await dio.download(
          downloadUrl,
          filePath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (total != -1 && mounted) {
              // Ensure mounted before setState
              setState(() {
                _downloadProgressMap[fileId] = received / total;
              });
            }
          },
          options: Options(
              headers: {}), // No authentication headers needed for public files
        );

        if (!mounted) return; // Added mounted check after await

        if (mounted) {
          // Ensure mounted before setState
          setState(() {
            _downloadProgressMap[fileId] = 1.0;
          });
          showAppSnackBar(
            context,
            s!.downloadCompleted(fileName),
            action: SnackBarAction(
              label: s!.openFile,
              onPressed: () {
                final lower = fileName.toLowerCase();
                if (lower.endsWith('.pdf')) {
                  Navigator.of(context, rootNavigator: true).pushNamed(
                    '/pdfViewer',
                    arguments: {
                      'localPath': filePath,
                      'fileId': fileName,
                      'fileName': fileName,
                    },
                  );
                } else if (lower.endsWith('.jpg') ||
                    lower.endsWith('.jpeg') ||
                    lower.endsWith('.png') ||
                    lower.endsWith('.gif') ||
                    lower.endsWith('.webp') ||
                    lower.endsWith('.bmp')) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LocalImageViewerScreen(
                        imagePath: filePath,
                        title: fileName,
                      ),
                    ),
                  );
                } else if (lower.endsWith('.mp4') ||
                    lower.endsWith('.mov') ||
                    lower.endsWith('.avi') ||
                    lower.endsWith('.mkv') ||
                    lower.endsWith('.webm')) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(
                        videoPath: filePath,
                        title: fileName,
                        isLocalFile: true,
                      ),
                    ),
                  );
                } else if (lower.endsWith('.mp3') ||
                    lower.endsWith('.wav') ||
                    lower.endsWith('.m4a') ||
                    lower.endsWith('.aac') ||
                    lower.endsWith('.ogg') ||
                    lower.endsWith('.flac')) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AudioPlayerScreen(
                        audioPath: filePath,
                        title: fileName,
                        isLocalFile: true,
                      ),
                    ),
                  );
                } else if (lower.endsWith('.docx') ||
                    lower.endsWith('.xlsx') ||
                    lower.endsWith('.pptx')) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OfficeDocumentViewerScreen(
                        documentPath: filePath,
                        title: fileName,
                        isLocalFile: true,
                      ),
                    ),
                  );
                } else {
                  OpenFilex.open(filePath);
                }
              },
            ),
          );
        }
        // Record in-memory that this folder has this downloaded file
        if (_currentFolderId != null) {
          final set =
              _globalFolderDownloadedNames[_currentFolderId!] ?? <String>{};
          set.add(fileName);
          _globalFolderDownloadedNames[_currentFolderId!] = set;
          // Persist for future sessions
          _persistAddDownloadedName(_currentFolderId!, fileName);
        }
        successCount++;
      } on DioException catch (e) {
        if (!mounted) return; // Added mounted check in catch block
        if (e.type == DioExceptionType.cancel) {
          developer.log("Download cancelled for $fileName",
              name: "DownloadFiles");
          if (mounted)
            showAppSnackBar(
                context, s!.downloadCancelled(fileName)); // Ensure mounted
        } else {
          developer.log("Dio download failed for $fileName (app-specific): $e",
              name: "DownloadFiles");
          if (mounted) {
            // Ensure mounted
            final partialFile =
                File(filePath); // Correctly define partialFile within scope
            if (await partialFile.exists()) {
              try {
                await partialFile.delete(); // Delete partial file
                developer.log("Deleted partial file: $filePath",
                    name: 'LectureFolderBrowser');
              } catch (delErr) {
                developer.log(
                    "Error deleting partial file during exception handling: $delErr",
                    name: 'LectureFolderBrowser');
              }
            }
            showAppSnackBar(context, s!.downloadFailed(fileName, e.toString()));
            setState(() {
              _downloadProgressMap.remove(fileId);
            });
          }
        }
      } catch (e) {
        if (!mounted) return; // Added mounted check in catch block
        developer.log("Generic download error for $fileName (app-specific): $e",
            name: "DownloadFiles");
        if (mounted) {
          // Ensure mounted
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s!.downloadFailed(fileName, e.toString()))));
          setState(() {
            _downloadProgressMap.remove(fileId);
          });
        }
      } finally {
        _cancelTokens.remove(fileId);
      }
    }

    if (mounted) {
      // Ensure mounted
      setState(() {
        _isDownloadingMultiple = false;
        _cancelSelectionMode();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s!.allDownloadsCompleted),
          action: successCount > 0
              ? SnackBarAction(
                  label: s!.openFolder,
                  onPressed: () async {
                    try {
                      final pathProvider = Provider.of<DownloadPathProvider>(
                          context,
                          listen: false);
                      final folderPath =
                          await pathProvider.getEffectiveDownloadPath();
                      await OpenFilex.open(folderPath);
                    } catch (e) {
                      developer.log("Could not open download folder: $e",
                          name: "DownloadFiles");
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text(s!.couldNotOpenFolder(e.toString()))));
                      }
                    }
                  })
              : null,
        ),
      );
    }
  }

  void _viewSelectedFileDetails() {
    if (_selectedFiles.length == 1) {
      final file = _selectedFiles.first;
      showDialog(
        context: context,
        builder: (context) => FileDetailsDialog(file: file, s: s!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s!.noItemSelectedForDetails)),
      );
    }
  }

  /// Handle leader mode actions (rename/delete)
  void _handleLeaderAction(String action, drive.File file) {
    if (action == 'rename') {
      _showRenameDialog(file);
    } else if (action == 'delete') {
      _showDeleteConfirmation(file);
    }
  }

  /// Show rename dialog for file/folder
  void _showRenameDialog(drive.File file) {
    final TextEditingController controller = TextEditingController(text: file.name);
    final isFolder = _isFolder(file);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            Icon(isFolder ? Icons.folder : Icons.edit, color: Colors.blue, size: 28),
            const SizedBox(width: 12),
            Text(isFolder ? AppLocalizations.of(context)!.renameFolder : AppLocalizations.of(context)!.renameItem, 
                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.enterNewName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty && value.trim() != file.name) {
                  Navigator.pop(context);
                  _performRename(file, value.trim());
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final newName = controller.text.trim();
                    if (newName.isNotEmpty && newName != file.name) {
                      Navigator.pop(context);
                      _performRename(file, newName);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.rename, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(drive.File file) {
    final isFolder = _isFolder(file);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(isFolder ? AppLocalizations.of(context)!.deleteFolder : AppLocalizations.of(context)!.deleteItem,
                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.confirmDeleteMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              isFolder ? 'This will delete the folder and all its contents.' : 'This action cannot be undone.',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _performDelete(file);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)!.delete, style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Perform rename operation
  Future<void> _performRename(drive.File file, String newName) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    // Normalize academic context values to English for permission checks
    final normalizedGrade = _normalizeGrade(widget.academicContext?.grade ?? 'Unknown');
    final normalizedDepartment = _normalizeDepartment(widget.academicContext?.department ?? 'Unknown');
    final normalizedYear = _normalizeYear(widget.academicContext?.year ?? 'Unknown');
    
    final success = await leaderProvider.renameFileOrFolder(
      fileId: file.id!,
      newName: newName,
      grade: normalizedGrade,
      department: normalizedDepartment,
      year: normalizedYear,
      context: context,
    );

    if (success) {
      // Refresh the file list to show updated name
      _fetchDriveFiles();
    }
  }

  /// Perform delete operation
  Future<void> _performDelete(drive.File file) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    // Normalize academic context values to English for permission checks
    final normalizedGrade = _normalizeGrade(widget.academicContext?.grade ?? 'Unknown');
    final normalizedDepartment = _normalizeDepartment(widget.academicContext?.department ?? 'Unknown');
    final normalizedYear = _normalizeYear(widget.academicContext?.year ?? 'Unknown');
    
    final success = await leaderProvider.deleteFileOrFolder(
      fileId: file.id!,
      fileName: file.name ?? 'Unknown',
      grade: normalizedGrade,
      department: normalizedDepartment,
      year: normalizedYear,
      context: context,
    );

    if (success) {
      // Refresh the file list to remove deleted item
      _fetchDriveFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (s == null) {
      return Scaffold(
          appBar: AppBar(
              title:
                  Text(AppLocalizations.of(context)?.lectures ?? "Lectures")),
          body: Center(
              child: Text(AppLocalizations.of(context)?.loadingLocalizations ??
                  "Loading localizations...")));
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          // App bar actions
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _selectedFiles.isNotEmpty && !_isDownloadingMultiple
                  ? _downloadSelectedFiles
                  : null,
              tooltip: s!.downloadAction,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed:
                  _selectedFiles.length == 1 && !_isDownloadingMultiple
                      ? _viewSelectedFileDetails
                      : null,
              tooltip: s!.viewDetails,
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed:
                  _isDownloadingMultiple ? null : _cancelSelectionMode,
              tooltip: s!.cancelSelection,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isDownloadingMultiple ? null : _fetchDriveFiles,
              tooltip: s!.refresh,
            ),
            if (_offlineMode)
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Icon(Icons.wifi_off, color: Colors.redAccent),
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          // --- Search and Sort Controls ---
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: s!.search,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<_SortMode>(
                  value: _sortMode,
                  items: [
                    DropdownMenuItem(
                      value: _SortMode.nameAsc,
                      child: Row(children: [
                        Icon(Icons.sort_by_alpha),
                        SizedBox(width: 4),
                        Text(s!.sortNameAsc)
                      ]),
                    ),
                    DropdownMenuItem(
                      value: _SortMode.nameDesc,
                      child: Row(children: [
                        Icon(Icons.sort_by_alpha),
                        SizedBox(width: 4),
                        Text(s!.sortNameDesc)
                      ]),
                    ),
                    DropdownMenuItem(
                      value: _SortMode.dateDesc,
                      child: Row(children: [
                        Icon(Icons.schedule),
                        SizedBox(width: 4),
                        Text(s!.sortDateDesc)
                      ]),
                    ),
                    DropdownMenuItem(
                      value: _SortMode.dateAsc,
                      child: Row(children: [
                        Icon(Icons.schedule),
                        SizedBox(width: 4),
                        Text(s!.sortDateAsc)
                      ]),
                    ),
                    DropdownMenuItem(
                      value: _SortMode.type,
                      child: Row(children: [
                        Icon(Icons.category),
                        SizedBox(width: 4),
                        Text(s!.sortType)
                      ]),
                    ),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      setState(() {
                        _sortMode = mode;
                      });
                    }
                  },
                  underline: Container(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 50),
                              const SizedBox(height: 10),
                              Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 16),
                                  textAlign: TextAlign.center),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                onPressed: _fetchDriveFiles,
                                label: Text(s!.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _files == null || _files!.isEmpty
                        ? _buildEmptyState(Icons.folder_open_outlined,
                            s!.noFilesIllustrationText)
                        : ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _filteredAndSortedFiles().length +
                                ((_globalNextPageToken[
                                            _currentFolderId ?? ''] !=
                                        null)
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              final bool hasMore = _globalNextPageToken[
                                      _currentFolderId ?? ''] !=
                                  null;
                              // Load More row
                              if (hasMore &&
                                  index == _filteredAndSortedFiles().length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: ElevatedButton.icon(
                                    icon: _isLoadingMore
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.expand_more),
                                    label: Text(_isLoadingMore
                                        ? s!.loading
                                        : s!.refresh),
                                    onPressed: _isLoadingMore
                                        ? null
                                        : () =>
                                            _fetchDriveFiles(loadMore: true),
                                  ),
                                );
                              }

                              final file = _filteredAndSortedFiles()[index];
                              final bool isSelected =
                                  _selectedFiles.any((sf) => sf.id == file.id);
                              final double? progress =
                                  _downloadProgressMap[file.id];

                              return Card(
                                color: isSelected
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.2)
                                    : null,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Stack(
                                  children: [
                                    ListTile(
                                      leading: _isSelectionMode
                                          ? Checkbox(
                                              value: isSelected,
                                              onChanged: (bool? value) {
                                                // Only allow selecting real Drive files (not synthetic local entries)
                                                if (file.id != null &&
                                                    !(file.id!
                                                        .startsWith('local:')))
                                                  _toggleSelection(file);
                                              },
                                            )
                                          : Icon(
                                              _isFolder(file)
                                                  ? Icons.folder_open_outlined
                                                  : _getIconForMimeType(
                                                      file.mimeType),
                                              color: _isFolder(file)
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.6),
                                              size: 28,
                                            ),
                                      title: Text(
                                        file.name ?? s!.unnamedItem,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: (progress != null &&
                                              progress > 0 &&
                                              progress < 1)
                                          ? Text(
                                              "${s!.downloading} (${(progress * 100).toStringAsFixed(0)}%)")
                                          : null,
                                      trailing: !_isSelectionMode
                                          ? Consumer<LeaderModeProvider>(
                                              builder: (context, leaderProvider, child) {
                                                if (leaderProvider.isLeaderMode && file.id != null && !file.id!.startsWith('local:')) {
                                                  return PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_vert, size: 20),
                                                    onSelected: (value) => _handleLeaderAction(value, file),
                                                    itemBuilder: (context) => [
                                                      PopupMenuItem(
                                                        value: 'rename',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit, size: 18),
                                                            SizedBox(width: 8),
                                                            Text(AppLocalizations.of(context)!.rename),
                                                          ],
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                                            SizedBox(width: 8),
                                                            Text(AppLocalizations.of(context)!.delete, style: TextStyle(color: Colors.red)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                } else if (!_isFolder(file)) {
                                                  return const Icon(Icons.arrow_forward_ios,
                                                      size: 16, color: Colors.grey);
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            )
                                          : null,
                                      onTap: () => _onItemTap(file),
                                      onLongPress: () => _onItemLongPress(file),
                                    ),
                                    if (progress != null &&
                                        progress > 0 &&
                                        progress < 1)
                                      Positioned.fill(
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.3)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          )
        ],
      ),
      floatingActionButton: Consumer<LeaderModeProvider>(
        builder: (context, leaderProvider, child) {
          if (leaderProvider.isLeaderMode) {
            return FloatingActionButton(
              onPressed: () => MaterialUploadHelper.showMaterialUploadBottomSheetWithContext(
                context,
                _currentFolderId,
                widget.academicContext,
              ),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _getAppBarTitle() {
    // Use subject name if available, otherwise fall back to academic context or "Lectures"
    if (widget.subjectName != null && widget.subjectName!.isNotEmpty) {
      return widget.subjectName!;
    }
    if (widget.academicContext != null) {
      final context = widget.academicContext!;
      if (context.semester != null && context.semester!.isNotEmpty) {
        final localizedSemester = _getLocalizedSemesterName(context.semester!);
        return '$localizedSemester - ${context.grade}';
      }
      if (context.grade != null && context.grade!.isNotEmpty) {
        return context.grade;
      }
    }
    return "Lectures";
  }

  String _getLocalizedSemesterName(String semesterName) {
    final s = AppLocalizations.of(context)!;
    if (semesterName == 'Semester 1' || semesterName == 'الفصل الأول') {
      return s.semester1;
    } else if (semesterName == 'Semester 2' || semesterName == 'الفصل الثاني') {
      return s.semester2;
    }
    return semesterName; // Return original if no match
  }

  IconData _getIconForMimeType(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    if (mimeType.startsWith('image/')) return Icons.image_outlined;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf_outlined;
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint'))
      return Icons.slideshow_outlined;
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel'))
      return Icons.table_chart_outlined;
    if (mimeType.contains('document') || mimeType.contains('word'))
      return Icons.article_outlined;
    if (mimeType.startsWith('video/')) return Icons.video_library_outlined;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon,
              size: 80,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sort Mode Enum and Extension ---
enum _SortMode { nameAsc, nameDesc, dateAsc, dateDesc, type }

extension _SortModeStrings on AppLocalizations {
  String get sortNameAsc => "A-Z";
  String get sortNameDesc => "Z-A";
  String get sortDateAsc => "Oldest";
  String get sortDateDesc => "Newest";
  String get sortType => "Type";
}

// --- File Details Dialog ---
class FileDetailsDialog extends StatelessWidget {
  final drive.File file;
  final AppLocalizations s;

  const FileDetailsDialog({super.key, required this.file, required this.s});

  @override
  Widget build(BuildContext context) {
    String formattedDate = s.notAvailableNow; // Default
    if (file.modifiedTime != null) {
      try {
        final currentLocale = Localizations.localeOf(context).toString();
        formattedDate = DateFormat.yMMMd(currentLocale)
            .add_jm()
            .format(file.modifiedTime!.toLocal());
      } catch (e) {
        developer.log("Error formatting date: $e", name: "FileDetailsDialog");
        formattedDate = file.modifiedTime!
            .toLocal()
            .toString()
            .substring(0, 16); // Fallback
      }
    }
    String fileSize = file.size != null
        ? formatBytesSimplified(int.tryParse(file.size!) ?? 0, 2, s)
        : s.notAvailableNow;

    return AlertDialog(
      title: Text(s.fileDetails),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            _buildDetailRow(s.fileNameField, file.name ?? s.unnamedItem),
            _buildDetailRow(
                s.fileTypeField, file.mimeType ?? s.notAvailableNow),
            _buildDetailRow(s.fileSizeField, fileSize),
            _buildDetailRow(s.lastModifiedField, formattedDate),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(s.ok),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
