import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'dart:io';
import 'package:pragmatic/Models/TranslationRequest.dart';
import 'package:pragmatic/Services/ApiService.dart';
class EpubReaderScreen extends StatefulWidget {
  final String filePath;
  final ApiService apiService;

  const EpubReaderScreen({super.key, required this.filePath, required this.apiService});

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
                  onTextSelected: (epubTextSelection) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.3,
                        minChildSize: 0.1,
                        maxChildSize: 0.8,
                        builder: (context, scrollController) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: ListView(
                              controller: scrollController,
                              children: [
                                Center(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 8),
                                    height: 4,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[400],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    widget.apiService.getTranslation(TranslationRequest(word: epubTextSelection.selectedText, destLang: "en")).toString(),
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                // Add more dictionary or info widgets here
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        )
      );
    }
}
