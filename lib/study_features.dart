// Imports specific to study features
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:googleapis/drive/v3.dart' as drive; // aliased as drive
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // For File operations
import 'package:intl/intl.dart'; // For date formatting
import 'package:permission_handler/permission_handler.dart'; // For permissions
// import 'package:file_picker/file_picker.dart'; // Not directly used here, but keep in pubspec if needed elsewhere
import 'package:open_filex/open_filex.dart'; // For opening files
import 'dart:developer' as developer; // For logging

// Core app imports (from app_core.dart)
import 'package:app/app_core.dart';

import 'l10n/app_localizations.dart'; // For AcademicContext, SignInProvider, DownloadPathProvider, AppLocalizations, ErrorScreen, showAppSnackBar, formatBytesSimplified

// Centralized data structure for all academic content
// Structure: Grade -> Department -> Year -> Semester -> SubjectName: FolderId
// The type needs to reflect the nesting of maps correctly.
const Map<String, Map<String, Map<String, Map<String, Map<String, String>>>>>
    allAcademicContentFolders = {
  'First Grade': {
    // Grade
    'Communication': {
      // Department
      'Current Year': {
        // Year
        'Semester 1': <String, String>{
          // Semester (Map<String, String> for subjects)
          'علم جودة': '1-ESboU85nTtO2FYMbiZZeNn3Anv6aH0',
          'تدريب تقني كهرباء': '1psr8ylukgFsqhW9v1CZkLpWaPaE-8MnL',
          'physics': '11LAt7VWyJB_NJtR-Q6u6btUfNY6uEpEx',
          'math': '11ag3IGjyezZouQO1tOyhaCeEbQLGND2t',
          'English': '11Kn1lg8qTyFFBa4ZQStnQYzzdLeAJYjl',
          'circuit': '11ZIekUHxVXriF1w2lC5dYSf3u8yCmeIt',
          'chinese': '12v8ywEq9-RMVhOvORwc3DGpkswRsBlLb',
          'it': '11cD7TV1sHuaK1QRYRrU8UB62Zye_i3mQ'
        },
        'Semester 2': <String, String>{
          'قضايا مجتمعية': '1wyuL_okkhbtFHNcSkKzXvc-wK7G420wj',
          'علوم حاسب': '14VYnkax5I9hXgaExRXYWQaz6mWlg59l3',
          'تصميم دوائر الاتصالات': '1mFSHV7BPzUoaf7AuFssGFL6mtNIzz4s',
          'اساسيات تكنولوجيا الشبكات': '1-y8Wk3Aa5G_WyyHCdIY_GP2XGDNbNTGi',
          'Math': '19o4N4Jb_9w12M_oVzC400L_K7G720wj',
          'English': '1D0Ps6mw5qY21jRuGVm5a_s1UZJwvPK8',
          'Communication Circuit Technology':
              '1ZyeUwHOoxAw2DisIFc5pGFJJ57Gy49hv',
          'Chinese': '14tYcv7b3zfvohazvVDElaJrcJafldeg4'
        },
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Electronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Mechatronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
  },
  'Second Grade': {
    'Communication': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Electronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Mechatronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
  },
  'Third Grade': {
    'Communication': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Electronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Mechatronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
  },
  'Fourth Grade': {
    'Communication': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Electronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Mechatronics': {
      'Current Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
  },
};

// GradeSelectionScreen - NO LONGER HAS ITS OWN SCAFFOLD OR APPBAR
class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Column(
      children: [
        AppBar(
          title: Text(s.appTitle),
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                    onPressed: () => Future.microtask(() =>
                        Navigator.of(context).pushNamed('/departments',
                            arguments: AcademicContext(grade: s.firstGrade))),
                    child: Text(s.firstGrade)),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () => Future.microtask(() =>
                        Navigator.of(context).pushNamed('/departments',
                            arguments: AcademicContext(grade: s.secondGrade))),
                    child: Text(s.secondGrade)),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () => Future.microtask(() =>
                        Navigator.of(context).pushNamed('/departments',
                            arguments: AcademicContext(grade: s.thirdGrade))),
                    child: Text(s.thirdGrade)),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () => Future.microtask(() =>
                        Navigator.of(context).pushNamed('/departments',
                            arguments: AcademicContext(grade: s.fourthGrade))),
                    child: Text(s.fourthGrade)),
              ],
            ),
          ),
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(departmentOptions.length, (index) {
            final String localizedDepartment = departmentOptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/years',
                      arguments: academicContext.copyWith(
                          department: localizedDepartment)),
                  child: Text(localizedDepartment)),
            );
          }),
        ),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop()),
        actions: [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(yearOptions.length, (index) {
            final String localizedYear = yearOptions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/semesters',
                      arguments: academicContext.copyWith(year: localizedYear)),
                  child: Text(localizedYear)),
            );
          }),
        ),
      ),
    );
  }
}

