// Imports specific to Settings features
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
import 'package:shared_preferences/shared_preferences.dart'; // For clearing cache
import 'package:path_provider/path_provider.dart'; // For clearing cache
import 'dart:io'; // For File operations
import 'package:open_filex/open_filex.dart'; // For opening download folder
import 'package:permission_handler/permission_handler.dart'; // For permissions
import 'dart:developer' as developer; // For logging
import 'package:file_picker/file_picker.dart'; // NEW: For choosing download location

// Core app imports (from app_core.dart)
import 'package:app/app_core.dart';

import 'l10n/app_localizations.dart'; // For AppLocalizations, SignInProvider, ThemeProvider, LanguageProvider, DownloadPathProvider, showAppSnackBar


// 11. Settings Screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearInternalPdfCache(BuildContext context, AppLocalizations s) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      int count = 0;
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = await dir.list().toList();
        for (FileSystemEntity entity in entities) {
          if (entity is File && entity.path.endsWith('.pdf') && entity.path.split('/').last.startsWith('pdf_cache_')) {
            await entity.delete();
            count++;
            developer.log("Deleted cached PDF: ${entity.path}", name: "SettingsScreen");
          }
        }
      }
      if (context.mounted) {
        showAppSnackBar(context, s.cacheClearedItems(count), icon: Icons.check_circle_outline, iconColor: Colors.green);
      }
    } catch (e) {
      developer.log("Error clearing cache: $e", name: "SettingsScreen");
      if (context.mounted) {
        showAppSnackBar(context, s.cacheClearFailed(e.toString()), icon: Icons.error_outline, iconColor: Colors.red);
      }
    }
  }

  // Modified function to open app-specific download path directly
  Future<void> _openAppDownloadPath(BuildContext context, AppLocalizations s, DownloadPathProvider pathProvider) async {
    if (!context.mounted) return;

    // Request permissions using the centralized method
    bool granted = await pathProvider.requestStoragePermissions(context, s);
    if (!granted) {
      developer.log("Permission not granted for opening download folder.", name: "SettingsScreen");
      // The showAppSnackBar inside requestStoragePermissions already guides the user.
      return; // Stop if permissions are not granted
    }

    final String currentDownloadPath = await pathProvider.getEffectiveDownloadPath();
    final String appDefaultDownloadPath = await pathProvider.getAppSpecificDownloadPath(); // Get the app's default path

    developer.log("Attempting to open path: $currentDownloadPath", name: "SettingsScreen");
    try {
      final result = await OpenFilex.open(currentDownloadPath);
      if (result.type != ResultType.done) {
        developer.log("Failed to open chosen folder: ${result.message}", name: "SettingsScreen");
        if (context.mounted) {
          // If user's chosen folder failed to open, try opening app's default download folder instead
          showAppSnackBar(
            context,
            s.couldNotOpenChosenFolder(result.message ?? 'Unknown error'), // New localization key
            icon: Icons.folder_off_outlined,
            iconColor: Colors.red,
            duration: const Duration(seconds: 7), // Give user time to read
          );
          // Fallback: try to open the app's default download folder
          if (currentDownloadPath != appDefaultDownloadPath) {
            developer.log("Attempting to open app's default download folder as fallback: $appDefaultDownloadPath", name: "SettingsScreen");
            final fallbackResult = await OpenFilex.open(appDefaultDownloadPath);
            if (fallbackResult.type != ResultType.done && context.mounted) {
              showAppSnackBar(context, s.couldNotOpenDefaultFolder, icon: Icons.folder_off_outlined, iconColor: Colors.red); // New localization key
            }
          }
        }
      }
    } catch (e) {
      developer.log("Could not open download folder (exception): $e", name: "SettingsScreen");
      if (context.mounted) {
        showAppSnackBar(context, s.couldNotOpenFolder(e.toString()), icon: Icons.folder_off_outlined, iconColor: Colors.red);
      }
    }
  }

  // NEW: Function to pick a new download location
  Future<void> _chooseDownloadLocation(BuildContext context, AppLocalizations s, DownloadPathProvider pathProvider) async {
    if (!context.mounted) return;

    // Request permissions using the centralized method
    bool granted = await pathProvider.requestStoragePermissions(context, s);
    if (!granted) {
      developer.log("Permission not granted for choosing download location.", name: "SettingsScreen");
      // The showAppSnackBar inside requestStoragePermissions already guides the user.
      return; // Stop if permissions are not granted
    }

    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null && context.mounted) {
        await pathProvider.setCustomDownloadPath(selectedDirectory);
        showAppSnackBar(context, s.downloadLocationUpdated(selectedDirectory), icon: Icons.check_circle_outline, iconColor: Colors.green);
      } else if (context.mounted) {
        showAppSnackBar(context, s.noLocationSelected);
      }
    } catch (e) {
      developer.log("Error picking download location: $e", name: "SettingsScreen");
      if (context.mounted) {
        showAppSnackBar(context, s.failedToSetDownloadLocation(e.toString()), icon: Icons.error_outline, iconColor: Colors.red);
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
      return Scaffold(appBar: AppBar(title: const Text("Settings")), body: const Center(child: CircularProgressIndicator()));
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
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  radius: 40,
                  child: user.photoUrl == null
                      ? Text(
                    user.displayName?.isNotEmpty == true
                        ? user.displayName![0].toUpperCase()
                        : (user.email.isNotEmpty == true ? user.email[0].toUpperCase() : '?'),
                    style: const TextStyle(fontSize: 30),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  user.displayName ?? user.email ?? s.unknownUser,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  user.email,
                  style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: user == null ? signInProvider.signIn : signInProvider.signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: user == null ? Theme.of(context).primaryColor : Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                icon: Icons.language,
                text: s.chooseLanguage,
                trailing: Text(
                    languageProvider.locale.languageCode == 'en' ? s.english : s.arabic,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                ),
                onTap: () {
                  showDialog(context: context, builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(s.chooseLanguage),
                      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        RadioListTile<Locale>(title: Text(s.english), value: const Locale('en'), groupValue: languageProvider.locale, onChanged: (Locale? value) { if (value != null) { languageProvider.setLocale(value); Navigator.of(dialogContext).pop(); } }),
                        RadioListTile<Locale>(title: Text(s.arabic), value: const Locale('ar'), groupValue: languageProvider.locale, onChanged: (Locale? value) { if (value != null) { languageProvider.setLocale(value); Navigator.of(dialogContext).pop(); } }),
                      ],
                      ),
                    );
                  },
                  );
                }
            ),
            _buildSettingsItem(
                context,
                s: s,
                icon: Icons.brightness_6_outlined,
                text: s.chooseTheme,
                trailing: Text(
                    themeProvider.themeMode == ThemeMode.light ? s.lightTheme :
                    themeProvider.themeMode == ThemeMode.dark ? s.darkTheme :
                    s.systemDefault,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))
                ),
                onTap: () {
                  showDialog(context: context, builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: Text(s.chooseTheme),
                      content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                        RadioListTile<ThemeMode>(title: Text(s.lightTheme), value: ThemeMode.light, groupValue: themeProvider.themeMode, onChanged: (ThemeMode? value) { if (value != null) { themeProvider.setThemeMode(value); Navigator.of(dialogContext).pop(); } }),
                        RadioListTile<ThemeMode>(title: Text(s.darkTheme), value: ThemeMode.dark, groupValue: themeProvider.themeMode, onChanged: (ThemeMode? value) { if (value != null) { themeProvider.setThemeMode(value); Navigator.of(dialogContext).pop(); } }),
                        RadioListTile<ThemeMode>(title: Text(s.systemDefault), value: ThemeMode.system, groupValue: themeProvider.themeMode, onChanged: (ThemeMode? value) { if (value != null) { themeProvider.setThemeMode(value); Navigator.of(dialogContext).pop(); } }),
                      ],
                      ),
                    );
                  },
                  );
                }
            ),
            _buildSettingsItem(
              context,
              s: s,
              icon: Icons.folder_open_outlined,
              text: s.downloadLocation,
              trailing: FutureBuilder<String>(
                  future: downloadPathProvider.getEffectiveDownloadPath(),
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data!.isNotEmpty){
                      String path = snapshot.data!;
                      if(path.length > 30) path = "...${path.substring(path.length - 27)}";
                      return Text(path, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12), overflow: TextOverflow.ellipsis);
                    }
                    return Text(s.notSet, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12));
                  }
              ),
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
                            _chooseDownloadLocation(context, s, downloadPathProvider);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.open_in_new),
                          title: Text(s.openCurrentLocation),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _openAppDownloadPath(context, s, downloadPathProvider);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.refresh),
                          title: Text(s.resetToDefault),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await downloadPathProvider.resetDownloadPath();
                            showAppSnackBar(context, s.downloadLocationReset, icon: Icons.check_circle_outline, iconColor: Colors.green);
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
                          child: Text(s.clear, style: const TextStyle(color: Colors.red)),
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
          ].map((item) => Padding(padding: const EdgeInsets.only(bottom: 0), child: item)).toList(),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required AppLocalizations s, required IconData icon, required String text, Widget? trailing, required VoidCallback onTap}) {
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

// AboutScreen
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String githubUrl = 'https://github.com/waytoo-average';
  static const String discordProfileUrl = 'https://discord.com/users/858382338281963520';
  static const String linkedinUrl = 'https://www.linkedin.com/in/belal-elnemr-94073322b/';
  static const String xUrl = 'https://twitter.com/BelalElNmer';
  static const String instagramUrl = 'https://www.instagram.com/belal_e_l_nemr/';
  static const String facebookUrl = 'https://www.facebook.com/belal.elnmr/';
  static const String appCurrentVersion = '0.1.3';
  static const String phoneNumber = '+201026027552';
  static const String emailAddress = 'belal.elnemr.work@gmail.com';


  Future<void> _launchUrl(BuildContext context, String url) async {
    final s = AppLocalizations.of(context);
    if (s == null) return;
    try {
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final Color? iconColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: Text(s.about), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Icon(Icons.code_outlined, size: 80, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(s.appTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 5),
            Text('${s.appVersion}: ${AboutScreen.appCurrentVersion}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(s.appDescription, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall))
          ]),
          const Divider(height: 40, thickness: 1),
          Text(s.madeBy, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8.0), Text(s.developerName, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)), Text(s.developerDetails, style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: 40, thickness: 1),

          Text(s.contactInfo, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Material(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4.0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _launchUrl(context, 'tel:${AboutScreen.phoneNumber}'),
                    child: Tooltip(
                      message: s.phoneNumber,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: Icon(Icons.phone_android_outlined, size: 30, color: iconColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Material(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4.0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _launchUrl(context, 'mailto:${AboutScreen.emailAddress}'),
                    child: Tooltip(
                      message: s.email,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: Icon(Icons.email_outlined, size: 30, color: iconColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Material(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4.0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _launchUrl(context, AboutScreen.githubUrl),
                    child: Tooltip(
                      message: s.githubProfile,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: Image.asset('assets/icons/github.png', width: 30, height: 30, color: iconColor),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Material(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  elevation: 4.0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _launchUrl(context, AboutScreen.discordProfileUrl),
                    child: Tooltip(
                      message: s.discordProfile,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Center(
                          child: Image.asset('assets/icons/discord.png', width: 30, height: 30, color: iconColor),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 40, thickness: 1),
        ],
      ),
    );
  }
}

// CollegeInfoScreen
class CollegeInfoScreen extends StatelessWidget {
  const CollegeInfoScreen({super.key});
  Future<void> _launchUrl(BuildContext context, String url) async {
    final s = AppLocalizations.of(context);
    if (s == null) return;
    try { if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) { if (context.mounted) showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red); }
    } catch (e) { if (context.mounted) showAppSnackBar(context, s.couldNotLaunchUrl(url), icon: Icons.link_off, iconColor: Colors.red); }
  }
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    const String facebookUrl = 'https://www.facebook.com/2018ECCAT';
    const String googleMapsUrl = 'https://maps.app.goo.gl/MTtsxuok1c5gteMw8';
    return Scaffold(
      appBar: AppBar(title: Text(s.aboutCollege), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Hero(tag: 'collegeIcon', child: Icon(Icons.school_outlined, size: 80, color: Colors.indigo)),
            const SizedBox(height: 10),
            Text(s.collegeName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Text(s.eccatIntro, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium))
          ]),
          const Divider(height: 40, thickness: 1),
          Text(s.connectWithUs, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16),
          Card(child: ListTile(
            leading: const Icon(Icons.facebook, color: Color(0xFF1877F2)),
            title: Text(s.facebookPage),
            trailing: const Icon(Icons.open_in_new_outlined, size: 20),
            onTap: () => _launchUrl(context, facebookUrl),
          )),
          const SizedBox(height:10),
          Card(child: ListTile(
            leading: const Icon(Icons.location_on_outlined, color: Color(0xFFDB4437)),
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