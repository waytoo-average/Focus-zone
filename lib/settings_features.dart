// lib/settings_features.dart

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'package:file_picker/file_picker.dart';
import 'src/utils/feedback_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'update_helper.dart';

// Core app imports
import 'package:app/app_core.dart';
import 'l10n/app_localizations.dart';
import 'src/ui/notification_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearInternalPdfCache(
      BuildContext context, AppLocalizations s) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      int count = 0;
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        for (FileSystemEntity entity in entities) {
          if (entity is File &&
              entity.path.endsWith('.pdf') &&
              entity.path.split('/').last.startsWith('pdf_cache_')) {
            await entity.delete();
            count++;
            developer.log("Deleted cached PDF: ${entity.path}",
                name: "SettingsScreen");
          }
        }
      }
      if (context.mounted) {
        showAppSnackBar(context, s.cacheClearedItems(count),
            icon: Icons.check_circle_outline, iconColor: Colors.green);
      }
    } catch (e) {
      developer.log("Error clearing cache: $e", name: "SettingsScreen");
      if (context.mounted) {
        showAppSnackBar(context, s.cacheClearFailed(e.toString()),
            icon: Icons.error_outline, iconColor: Colors.red);
      }
    }
  }

 

  Future<void> openFolderInListView({
    required BuildContext context,
    required String folderPath,
  }) async {
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 30) {
        hasPermission =
            (await Permission.manageExternalStorage.request()).isGranted;
      } else {
        hasPermission = (await Permission.storage.request()).isGranted;
      }
    } else {
      hasPermission = true;
    }

    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required.")),
        );
      }
      return;
    }

    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    try {
      final allEntities = dir.listSync();
      final files = allEntities.whereType<File>().toList();

      if (files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text("No files found in: ${path.basename(folderPath)}")),
          );
        }
        return;
      }

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (_, controller) => Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Files in ${path.basename(folderPath)} (${files.length})",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: files.length,
                    itemBuilder: (_, i) {
                      final file = files[i];
                      final fileName = path.basename(file.path);
                      final extension = path.extension(file.path).toLowerCase();

                      IconData icon = switch (extension) {
                        '.md' => Icons.description,
                        '.apk' => Icons.android,
                        '.pdf' => Icons.picture_as_pdf,
                        '.txt' => Icons.text_snippet,
                        _ => Icons.insert_drive_file,
                      };

                      return ListTile(
                        leading: Icon(icon),
                        title: Text(fileName),
                        subtitle: Text(
                            "${extension.toUpperCase()} • ${_getFileSize(file)}"),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) async {
                            switch (value) {
                              case 'open':
                                Navigator.pop(context);
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text("Cannot open file: $e")),
                                    );
                                  }
                                }
                                break;
                              case 'delete':
                                _showDeleteConfirmation(context, file, () {
                                  Navigator.pop(context);
                                  openFolderInListView(
                                      context: context, folderPath: folderPath);
                                });
                                break;
                              case 'rename':
                                _showRenameDialog(context, file, () {
                                  Navigator.pop(context);
                                  openFolderInListView(
                                      context: context, folderPath: folderPath);
                                });
                                break;
                              case 'info':
                                _showFileInfo(context, file);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'open',
                              child: Row(children: [
                                Icon(Icons.open_in_new),
                                SizedBox(width: 8),
                                Text('Open')
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Rename')
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red))
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'info',
                              child: Row(children: [
                                Icon(Icons.info_outline),
                                SizedBox(width: 8),
                                Text('Properties')
                              ]),
                            ),
                          ],
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          try {
                            await OpenFilex.open(file.path);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Cannot open file: $e")),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error accessing folder: $e")),
        );
      }
    }
  }

  void _showDeleteConfirmation(
      BuildContext context, File file, VoidCallback onDeleted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text(
            'Are you sure you want to delete "${path.basename(file.path)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await file.delete();
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Deleted ${path.basename(file.path)}')),
                  );
                }
                onDeleted();
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete file: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, File file, VoidCallback onRenamed) {
    final TextEditingController nameController = TextEditingController();
    final currentName = path.basenameWithoutExtension(file.path);
    final extension = path.extension(file.path);
    nameController.text = currentName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'New name',
            suffixText: extension,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;

              try {
                final newPath =
                    path.join(path.dirname(file.path), '$newName$extension');
                await file.rename(newPath);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Renamed to $newName$extension')),
                  );
                }
                onRenamed();
              } catch (e) {
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to rename file: $e')),
                  );
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showFileInfo(BuildContext context, File file) {
    final fileName = path.basename(file.path);
    final fileSize = _getFileSize(file);
    final filePath = file.path;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Properties'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', fileName),
            _buildInfoRow('Size:', fileSize),
            _buildInfoRow('Path:', filePath),
            _buildInfoRow('Type:', path.extension(file.path).toUpperCase()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '${bytes}B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  Future<void> _chooseDownloadLocation(BuildContext context, AppLocalizations s,
      DownloadPathProvider pathProvider) async {
    if (!context.mounted) return;

    if (Platform.isIOS) {
      await pathProvider.resetDownloadPath();
      if (context.mounted) {
        showAppSnackBar(
            context,
            s.downloadPathSetTo(await pathProvider
                .getEffectiveDownloadPath()), // FIX: Changed to getEffectiveDownloadPath
            icon: Icons.info_outline,
            iconColor: Colors.blue);
      }
      return;
    }

    bool granted = await pathProvider.requestStoragePermissions(context, s);
    if (!granted) {
      developer.log("Permission not granted for choosing download location.",
          name: "SettingsScreen");
      return;
    }

    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        final testFile = File('${selectedDirectory}/.test_write');
        try {
          await testFile.writeAsString('test');
          await testFile.delete();
          await pathProvider.setCustomDownloadPath(selectedDirectory);
          if (context.mounted) {
            showAppSnackBar(context, s.downloadPathSetTo(selectedDirectory),
                icon: Icons.check_circle_outline, iconColor: Colors.green);
          }
        } catch (e) {
          if (context.mounted) {
            showAppSnackBar(context, s.failedToCreateDirectory(e.toString()),
                icon: Icons.error_outline, iconColor: Colors.red);
          }
        }
      } else {
        if (context.mounted) {
          showAppSnackBar(context, s.noDirectorySelected);
        }
      }
    } catch (e) {
      developer.log("Error picking download location: $e",
          name: "SettingsScreen");
      if (context.mounted) {
        showAppSnackBar(context, s.failedToChooseDownloadPath(e.toString()),
            icon: Icons.error_outline, iconColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final signInProvider = Provider.of<SignInProvider>(context);
    final user = signInProvider.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final downloadPathProvider = Provider.of<DownloadPathProvider>(context);
    final s = AppLocalizations.of(context);

    if (s == null) {
      return Scaffold(
          appBar: AppBar(title: const Text("Settings")),
          body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            if (user != null) ...[
              Center(
                child: CircleAvatar(
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  radius: 40,
                  child: user.photoUrl == null
                      ? Text(
                          user.displayName?.isNotEmpty == true
                              ? user.displayName![0].toUpperCase()
                              : (user.email.isNotEmpty == true
                                  ? user.email[0].toUpperCase()
                                  : '?'),
                          style: const TextStyle(fontSize: 30),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  user.displayName ?? user.email,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  user.email,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: user == null
                  ? () => signInProvider.signInWithErrorHandling(context)
                  : signInProvider.signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: user == null
                    ? Theme.of(context).primaryColor
                    : Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              child: Text(user == null ? s.signInWithGoogle : s.signOut),
            ),
            const SizedBox(height: 20),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.info_outline,
              text: s.aboutCollege,
              onTap: () {
                Navigator.pushNamed(context, '/collegeInfo');
              },
            ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.feedback_outlined,
              text: s.feedbackCenter,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackCenterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.language_outlined,
              text: s.chooseLanguage,
              trailing: Text(
                languageProvider.locale.languageCode == 'ar'
                    ? 'العربية'
                    : 'English',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext dialogContext) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.chooseLanguage,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          _OptionCard(
                            title: 'English',
                            icon: Icons.language,
                            selected: languageProvider.locale.languageCode == 'en',
                            onTap: () {
                              languageProvider.setLocale(const Locale('en'));
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                          _OptionCard(
                            title: 'العربية',
                            icon: Icons.language,
                            selected: languageProvider.locale.languageCode == 'ar',
                            onTap: () {
                              languageProvider.setLocale(const Locale('ar'));
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.notifications_outlined,
              text: s.notificationSettingsTitle, 
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            _buildSettingsItem(context,
                s: s,
                icon: Icons.brightness_6_outlined,
                text: s.chooseTheme,
                trailing: Text(
                    themeProvider.themeMode == ThemeMode.light
                        ? s.lightTheme
                        : themeProvider.themeMode == ThemeMode.dark
                            ? s.darkTheme
                            : s.systemDefault,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6))), onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (BuildContext dialogContext) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.chooseTheme,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        _OptionCard(
                          title: s.lightTheme,
                          icon: Icons.light_mode,
                          selected: themeProvider.themeMode == ThemeMode.light,
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.light);
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        _OptionCard(
                          title: s.darkTheme,
                          icon: Icons.dark_mode,
                          selected: themeProvider.themeMode == ThemeMode.dark,
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.dark);
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        _OptionCard(
                          title: s.systemDefault,
                          icon: Icons.phone_iphone,
                          selected: themeProvider.themeMode == ThemeMode.system,
                          onTap: () {
                            themeProvider.setThemeMode(ThemeMode.system);
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.folder_open_outlined,
              text: s.downloadLocation,
              trailing: FutureBuilder<String>(
                  future: downloadPathProvider.getEffectiveDownloadPath(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData &&
                        snapshot.data!.isNotEmpty) {
                      String path = snapshot.data!;
                      if (path.length > 30) {
                        path = "...${path.substring(path.length - 27)}";
                      }
                      return Text(path,
                          style: TextStyle(
                              color: Theme.of(context).hintColor, fontSize: 12),
                          overflow: TextOverflow.ellipsis);
                    }
                    return Text(s.notSet,
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12));
                  }),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext sheetContext) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(s.chooseNewLocation),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _chooseDownloadLocation(
                                context, s, downloadPathProvider);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.open_in_new),
                          title: Text(s.openCurrentLocation),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            final pathProvider =
                                Provider.of<DownloadPathProvider>(context,
                                    listen: false);

                            pathProvider
                                .getEffectiveDownloadPath()
                                .then((folderPath) {
                              openFolderInListView(
                                  context: context, folderPath: folderPath);
                            });
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: Text(s.resetToDefault),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await downloadPathProvider.resetDownloadPath();
                            if (context.mounted) {
                              showAppSnackBar(context, s.downloadLocationReset,
                                  icon: Icons.check_circle_outline,
                                  iconColor: Colors.green);
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.delete_sweep_outlined,
              text: s.clearPdfCache,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(s.confirmAction),
                      content: Text(s.confirmClearCache),
                      actions: <Widget>[
                        TextButton(
                          child: Text(s.cancel),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                        ),
                        TextButton(
                          child: Text(s.clear,
                              style: const TextStyle(color: Colors.red)),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _clearInternalPdfCache(context, s);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.help_outline,
              text: s.about,
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context,
      {required AppLocalizations s,
      required IconData icon,
      required String text,
      Widget? trailing,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(text, style: const TextStyle(fontSize: 16)),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _UpdateStatusCard extends StatefulWidget {
  const _UpdateStatusCard();

  @override
  State<_UpdateStatusCard> createState() => _UpdateStatusCardState();
}

class _UpdateStatusCardState extends State<_UpdateStatusCard> {
  String? _currentVersion;
  UpdateInfo? _updateInfo;
  bool _checking = false;
  bool _applying = false;
  double _progress = 0.0;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _currentVersion = info.version);
    } catch (_) {}
  }

  Future<void> _checkForUpdates() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _updateInfo = null;
      _checked = false;
    });
    try {
      final info = await UpdateHelper.checkForUpdate();
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _checked = true;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _applyPatch(UpdateInfo info) async {
    if (_applying) return;
    setState(() {
      _applying = true;
      _progress = 0.0;
    });
    try {
      final ok = await UpdateHelper.applyPatchUpdate(info, (p) {
        if (mounted) setState(() => _progress = p.clamp(0.0, 1.0));
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Update applied successfully.' : 'Failed to apply update.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to apply update.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _openDownload(UpdateInfo info) async {
    // Always open the versions page for full updates
    final url = 'https://focus-zonee.netlify.app/versions';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch: $url')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    String statusText;
    Color statusColor = theme.textTheme.bodyMedium?.color ?? Colors.black54;
    Widget? actionRow;

    if (_checking) {
      statusText = 'Checking for updates...';
    } else if (_checked && _updateInfo == null) {
      statusText = 'Your app is up to date.';
      statusColor = Colors.green[700] ?? statusColor;
    } else if (_updateInfo == null) {
      statusText = 'Unknown - tap to check for updates';
      actionRow = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.system_update_alt),
            label: const Text('Check for updates'),
            onPressed: _checkForUpdates,
          ),
        ],
      );
    } else {
      // _updateInfo not null: either update available or up-to-date
      final info = _updateInfo!;
      if (info.updateType == UpdateType.none || info.latestVersion.isEmpty) {
        statusText = 'Your app is up to date.';
        statusColor = Colors.green[700] ?? statusColor;
      } else {
        final sizeText = UpdateHelper.getUpdateSize(info);
        if (info.isPatchUpdate) {
          statusText = 'Patch update available: v${info.latestVersion} • $sizeText';
          statusColor = Colors.orange[700] ?? statusColor;
          actionRow = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_applying) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 6),
                Text('${(_progress * 100).toStringAsFixed(0)}%', style: theme.textTheme.bodySmall),
              ] else ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.downloading),
                  label: const Text('Apply patch update'),
                  onPressed: () => _applyPatch(info),
                ),
              ],
            ],
          );
        } else {
          statusText = 'Full update available: v${info.latestVersion} • $sizeText';
          statusColor = Colors.blue[700] ?? statusColor;
          actionRow = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Visit download page'),
                onPressed: () => _openDownload(info),
              ),
            ],
          );
        }
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.primary.withOpacity(0.1),
                  child: Icon(Icons.system_update, color: color.primary),
                ),
                const SizedBox(width: 12),
                Text('Update Status', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                if (_currentVersion != null)
                  Text('${s.appVersion}: ${_currentVersion!}', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(statusText, style: theme.textTheme.bodyMedium?.copyWith(color: statusColor)),
            if (actionRow != null) ...[
              const SizedBox(height: 8),
              actionRow,
            ],
          ],
        ),
      ),
    );
  }
}

