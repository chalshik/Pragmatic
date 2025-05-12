import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'dart:io';
class EpubReaderScreen extends StatefulWidget {
  final String filePath;

  const EpubReaderScreen({super.key, required this.filePath});

  @override
  _EpubReaderScreenState createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
    final epubController = EpubController();
    var textSelection = '';

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: EpubViewer(
                  epubSource: EpubSource.fromFile(File(widget.filePath)),
                  epubController: epubController,
                  displaySettings: EpubDisplaySettings(flow: EpubFlow.paginated, snap: true),
                  onChaptersLoaded: (chapters) {},
                  onEpubLoaded: () async {},
                  onRelocated: (value) {},
                  onTextSelected: (epubTextSelection) {},
                  ),
              ),
            ],
          )
        )
      );
    }
}
