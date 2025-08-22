// lib/helper.dart

import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'app_core.dart';
import 'study_features.dart';

class NotificationService {
  static bool isAnyPermissionBeingRequested = false;

  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> requestNotificationPermission() async {
    while (isAnyPermissionBeingRequested) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    isAnyPermissionBeingRequested = true;
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }

      if (!await AndroidUtils.canScheduleExactAlarms()) {
        await AndroidUtils.openExactAlarmSettingsIfRequired();
      }
    } finally {
      isAnyPermissionBeingRequested = false;
    }
  }

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    final localTimeZone = await FlutterTimezone.getLocalTimezone();

    try {
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (e) {
      // print(e.toString());
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_notify');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'due_day_channel',
      'Due Day Notifications',
      importance: Importance.high,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}

class AndroidUtils {
  static Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      final canSchedule = await NotificationService.notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.canScheduleExactNotifications();
      return canSchedule ?? false;
    }
    return true;
  }

  static Future<void> openExactAlarmSettingsIfRequired() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      if (sdkInt >= 31) {
        const intent = AndroidIntent(
          action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        );
        await intent.launch();
      }
    }
  }
}

// --- Material Upload Helper Classes ---
class MaterialUploadHelper {
  /// Show material upload bottom sheet
  static void showMaterialUploadBottomSheet(BuildContext context) {
    // Extract context information before showing the bottom sheet
    final folderId = _getCurrentFolderId(context);
    final grade = _getCurrentGrade(context);
    final department = _getCurrentDepartment(context);
    final year = _getCurrentYear(context);

    // Debug: Print extracted values
    print('DEBUG: Extracted context values:');
    print('  folderId: $folderId');
    print('  grade: $grade');
    print('  department: $department');
    print('  year: $year');

    if (folderId == null) {
      showAppSnackBar(
        context,
        'Cannot determine current folder location. Please try again.',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => MaterialUploadBottomSheet(
        folderId: folderId,
        grade: grade,
        department: department,
        year: year,
        parentContext: context,
      ),
    );
  }

  /// Show material upload bottom sheet with explicit context
  static void showMaterialUploadBottomSheetWithContext(
    BuildContext context,
    String? folderId,
    AcademicContext? academicContext,
  ) {
    // Debug: Print provided values
    print('DEBUG: Direct folder upload - folderId: $folderId');

    if (folderId == null || folderId.isEmpty) {
      showAppSnackBar(
        context,
        'Cannot determine current folder location. Please try again.',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => MaterialUploadBottomSheet(
        folderId: folderId,
        grade: academicContext?.grade,
        department: academicContext?.department,
        year: academicContext?.year,
        parentContext: context,
      ),
    );
  }
  
  // Helper methods to extract context from current route
  static String? _getCurrentFolderId(BuildContext context) {
    // Use the static method to get the current dynamic folder ID from the browser state
    return LectureFolderBrowserScreen.getCurrentFolderId(context);
  }

  static String? _getCurrentGrade(BuildContext context) {
    // Try to find the LectureFolderBrowserScreen widget in the widget tree
    LectureFolderBrowserScreen? browserScreen;
    context.visitAncestorElements((element) {
      if (element.widget is LectureFolderBrowserScreen) {
        browserScreen = element.widget as LectureFolderBrowserScreen;
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    
    return browserScreen?.academicContext?.grade;
  }

  static String? _getCurrentDepartment(BuildContext context) {
    // Try to find the LectureFolderBrowserScreen widget in the widget tree
    LectureFolderBrowserScreen? browserScreen;
    context.visitAncestorElements((element) {
      if (element.widget is LectureFolderBrowserScreen) {
        browserScreen = element.widget as LectureFolderBrowserScreen;
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    
    return browserScreen?.academicContext?.department;
  }

  static String? _getCurrentYear(BuildContext context) {
    // Try to find the LectureFolderBrowserScreen widget in the widget tree
    LectureFolderBrowserScreen? browserScreen;
    context.visitAncestorElements((element) {
      if (element.widget is LectureFolderBrowserScreen) {
        browserScreen = element.widget as LectureFolderBrowserScreen;
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    
    return browserScreen?.academicContext?.year;
  }
}

class MaterialUploadBottomSheet extends StatelessWidget {
  final String? folderId;
  final String? grade;
  final String? department;
  final String? year;
  final BuildContext parentContext;

  const MaterialUploadBottomSheet({
    super.key,
    this.folderId,
    this.grade,
    this.department,
    this.year,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            'Add Content',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // --- Search and Sort Controls ---
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomSheetOption(
                  icon: Icons.folder_outlined,
                  label: 'Folder',
                  onTap: () {
                    Navigator.pop(context);
                    ContentManager.createFolderWithContext(parentContext, folderId);
                  },
                ),
                _BottomSheetOption(
                  icon: Icons.upload_outlined,
                  label: 'Upload',
                  onTap: () {
                    Navigator.pop(context);
                    ContentManager.uploadFileWithContext(parentContext, folderId, grade, department, year);
                  },
                ),
                _BottomSheetOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Scan',
                  onTap: () {
                    Navigator.pop(context);
                    ContentManager.scanDocumentWithContext(parentContext, folderId, grade, department, year);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Content Management Helper ---
class ContentManager {
  // New methods with explicit context parameters
  static void createFolderWithContext(BuildContext context, String? folderId) {
    if (folderId == null) {
      showAppSnackBar(
        context,
        'Cannot determine current folder location',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder, color: Colors.blue),
            SizedBox(width: 8),
            Text('Create Folder'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
              _createFolderWithNameAndContext(context, value.trim(), folderId);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final folderName = controller.text.trim();
              if (folderName.isNotEmpty) {
                Navigator.pop(context);
                _createFolderWithNameAndContext(context, folderName, folderId);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  static void uploadFileWithContext(BuildContext context, String? folderId, String? grade, String? department, String? year) async {
    if (folderId == null) {
      showAppSnackBar(
        context,
        'Cannot determine current folder location',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    if (!leaderProvider.isLeaderMode) {
      showAppSnackBar(
        context,
        'Please sign in as leader first',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.path != null) {
          final success = await leaderProvider.uploadFileToFolder(
            folderId: folderId,
            file: File(file.path!),
            fileName: file.name,
            grade: grade ?? 'Unknown',
            department: department ?? 'Unknown',
            year: year ?? 'Unknown',
            onProgress: (progress) {
              // Progress feedback could be enhanced with a progress dialog
            },
            context: context,
          );

          if (success && context.mounted) {
            showAppSnackBar(
              context,
              'File "${file.name}" uploaded successfully',
              icon: Icons.upload_file,
              iconColor: Colors.green,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Error uploading file: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  static void scanDocumentWithContext(BuildContext context, String? folderId, String? grade, String? department, String? year) async {
    if (folderId == null) {
      showAppSnackBar(
        context,
        'Cannot determine current folder location',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }
    
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    if (!leaderProvider.isLeaderMode) {
      showAppSnackBar(
        context,
        'Please sign in as leader first',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      // Check camera permission
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          if (context.mounted) {
            showAppSnackBar(
              context,
              'Camera permission required for document scanning',
              icon: Icons.camera_alt,
              iconColor: Colors.orange,
            );
          }
          return;
        }
      }

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final fileName = 'scanned_document_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final success = await leaderProvider.uploadFileToFolder(
          folderId: folderId,
          file: File(image.path),
          fileName: fileName,
          grade: grade ?? 'Unknown',
          department: department ?? 'Unknown',
          year: year ?? 'Unknown',
          onProgress: (progress) {
            // Progress feedback could be enhanced with a progress dialog
          },
          context: context,
        );

        if (success && context.mounted) {
          showAppSnackBar(
            context,
            'Document scanned and uploaded successfully',
            icon: Icons.scanner,
            iconColor: Colors.green,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Error scanning document: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  static void _createFolderWithNameAndContext(BuildContext context, String folderName, String folderId) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    if (!leaderProvider.isLeaderMode) {
      showAppSnackBar(
        context,
        'Please sign in as leader first',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      final success = await leaderProvider.createFolderInDrive(
        parentFolderId: folderId,
        folderName: folderName,
        context: context,
      );

      if (success && context.mounted) {
        showAppSnackBar(
          context,
          'Folder "$folderName" created successfully',
          icon: Icons.folder,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Failed to create folder: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  // Original methods (kept for backward compatibility)
  static void createFolder(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.create_new_folder, color: Colors.blue),
            SizedBox(width: 8),
            Text('Create Folder'),
          ],
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context);
              _createFolderWithName(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final folderName = controller.text.trim();
              if (folderName.isNotEmpty) {
                Navigator.pop(context);
                _createFolderWithName(context, folderName);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  static void _createFolderWithName(BuildContext context, String folderName) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    if (!leaderProvider.isLeaderMode) {
      showAppSnackBar(
        context,
        'Please sign in as leader first',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      // Get current folder context from the route
      final currentFolderId = _getCurrentFolderId(context);
      
      if (currentFolderId == null) {
        showAppSnackBar(
          context,
          'Cannot determine current folder location',
          icon: Icons.error,
          iconColor: Colors.red,
        );
        return;
      }

      final success = await leaderProvider.createFolderInDrive(
        parentFolderId: currentFolderId,
        folderName: folderName,
        context: context,
      );

      if (success && context.mounted) {
        showAppSnackBar(
          context,
          'Folder "$folderName" created successfully',
          icon: Icons.folder,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Failed to create folder: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  static void uploadFile(BuildContext context) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    if (!leaderProvider.isLeaderMode) {
      showAppSnackBar(
        context,
        'Please sign in as leader first',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final currentFolderId = _getCurrentFolderId(context);
        
        if (currentFolderId == null) {
          if (context.mounted) {
            showAppSnackBar(
              context,
              'Cannot determine current folder location',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          }
          return;
        }

        if (file.path != null) {
          final grade = _getCurrentGrade(context) ?? 'Unknown';
          final department = _getCurrentDepartment(context) ?? 'Unknown';
          final year = _getCurrentYear(context) ?? 'Unknown';
          
          final success = await leaderProvider.uploadFileToFolder(
            folderId: currentFolderId,
            file: File(file.path!),
            fileName: file.name,
            grade: grade,
            department: department,
            year: year,
            onProgress: (progress) {
              // Progress feedback could be enhanced with a progress dialog
            },
            context: context,
          );

          if (success && context.mounted) {
            showAppSnackBar(
              context,
              'File "${file.name}" uploaded successfully',
              icon: Icons.upload_file,
              iconColor: Colors.green,
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Error uploading file: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  static void scanDocument(BuildContext context) async {
    final leaderProvider = Provider.of<LeaderModeProvider>(context, listen: false);
    
    if (!leaderProvider.isLeaderMode) {
      showAppSnackBar(
        context,
        'Please sign in as leader first',
        icon: Icons.error,
        iconColor: Colors.red,
      );
      return;
    }

    try {
      // Check camera permission
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          if (context.mounted) {
            showAppSnackBar(
              context,
              'Camera permission required for document scanning',
              icon: Icons.camera_alt,
              iconColor: Colors.orange,
            );
          }
          return;
        }
      }

      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final currentFolderId = _getCurrentFolderId(context);
        
        if (currentFolderId == null) {
          if (context.mounted) {
            showAppSnackBar(
              context,
              'Cannot determine current folder location',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          }
          return;
        }

        final fileName = 'scanned_document_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final grade = _getCurrentGrade(context) ?? 'Unknown';
        final department = _getCurrentDepartment(context) ?? 'Unknown';
        final year = _getCurrentYear(context) ?? 'Unknown';
        
        final success = await leaderProvider.uploadFileToFolder(
          folderId: currentFolderId,
          file: File(image.path),
          fileName: fileName,
          grade: grade,
          department: department,
          year: year,
          onProgress: (progress) {
            // Progress feedback could be enhanced with a progress dialog
          },
          context: context,
        );

        if (success && context.mounted) {
          showAppSnackBar(
            context,
            'Document scanned and uploaded successfully',
            icon: Icons.scanner,
            iconColor: Colors.green,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Error scanning document: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  // Helper methods to extract context from current route
  static String? _getCurrentFolderId(BuildContext context) {
    // Use the static method to get the current dynamic folder ID from the browser state
    return LectureFolderBrowserScreen.getCurrentFolderId(context);
  }

  static String? _getCurrentGrade(BuildContext context) {
    // Try to find the LectureFolderBrowserScreen widget in the widget tree
    LectureFolderBrowserScreen? browserScreen;
    context.visitAncestorElements((element) {
      if (element.widget is LectureFolderBrowserScreen) {
        browserScreen = element.widget as LectureFolderBrowserScreen;
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    
    return browserScreen?.academicContext?.grade;
  }

  static String? _getCurrentDepartment(BuildContext context) {
    // Try to find the LectureFolderBrowserScreen widget in the widget tree
    LectureFolderBrowserScreen? browserScreen;
    context.visitAncestorElements((element) {
      if (element.widget is LectureFolderBrowserScreen) {
        browserScreen = element.widget as LectureFolderBrowserScreen;
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    
    return browserScreen?.academicContext?.department;
  }

  static String? _getCurrentYear(BuildContext context) {
    // Try to find the LectureFolderBrowserScreen widget in the widget tree
    LectureFolderBrowserScreen? browserScreen;
    context.visitAncestorElements((element) {
      if (element.widget is LectureFolderBrowserScreen) {
        browserScreen = element.widget as LectureFolderBrowserScreen;
        return false; // Stop searching
      }
      return true; // Continue searching
    });
    
    return browserScreen?.academicContext?.year;
  }
}