// AboutScreen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String githubUrl = 'https://github.com/waytoo-average';
  static const String discordProfileUrl =
      'https://discord.com/users/858382338281963520';
  static const String phoneNumber = '+201027658156';
  static const String emailAddress = 'belalmohamedelnemr0@gmail.com';

  Future<void> _launchUrl(BuildContext context, String url) async {
    final s = AppLocalizations.of(context);
    if (s == null) return;
    try {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showAppSnackBar(context, s.couldNotLaunchUrl(url),
              icon: Icons.link_off, iconColor: Colors.red);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, s.couldNotLaunchUrl(url),
            icon: Icons.link_off, iconColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
          title: Text(s.about),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Info Card
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.code_outlined,
                      size: 60, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 12),
                  Text(s.appTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version;
                      return Text(
                        version != null
                            ? '${s.appVersion}: $version'
                            : s.appVersion,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(s.appDescription,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Update Status Card
          const _UpdateStatusCard(),
          const SizedBox(height: 24),
          // Developer Info
          Text(s.madeBy, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8.0),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.developerName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(s.developerDetails,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Contact Info
          Text(s.contactInfo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8.0),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Column(
              children: [
                _ContactListTile(
                  icon: Icons.phone_android_outlined,
                  text: s.phoneNumber,
                  onTap: () =>
                      _launchUrl(context, 'tel:${AboutScreen.phoneNumber}'),
                ),
                const Divider(height: 1),
                _ContactListTile(
                  icon: Icons.email_outlined,
                  text: s.email,
                  onTap: () =>
                      _launchUrl(context, 'mailto:${AboutScreen.emailAddress}'),
                ),
                const Divider(height: 1),
                _ContactListTile(
                  asset: 'assets/icons/github.png',
                  text: s.githubProfile,
                  onTap: () => _launchUrl(context, AboutScreen.githubUrl),
                ),
                const Divider(height: 1),
                _ContactListTile(
                  asset: 'assets/icons/discord.png',
                  text: s.discordProfile,
                  onTap: () =>
                      _launchUrl(context, AboutScreen.discordProfileUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactListTile extends StatelessWidget {
  final IconData? icon;
  final String? asset;
  final String text;
  final VoidCallback onTap;
  const _ContactListTile(
      {this.icon, this.asset, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: Theme.of(context).primaryColor, size: 28)
          : asset != null
              ? Image.asset(asset!, width: 28, height: 28)
              : null,
      title: Text(text, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.open_in_new_outlined, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 0,
    );
  }
}

// CollegeInfoScreen
class CollegeInfoScreen extends StatelessWidget {
  const CollegeInfoScreen({super.key});
  Future<void> _launchUrl(BuildContext context, String url) async {
    final s = AppLocalizations.of(context);
    if (s == null) return;
    try {
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showAppSnackBar(context, s.couldNotLaunchUrl(url),
              icon: Icons.link_off, iconColor: Colors.red);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, s.couldNotLaunchUrl(url),
            icon: Icons.link_off, iconColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    const String facebookUrl = 'https://www.facebook.com/2018ECCAT';
    const String googleMapsUrl =
        'https://maps.app.goo.gl/xC55Rg5va37txSqC7';
    return Scaffold(
      appBar: AppBar(
          title: Text(s.aboutCollege),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Hero(
                    tag: 'collegeIcon',
                    child: Icon(Icons.school_outlined,
                        size: 80, color: Colors.indigo)),
                const SizedBox(height: 10),
                Text(s.collegeName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(s.eccatIntro,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium))
              ]),
          const Divider(height: 40, thickness: 1),
          Text(s.connectWithUs, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Card(
              child: ListTile(
            leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
            title: Text(s.facebookPage),
            trailing: const Icon(Icons.open_in_new_outlined, size: 20),
            onTap: () => _launchUrl(context, facebookUrl),
          )),
          const SizedBox(height: 10),
          Card(
              child: ListTile(
            leading: const Icon(Icons.location_on_outlined,
                color: Color(0xFFDB4437)),
            title: Text(s.collegeLocation),
            trailing: const Icon(Icons.open_in_new_outlined, size: 20),
            onTap: () => _launchUrl(context, googleMapsUrl),
          )),
          const Divider(height: 40, thickness: 1),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _OptionCard(
      {required this.title,
      required this.icon,
      required this.selected,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final borderColor =
        selected ? Theme.of(context).colorScheme.secondary : Colors.transparent;
    return Card(
      elevation: selected ? 6 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: selected ? 2 : 0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon,
                  color: selected
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).iconTheme.color),
              const SizedBox(width: 16),
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium)),
              if (selected)
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.secondary)
            ],
          ),
        ),
      ),
    );
  }
}