// SemesterSelectionScreen
class SemesterSelectionScreen extends StatelessWidget {
  final AcademicContext academicContext;
  const SemesterSelectionScreen({super.key, required this.academicContext});

  Map<String, String> _getSubjectsForContext(
      BuildContext context, AcademicContext contextToLookup) {
    final String? canonicalGrade = contextToLookup.getCanonicalGrade(context);
    final String? canonicalDepartment =
        contextToLookup.getCanonicalDepartment(context);
    final String? canonicalYear = contextToLookup.getCanonicalYear(context);
    final String? canonicalSemester =
        contextToLookup.getCanonicalSemester(context);

    if (canonicalGrade == null ||
        canonicalDepartment == null ||
        canonicalYear == null ||
        canonicalSemester == null) {
      developer.log(
          'Incomplete Canonical AcademicContext for subject lookup: $contextToLookup',
          name: 'SemesterSelectionScreen');
      return {};
    }

    final Map<String, Map<String, Map<String, Map<String, String>>>>? gradeMap =
        allAcademicContentFolders[canonicalGrade];
    final Map<String, Map<String, Map<String, String>>>? departmentMap =
        gradeMap?[canonicalDepartment];
    final Map<String, Map<String, String>>? yearMap =
        departmentMap?[canonicalYear];
    final Map<String, String>? semesterMap = yearMap?[canonicalSemester];

    return semesterMap ?? {};
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;

    final Map<String, String> semester1Subjects = _getSubjectsForContext(
        context, academicContext.copyWith(semester: s.semester1));
    final Map<String, String> semester2Subjects = _getSubjectsForContext(
        context, academicContext.copyWith(semester: s.semester2));

    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/subjects',
                    arguments: {
                      'subjects': semester1Subjects,
                      'context':
                          academicContext.copyWith(semester: s.semester1),
                    },
                  );
                },
                child: Text(s.semester1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/subjects',
                    arguments: {
                      'subjects': semester2Subjects,
                      'context':
                          academicContext.copyWith(semester: s.semester2),
                    },
                  );
                },
                child: Text(s.semester2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SubjectSelectionScreen
class SubjectSelectionScreen extends StatelessWidget {
  final Map<String, String> subjects;
  final AcademicContext academicContext;
  const SubjectSelectionScreen(
      {super.key, required this.subjects, required this.academicContext});
  @override
  Widget build(BuildContext context) {
    final List<MapEntry<String, String>> subjectsList =
        subjects.entries.toList();
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 3),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            if (subjectsList.isEmpty)
              Expanded(
                  child: Center(
                      child: Text(s.notAvailableNow,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color))))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: subjectsList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 20),
                  itemBuilder: (context, index) {
                    final subjectName = subjectsList[index].key;
                    final rootFolderId = subjectsList[index].value;
                    return ElevatedButton(
                        onPressed: () => Navigator.pushNamed(
                                context, '/subjectContentScreen',
                                arguments: {
                                  'subjectName': subjectName,
                                  'rootFolderId': rootFolderId,
                                  'academicContext': academicContext.copyWith(
                                      subjectName: subjectName)
                                }),
                        child: Text(subjectName));
                  },
                ),
              ),
          ],
        ),
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
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LectureFolderBrowserScreen(
                        initialFolderId: rootFolderId,
                      ),
                    ),
                  );
                },
                child: Text(s.lectures)),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => showAppSnackBar(
                    context, s.explanationContentNotAvailable(subjectName),
                    icon: Icons.info_outline),
                child: Text(s.explanation)),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => showAppSnackBar(
                    context, s.summariesContentNotAvailable(subjectName),
                    icon: Icons.info_outline),
                child: Text(s.summaries)),
          ],
        ),
      ),
    );
  }
}

