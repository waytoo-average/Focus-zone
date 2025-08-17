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
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
// For permissions
// import 'package:file_picker/file_picker.dart'; // Not directly used here, but keep in pubspec if needed elsewhere
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:just_audio/just_audio.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:developer' as developer; // For logging

// Core app imports (from app_core.dart)
import 'package:app/app_core.dart';
import 'package:app/src/utils/app_animations.dart';

import 'l10n/app_localizations.dart'; // For AcademicContext, SignInProvider, DownloadPathProvider, AppLocalizations, ErrorScreen, showAppSnackBar, formatBytesSimplified

// --- Academic Content Data ---
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
        },
        'Semester 2': <String, String>{},
      },
      'Last Year': {
        'Semester 1': <String, String>{
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
        'Semester 1': <String, String>{
          'subject 1': '1MQj-05IJcT8SvTTWFmgDUDkClTHgRKLB',
          'subject 2': '1r1e01lEcQclwwnU5Vm3CBHWym7FzTrUE',
          'subject 3': '10FoYkEE3QY7RlKJi9N463EwjOQASP8Dp',
          'subject 4': '1LAE2HJx4z_pCLuzFBYMre5fPFehvN8vE',
          'subject 5': '14Qo6GNGvhT4R0RzhpKyehuYLj--A4-N4',
          'subject 6': '1yC6i4q0qmLoOZvyPo1-t02IXdavbtxTL',
          'subject 7': '1bakGQhd7GQm0psyT_LugJ0QKR2qTS5R7',
          'subject 8': '14fjnu6Lzjk-e667Mjn1EeppVs-hwwCly',
        }, //new leader foleder ids here
        'Semester 2': <String, String>{
          'subject 1': '1WxS1Baz3kXgbL9_TQ0sUXf43gg8-QFFh',
          'subject 2': '1easCQAcuYIip_CQrgAgyRDkuqQqQoEhe',
          'subject 3': '1iLyE4nyK_dr2SuOdvMlVOUpJ63vj3zK7',
          'subject 4': '1xKwj7ZZWygqIsx4w_gNeVIw9s5LT0JOd',
          'subject 5': '1OZimdoorHXKXUw_mkQzzKLUvqrnuH5T4',
          'subject 6': '11odjzKZfzE_LocHlPVlbHBD4aX7gv-bS',
          'subject 7': '1KFZVXYKCK8mgAYgQHwAwbUMRapbl3PKY',
          'subject 8': '1zsS4MOx2XNBr71ICT8kJPMhLJJGYYkw4',
        },
      },
      'Last Year': {
        'Semester 1': <String, String>{
          'Advanced Applications': '1uUVlSCePNIdodWrEse09syRa1GG8CuWX',
          'C': '1MvfdtvfgEYHuYnnBoq7dQd4_cgST-lKF',
          'chinese': '1R8bkpCpeFE2RZkvsRB_oBJ6XTmhMSclE',
          'communication system': '1ViffWHEGFhcPZHScw-9TgszMtQvM5-AR',
          'digital': '1ywJQBhI6rZrTloOxZ-wRUYP76A1zUOqQ',
          'English': '1sMw6xH-xe8zroik167iIz4qAEXDu7l5V',
        },
        'Semester 2': <String, String>{
          'Chinese': '17MkwuLxXrBWBSYU3n5kMa8cv_dkTCDfc',
          'English': '1qchN-Frn_bTsgg3qbh9A5fqkhhrhwVNO',
          'java OOP': '1S-qA_xFsTdIEHNKSOntoq3DWiQCCa4s4',
          'Network Database Technology': '1GK_h9zOwF3uB0Cy0XDvdWw3s3bJtnHPU',
          'Network Interconnection Technology':
              '1jG0LMY-Q15woS1STcwNnUWkRZHmtTOXC',
          'Program-Controlled Exchange Technology':
              '1Q3JMqUc7eK8E8xgDTuUnIJCAWS84BK_V',
          'Technical Reporting': '18qibQHXeM9_MRdRm59YVdeD17H4Rnase',
        },
      },
    },
    'Electronics': {
      'Current Year': {
        'Semester 1': <String, String>{
          'subject 1': '1iOJ0ETCqhj2nIhc0h179AjZlZ5oPkYqz',
          'subject 2': '1svxPImxZrdEsOm--RQXwbqYObX1VW-v2',
          'subject 3': '1H2gtWG-MQeGLSPtY7vYHDrmcj8eXwoIi',
          'subject 4': '1WYVGZxZ0jdsyMTwI7GDLlYYwTEfMSFRx',
          'subject 5': '1GhUWe7m0VpQaxlbXrWFj9znP7Qit3tWk',
          'subject 6': '1orZz64rngJJi1IZ9EQGztT8r0nBmK88n',
          'subject 7': '1kicMvcE8u1fut1dxZA1MLsEMBKaCLa_P',
          'subject 8': '1ZMnQQR85LUBAM6TqjM9PDSyUSMGJ4W-4',
        },
        'Semester 2': <String, String>{
          'subject 1': '1PA95APyrhecOPvpEvxsoU5uux2ns7B2o',
          'subject 2': '1_k7i9QbC65r7NffmMAwrE2KbXnQxU48z',
          'subject 3': '1TUo0JfIg3HsdssH_S46D5g3VVz3sP5Qx',
          'subject 4': '1jjuS1-FfkibE8Lx9pUJnjRnPuZAzPiaq',
          'subject 5': '1hgIHx1w3aoqCVVXuZw7ntk5ZJY-wPUW4',
          'subject 6': '1yRfwMufuKDTxgTvHNUYJTELJi7_11F1B',
          'subject 7': '1bARI-uvsVH46p432NcT5tkv3V6Q174T6',
          'subject 8': '1t6ehIUH0LzdydIO6roidy3-9YZE6VNTK',
        },
      },
      'Last Year': {
        'Semester 1': <String, String>{},
        'Semester 2': <String, String>{},
      },
    },
    'Mechatronics': {
      'Current Year': {
        'Semester 1': <String, String>{
          'subject 1': '1dzvDKk7PFM2ofHFQm0Dua2IrV6j1Exyw',
          'subject 2': '1yeAefe-opHqtm_z1I9lwAFuztr_g7n6C',
          'subject 3': '17CLjvYJnSXXjVcIriEzvHYZNClDQT9VW',
          'subject 4': '1IgYAuayak_21JZDq-57xdVLPYelBhxMq',
          'subject 5': '1GCgqQqKul3P3LAP9LFuoXvoAZzmrJvp1',
          'subject 6': '1A4pjnedpCZ_pzWyH5cIJQ93Q7ASuaxEM',
          'subject 7': '1loR8DU7yomX7ap-mg5V0GaatyJW_eIJX',
          'subject 8': '1FYw2SH4q4GlzU-gUfsQcgnM02hT5p5vS',
        },
        'Semester 2': <String, String>{
          'subject 1': '1iFl8GYbzaJsBrVJPp5ACoqtP721Zh8IX',
          'subject 2': '1WCyNnJQQhui2RfDjghJGxVN26g2z42kR',
          'subject 3': '1Y6IbeSMr1ZZ19sxQMf3hNQJrNNN7PbhF',
          'subject 4': '11BAOvLGkGu3hueip6a2XtAscnsk2G0BW',
          'subject 5': '11KEcex13uDZA6AB0MS35lpwr9B5jqCmX',
          'subject 6': '1Er8HI-EYagYmFfD-w71kifoNLeDf1ofW',
          'subject 7': '1FvR-6xrXSzJ8Za_1SnkLAMPwMvlp628c',
          'subject 8': '1Hdo8NkAJ49_Af4riOOBTPiY3tCzt4Z1O',
        },
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
        'Semester 1': <String, String>{
          'broadband': '1aisZwaK65RJi_BPfj_E6hR-TZ0sKeR6p',
          'chinese': '19TZyvCl92HH5DMf4mprO59tm-gta91wL',
          'Communiction network': '1prylDZjqSTrY-BlEI4pXJrzAjbYi0Dq8',
          'Linux': '1_8-fAa_nBudeiKwry4LR-JWIciMxWjUF',
          'NGN': '17ERpI6NTPjXadcc3QsrjmqUAVf4YdRBO',
          'website': '1tN_z_WgmXpxohPoAvHqvtTnd3iQX0YA0',
          'الصحه والسلامه': '1kUks0v7IC5n4q4FMaAuH1QjAVQpvKNIG',
        },
        'Semester 2': <String, String>{
          'cable': '1vMU9TLYEMjjLZKGyAhc7WsUxfhA3a8H3',
          'mobile': '1Dxx-GjuzsrUfeGgKAmFYIDjds4QgCL9q',
          'security': '1tUe7OcIJNxrg8pGJuOSmkJfxC7oAVsx3',
          'switching': '1Vm9NvUiqs_uBflCX-iQSrTXNt84a21It',
          'wireless': '1vY9KfmZVRIdQow7iGOA2SP2jzn_rJr06',
          'التفكير المهني': '1G6PCmt3Ff7VGqJgp1NW7y9rNAx24s3wO',
        },
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

// --- Grade Selection UI ---
// GradeSelectionScreen - NO LONGER HAS ITS OWN SCAFFOLD OR APPBAR
class GradeSelectionScreen extends StatelessWidget {
  const GradeSelectionScreen({super.key});
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
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StaggeredListView(
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
    final theme = Theme.of(context);
    final Map<String, String> semester1Subjects = _getSubjectsForContext(
        context, academicContext.copyWith(semester: s.semester1));
    final Map<String, String> semester2Subjects = _getSubjectsForContext(
        context, academicContext.copyWith(semester: s.semester2));

    final bool hasSem1 = semester1Subjects.isNotEmpty;
    final bool hasSem2 = semester2Subjects.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 2),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: (!hasSem1 && !hasSem2)
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
                      title:
                          Text(s.semester1, style: theme.textTheme.titleMedium),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/subjects',
                          arguments: {
                            'subjects': semester1Subjects,
                            'context':
                                academicContext.copyWith(semester: s.semester1),
                          },
                        );
                      },
                    ),
                  ),
                if (hasSem2)
                  Card(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    child: ListTile(
                      title:
                          Text(s.semester2, style: theme.textTheme.titleMedium),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/subjects',
                          arguments: {
                            'subjects': semester2Subjects,
                            'context':
                                academicContext.copyWith(semester: s.semester2),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(academicContext.titleString, softWrap: true, maxLines: 3),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
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
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectContentScreen(
                            subjectName: entry.key,
                            rootFolderId: entry.value,
                            academicContext: academicContext,
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
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        elevation: theme.appBarTheme.elevation,
        backgroundColor: theme.appBarTheme.backgroundColor,
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
                Consumer<SignInProvider>(
                  builder: (context, signInProvider, child) {
                    if (signInProvider.currentUser == null) {
                      return ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        onPressed: () =>
                            signInProvider.signInWithErrorHandling(context),
                        label: Text(s?.signIn ?? 'Sign In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
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
                  : const Center(child: Text('Video player not available')),
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
                                Theme.of(context).primaryColor.withOpacity(0.1),
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
                          child: const Text('Open with external app'),
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
                  child: const Text('Open with external app'),
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

    final signInProvider = Provider.of<SignInProvider>(context, listen: false);
    final http.Client? authenticatedClient =
        await signInProvider.authenticatedHttpClient;

    if (!mounted) return;

    if (authenticatedClient == null) {
      if (mounted) {
        setState(() {
          _error = s!.notSignedInClientNotAvailable;
          _offlineMode = true;
          _isLoading = false;
        });
      }
      // Attempt to show any locally downloaded files for this folder
      final localFiles = await _buildLocalFilesForCurrentFolder();
      if (mounted) {
        setState(() {
          _files = localFiles;
        });
      }
      return;
    }

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

    final driveApi = drive.DriveApi(authenticatedClient);

    try {
      final String? pageToken = loadMore
          ? _globalNextPageToken[_currentFolderId!]
          : null; // null for first page

      final result = await driveApi.files.list(
        q: "'$_currentFolderId' in parents and trashed = false",
        $fields:
            'nextPageToken, files(id, name, mimeType, webViewLink, iconLink, size, modifiedTime, webContentLink)',
        orderBy: 'folder,name',
        pageToken: pageToken,
        pageSize: 50,
      );

      if (!mounted) return;

      // Merge or replace results and update global caches
      final List<drive.File> newFiles = result.files ?? <drive.File>[];

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
      _globalNextPageToken[_currentFolderId!] = result.nextPageToken;

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
          // --- Search and Sort Controls ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              const SizedBox(height: 10),
                              Consumer<SignInProvider>(
                                builder: (context, signInProvider, child) {
                                  if (signInProvider.currentUser == null) {
                                    return ElevatedButton.icon(
                                      icon: const Icon(Icons.login),
                                      onPressed: () => signInProvider
                                          .signInWithErrorHandling(context),
                                      label: Text(s?.signIn ?? 'Sign In'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
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

// --- Sort Mode Enum and Extension ---
enum _SortMode { nameAsc, nameDesc, dateAsc, dateDesc, type }

extension _SortModeStrings on AppLocalizations {
  String get sortNameAsc => sortByNameAsc ?? "A-Z";
  String get sortNameDesc => sortByNameDesc ?? "Z-A";
  String get sortDateAsc => sortByDateAsc ?? "Oldest";
  String get sortDateDesc => sortByDateDesc ?? "Newest";
  String get sortType => sortByType ?? "Type";
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
