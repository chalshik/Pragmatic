import 'package:flutter/material.dart';
import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'dart:io';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Models/WordEntry.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:pragmatic/Providers/SelectedDeckProvider.dart';

class EpubReaderScreen extends StatefulWidget {
  final String filePath;
  final ApiService apiService;

  const EpubReaderScreen({
    super.key,
    required this.filePath,
    required this.apiService,
  });

  @override
  _EpubReaderScreenState createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  final epubController = EpubController();
  var textSelection = '';

  String generateBackText(WordEntry wordEntry) {
    final buffer = StringBuffer();

    for (final meaning in wordEntry.meanings) {
      buffer.writeln(meaning.partOfSpeech); // e.g. noun, verb

      for (final def in meaning.definitions) {
        buffer.writeln('- ${def.definition}');
        if (def.example != null && def.example!.isNotEmpty) {
          buffer.writeln('Example: "${def.example}"');
        }
      }

      buffer.writeln(); // add a blank line between meanings
    }

    return buffer.toString().trim();
  }

  void showWordDetailBottomSheet(BuildContext context, WordEntry wordEntry) {
    // Save the current sheet context for SnackBars
    final bottomSheetContext = context;
    final word = wordEntry.word;
    final phonetic = wordEntry.phonetic;
    final audio =
        wordEntry.phonetics
            .firstWhere(
              (p) => p.audio != null && p.audio!.isNotEmpty,
              orElse: () => Phonetic(text: '', audio: ''),
            )
            .audio;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Add invisible barrier to detect taps outside sheet
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.45,
                minChildSize: 0.3,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return ScaffoldMessenger(
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 10),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // 1) Expanded list of word + phonetic + meanings
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                children: [
                                  Center(
                                    child: Text(
                                      word,
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (phonetic.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        '/$phonetic/',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (audio != null && audio.isNotEmpty) ...[
                                    SizedBox(height: 8),
                                    Center(
                                      child: IconButton(
                                        icon: Icon(Icons.volume_up),
                                        onPressed: () async {
                                          final player = AudioPlayer();
                                          await player.play(UrlSource(audio));
                                        },
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 16),
                                  // All the meaning/definition widgets (they will scroll if too long)
                                  ...wordEntry.meanings.map((meaning) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meaning.partOfSpeech,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        ...meaning.definitions.map((d) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('- ${d.definition}'),
                                                if (d.example != null &&
                                                    d.example!.isNotEmpty)
                                                  Text(
                                                    'Example: "${d.example}"',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        SizedBox(height: 12),
                                      ],
                                    );
                                  }).toList(),
                                  // Add some bottom padding so the last bit of text doesn't get hidden
                                  SizedBox(height: 12),
                                ],
                              ),
                            ),

                            // 2) Fixed "Create card" button at the bottom
                            ElevatedButton(
                              onPressed: () async {
                                print('Create card button pressed');

                                // Get data needed for API call
                                final deckId =
                                    Provider.of<SelectedDeckProvider>(
                                      context,
                                      listen: false,
                                    ).selectedDeck?.id;
                                print('Selected deck ID: $deckId');

                                // Use our GlobalKey for SnackBar messages

                                if (deckId == null) {
                                  print('Deck not found or not defined');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Deck not found or not defined.',
                                      ),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        bottom: 80,
                                        left: 20,
                                        right: 20,
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final back = generateBackText(wordEntry);
                                print('Generated back text: $back');

                                try {
                                  print('Calling apiService.createCard...');
                                  final response = await widget.apiService
                                      .createCard(
                                        front: word,
                                        back: back,
                                        deckId: deckId.toString(),
                                      );
                                  print('Card created: $response');

                                  // Show success message that will appear above the sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Card created successfully!',
                                      ),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        bottom: 80,
                                        left: 20,
                                        right: 20,
                                      ),
                                    ),
                                  );
                                } catch (e, stackTrace) {
                                  print('Failed to create card: $e');
                                  print(stackTrace);

                                  // Show error message that will appear above the sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to create card. Please try again.',
                                      ),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        bottom: 80,
                                        left: 20,
                                        right: 20,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text('+ create card'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
                displaySettings: EpubDisplaySettings(
                  flow: EpubFlow.paginated,
                  snap: true,
                ),
                onChaptersLoaded: (chapters) {},
                onEpubLoaded: () async {},
                onRelocated: (value) {},
                onTextSelected: (epubTextSelection) async {
                  final selectedWord = epubTextSelection.selectedText.trim();
                  if (selectedWord.isNotEmpty) {
                    try {
                      final wordEntry = await widget.apiService.fetchDefinition(
                        selectedWord,
                      );
                      if (!mounted) {
                        return;
                      }
                      showWordDetailBottomSheet(context, wordEntry);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Definition not found'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(
                            bottom: 80,
                            left: 20,
                            right: 20,
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