// PDF Viewer Screen
class PdfViewerScreen extends StatefulWidget {
  final String? fileUrl;
  final String fileId;
  final String? fileName;

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.fileId,
    this.fileName,
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
          // Ensure mounted before setState
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

    if (widget.fileId.isNotEmpty) {
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
                  )
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

  const LectureFolderBrowserScreen({super.key, this.initialFolderId});

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

  bool _isSelectionMode = false;
  final Set<drive.File> _selectedFiles =
      <drive.File>{}; // Store full File objects for details

  Map<String, double> _downloadProgressMap =
      {}; // fileId -> progress (0.0 to 1.0)
  Map<String, CancelToken> _cancelTokens = {}; // fileId -> CancelToken
  bool _isDownloadingMultiple = false;

  @override
  void initState() {
    super.initState();
    _currentFolderId = widget.initialFolderId;
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

    final signInProvider = Provider.of<SignInProvider>(context, listen: false);

    if (signInProvider.currentUser != null &&
        (_files == null && _error == null ||
            (_error != null && _error == s?.notSignedInClientNotAvailable))) {
      // Added null-aware operator for s
      _fetchDriveFiles();
    } else if (signInProvider.currentUser == null && mounted && s != null) {
      if (_isLoading) {
        setState(() {
          _error = s!.notSignedInClientNotAvailable;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    final signInProvider = Provider.of<SignInProvider>(context, listen: false);
    if (mounted) {
      // Ensure mounted before setState
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    await signInProvider.signIn();
    if (!mounted) return; // Added mounted check after await
    if (signInProvider.currentUser != null && mounted) {
      // Ensure mounted before accessing context and setState
      _fetchDriveFiles();
    } else if (signInProvider.currentUser == null && mounted && s != null) {
      setState(() {
        _error = s!.notSignedInClientNotAvailable;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDriveFiles() async {
    if (!mounted) return;

    if (s == null) {
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _error = AppLocalizations.of(context)?.error ??
              "Localization service not available.";
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isSelectionMode = false; // Reset selection on refresh/navigation
      _selectedFiles.clear();
    });

    final signInProvider = Provider.of<SignInProvider>(context,
        listen: false); // Safe, listen: false
    final http.Client? authenticatedClient =
        await signInProvider.authenticatedHttpClient;

    if (!mounted) return; // Added mounted check after await

    if (authenticatedClient == null) {
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _error = s!.notSignedInClientNotAvailable;
          _isLoading = false;
        });
      }
      return;
    }

    if (_currentFolderId == null) {
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _error = s!.errorMissingFolderId;
          _isLoading = false;
        });
      }
      return;
    }

    final driveApi = drive.DriveApi(authenticatedClient);

    try {
      final result = await driveApi.files.list(
        q: "'$_currentFolderId' in parents and trashed = false",
        $fields:
            'files(id, name, mimeType, webViewLink, iconLink, size, modifiedTime, webContentLink)', // Added webContentLink for direct download
        orderBy: 'folder,name',
      );

      if (!mounted) return; // Added mounted check after await

      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _files = result.files;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        // Ensure mounted before setState
        setState(() {
          _error = s!.failedToLoadFiles(e.toString());
          _isLoading = false;
        });
      }
      developer.log('Error fetching Drive files: $e',
          name: 'LectureFolderBrowser');
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
            ),
          ),
        );
      } else {
        if (file.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s!.errorFileIdMissing)),
          );
          return;
        }

        if (file.name?.toLowerCase().endsWith('.pdf') == true) {
          final String directPdfUrl =
              'https://drive.google.com/uc?export=download&id=${file.id!}';
          Navigator.pushNamed(
            context,
            '/pdfViewer',
            arguments: {
              'fileUrl': directPdfUrl,
              'fileId': file.id!,
              'fileName': file.name,
            },
          );
        } else if (file.webViewLink != null) {
          Navigator.pushNamed(
            context,
            '/googleDriveViewer',
            arguments: {
              'embedUrl': file.webViewLink,
              'fileId': file.id, // Pass fileId for recent files
              'fileName': file.name, // Pass fileName for recent files
              'mimeType': file.mimeType, // Pass mimeType for recent files
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s!.cannotOpenFileType)),
          );
        }
      }
    }
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
              headers: (mounted &&
                      Provider.of<SignInProvider>(context, listen: false)
                              .currentUser !=
                          null)
                  ? (await Provider.of<SignInProvider>(context, listen: false)
                      .currentUser!
                      .authHeaders)
                  : {}), // Safe, check mounted
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
                label: s!.openFile, onPressed: () => OpenFilex.open(filePath)),
          );
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
                    if (Platform.isAndroid ||
                        Platform.isIOS ||
                        Platform.isMacOS ||
                        Platform.isLinux ||
                        Platform.isWindows) {
                      try {
                        await OpenFilex.open(effectiveDownloadPath);
                      } catch (e) {
                        developer.log("Could not open download folder: ${e}",
                            name: "DownloadFiles");
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
    if (!mounted || s == null) return; // Ensure mounted

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

  @override
  Widget build(BuildContext context) {
    final signInProvider = Provider.of<SignInProvider>(context);
    final user = signInProvider.currentUser;

    if (s == null) {
      return Scaffold(
          appBar: AppBar(
              title:
                  Text(AppLocalizations.of(context)?.lectures ?? "Lectures")),
          body: Center(
              child: Text(AppLocalizations.of(context)?.loadingLocalizations ??
                  "Loading localizations...")));
    }

    return Scaffold(
      backgroundColor: Theme.of(context)
          .colorScheme
          .background, // Set Scaffold background back to solid background color
      body: Column(
        // Removed Container with gradient
        children: [
          AppBar(
            // AppBar remains at the top
            title: Text(s!.lectures),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_isDownloadingMultiple) {
                  showAppSnackBar(context, s!.downloadInProgressPleaseWait);
                  return;
                }
                Navigator.pop(context);
              },
            ),
            actions: [
              if (_isSelectionMode) ...[
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed:
                      _selectedFiles.isNotEmpty && !_isDownloadingMultiple
                          ? _downloadSelectedFiles
                          : null,
                  tooltip: s!.downloadSelected,
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
                  onPressed: _isDownloadingMultiple
                      ? null
                      : (user != null ? _fetchDriveFiles : _handleSignIn),
                  tooltip: s!.refresh,
                ),
                if (user != null)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed:
                        _isDownloadingMultiple ? null : signInProvider.signOut,
                    tooltip: s!.signOut,
                  )
                else
                  TextButton(
                    onPressed: _handleSignIn,
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0)),
                    child:
                        Text(s!.signIn, style: const TextStyle(fontSize: 16)),
                  ),
              ],
            ],
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
                              if (user == null)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.login),
                                  onPressed: _handleSignIn,
                                  label: Text(s!.signInWithGoogle),
                                ),
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
                            itemCount: _files!.length,
                            itemBuilder: (context, index) {
                              final file = _files![index];
                              final bool isSelected =
                                  _selectedFiles.any((sf) => sf.id == file.id);
                              final double? progress =
                                  _downloadProgressMap[file.id];

                              return Card(
                                color: isSelected
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.2)
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
                                                if (file.id != null)
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
                                                      .withOpacity(0.6),
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
                                      trailing: !_isSelectionMode &&
                                              !_isFolder(file)
                                          ? const Icon(Icons.arrow_forward_ios,
                                              size: 16, color: Colors.grey)
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
                                                      .withOpacity(0.3)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
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
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.4)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                  ),
            ),
          ),
        ],
      ),
    );
  }
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
