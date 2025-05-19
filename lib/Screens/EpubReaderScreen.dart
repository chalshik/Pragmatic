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

  const EpubReaderScreen({super.key, required this.filePath, required this.apiService});

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
      final word = wordEntry.word;
      final phonetic = wordEntry.phonetic;
      final audio = wordEntry.phonetics.firstWhere(
        (p) => p.audio != null && p.audio!.isNotEmpty,
        orElse: () => Phonetic(text: '', audio: ''),
      ).audio;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          return DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                padding: EdgeInsets.all(16),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Text(
                        word,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (phonetic.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          '/$phonetic/',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
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
                    ...wordEntry.meanings.map((meaning) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meaning.partOfSpeech,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          ...meaning.definitions.map((d) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('- ${d.definition}'),
                                  if (d.example != null && d.example!.isNotEmpty)
                                    Text(
                                      'Example: "${d.example}"',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                    ElevatedButton(
                      onPressed: () async {
                        print('Create card button pressed');
                        final deckId = Provider.of<SelectedDeckProvider>(context, listen: false).selectedDeck?.id;
                        print('Selected deck ID: $deckId');
                        final back = generateBackText(wordEntry);
                        print('Generated back text: $back');

                        try {
                          if (deckId != null) {
                            print('Calling apiService.createCard...');
                            final createdCard = await widget.apiService.createCard(
                              front: word,
                              back: back,
                              deckId: deckId.toString(),
                            );
                            print('Card created: $createdCard');

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Card created successfully!'),
                                duration: Duration(seconds: 2),
                              ),
                            );

                            Navigator.of(context).pop(); // close the bottom sheet or dialog
                            print('Bottom sheet closed');
                          } else {
                            print('Deck not found or not defined');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deck not found or not defined.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e, stackTrace) {
                          print('Failed to create card: $e');
                          print(stackTrace);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create card: $e'),
                              duration: Duration(seconds: 2),
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
              );
            },
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
                  displaySettings: EpubDisplaySettings(flow: EpubFlow.paginated, snap: true),
                  onChaptersLoaded: (chapters) {},
                  onEpubLoaded: () async {},
                  onRelocated: (value) {},
                  onTextSelected: (epubTextSelection) async {
                    final selectedWord = epubTextSelection.selectedText.trim();
                    if (selectedWord.isNotEmpty) {
                      try {
                        final wordEntry = await widget.apiService.fetchDefinition(selectedWord);
                        if (!mounted) {
                          return;
                        }
                        showWordDetailBottomSheet(context, wordEntry);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Definition not found')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          )
        )
      );
    }
}
