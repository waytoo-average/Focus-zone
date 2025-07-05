import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class JuzViewerScreen extends StatefulWidget {
  final int juzNumber;
  final bool isWholeQuran;
  const JuzViewerScreen(
      {Key? key, required this.juzNumber, this.isWholeQuran = false})
      : super(key: key);

  @override
  State<JuzViewerScreen> createState() => _JuzViewerScreenState();
}

class _JuzViewerScreenState extends State<JuzViewerScreen> {
  List<File> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    final dir = await getApplicationDocumentsDirectory();
    final targetDir = widget.isWholeQuran
        ? Directory('${dir.path}/quran_full')
        : Directory('${dir.path}/quran_juz_${widget.juzNumber}');
    if (targetDir.existsSync()) {
      final files = targetDir
          .listSync()
          .whereType<File>()
          .where((f) =>
              f.path.endsWith('.jpg') ||
              f.path.endsWith('.jpeg') ||
              f.path.endsWith('.png'))
          .toList();

      // Sort files properly based on page numbers
      files.sort((a, b) {
        final aPage = _extractPageNumber(a.path);
        final bPage = _extractPageNumber(b.path);
        return aPage.compareTo(bPage);
      });

      setState(() {
        _images = files;
        _loading = false;
      });
    } else {
      setState(() {
        _images = [];
        _loading = false;
      });
    }
  }

  // Extract page number from filename
  int _extractPageNumber(String filePath) {
    final fileName = filePath.split('/').last;
    final nameWithoutExt = fileName.split('.').first;

    // Handle the specific format: big-quran_Page_001
    final pageMatch =
        RegExp(r'Page_(\d+)', caseSensitive: false).firstMatch(nameWithoutExt);
    if (pageMatch != null) {
      return int.tryParse(pageMatch.group(1) ?? '0') ?? 0;
    }

    // Fallback: try to extract any numbers from the filename
    final numbers = RegExp(r'\d+').allMatches(nameWithoutExt);
    if (numbers.isNotEmpty) {
      // Use the first number found as page number
      return int.tryParse(numbers.first.group(0) ?? '0') ?? 0;
    }

    // Final fallback to alphabetical sorting if no numbers found
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.isWholeQuran ? 'Full Quran' : 'Juz ${widget.juzNumber}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _images.isEmpty
              ? const Center(child: Text('No images found for this Juz.'))
              : PhotoViewGallery.builder(
                  itemCount: _images.length,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: FileImage(_images[index]),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 3.0,
                    );
                  },
                  scrollPhysics: const BouncingScrollPhysics(),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.black),
                  pageController: PageController(),
                  reverse: true,
                ),
    );
  }
}
