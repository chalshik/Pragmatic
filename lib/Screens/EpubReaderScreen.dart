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
        return GestureDetector(
          onTap: () {}, // Prevents tap from dismissing sheet
                      child: Container(
            decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
                          ),
                          boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5),
                          ],
                        ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                // Word and pronunciation
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Column(
                          children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                Text(
                                      word,
                                  style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                if (phonetic.isNotEmpty)
                                  Text(
                                        '/$phonetic/',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                              ],
                            ),
                                    ),
                          if (audio != null && audio.isNotEmpty)
                            Material(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(40),
                                onTap: () async {
                                          final player = AudioPlayer();
                                          await player.play(UrlSource(audio));
                                        },
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Icon(
                                    Icons.volume_up, 
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                      ),
                                    ),
                                  ],
                      ),
                    ],
                  ),
                ),
                
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Colors.grey[200], height: 1),
                ),
                
                // Definitions section - scrollable
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: wordEntry.meanings.map((meaning) {
                                    return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, 
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                          meaning.partOfSpeech,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                          ),
                                        ),
                              const SizedBox(height: 8),
                                        ...meaning.definitions.map((d) {
                                          return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                            child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                          const Text('• ', style: TextStyle(fontSize: 16)),
                                          Expanded(
                                            child: Text(
                                              d.definition,
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (d.example != null && d.example!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 14, top: 4),
                                          child: Text(
                                            '"${d.example}"',
                                                    style: TextStyle(
                                              color: Colors.grey[700],
                                              fontStyle: FontStyle.italic,
                                            ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                              const SizedBox(height: 8),
                                      ],
                                    );
                                  }).toList(),
                      ),
                    ),
                              ),
                            ),

                // Create card button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ElevatedButton.icon(
                              onPressed: () async {
                                print('Create card button pressed');

                                // Get data needed for API call
                                final deckId =
                                    Provider.of<SelectedDeckProvider>(
                                      context,
                                      listen: false,
                                    ).selectedDeck?.id;
                                print('Selected deck ID: $deckId');

                                if (deckId == null) {
                                  print('Deck not found or not defined');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please select a deck first.',
                                      ),
                                      action: SnackBarAction(
                                        label: 'Select',
                                        onPressed: () {
                                          // Add deck selection dialog here if needed
                                        },
                                      ),
                                      duration: Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      margin: EdgeInsets.only(
                                        top: MediaQuery.of(context).padding.top + 10,
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

                                  // Close the bottom sheet first
                                  Navigator.of(context).pop();
                                  
                                  // Then show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Card created successfully!',
                                      ),
                                      backgroundColor: Colors.green,
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

                                  // Close the bottom sheet first on error too
                                  Navigator.of(context).pop();
                                  
                                  // Then show error message
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
                    icon: Icon(Icons.add_card),
                    label: Text('Add to Flashcards'),
                              style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('EPUB Reader'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                          duration: Duration(seconds: 2),
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
