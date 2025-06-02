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
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  late final EpubController _epubController;
  AudioPlayer? _audioPlayer;
  bool _isCreatingCard = false;

  @override
  void initState() {
    super.initState();
    _epubController = EpubController();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  String _generateBackText(WordEntry wordEntry) {
    final buffer = StringBuffer();

    for (final meaning in wordEntry.meanings) {
      buffer.writeln(meaning.partOfSpeech);

      for (final definition in meaning.definitions) {
        buffer.writeln('• ${definition.definition}');
        if (definition.example?.isNotEmpty == true) {
          buffer.writeln('  Example: "${definition.example}"');
        }
      }
      buffer.writeln(); // Add blank line between meanings
    }

    return buffer.toString().trim();
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      // Dispose previous player if exists
      await _audioPlayer?.dispose();
      
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.play(UrlSource(audioUrl));
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to play audio', isError: true);
      }
    }
  }

  Future<void> _createFlashcard(WordEntry wordEntry) async {
    if (_isCreatingCard) return; // Prevent multiple simultaneous calls

    setState(() {
      _isCreatingCard = true;
    });

    try {
      final selectedDeckProvider = context.read<SelectedDeckProvider>();
      final deckId = selectedDeckProvider.selectedDeck?.id;

      if (deckId == null) {
        _showDeckSelectionError();
        return;
      }

      final backText = _generateBackText(wordEntry);
      
      await widget.apiService.createCard(
        front: wordEntry.word,
        back: backText,
        deckId: deckId.toString(),
      );

      if (mounted) {
        Navigator.pop(context); // Close the bottom sheet
        _showSnackBar('Card created successfully!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to create card. Please try again.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingCard = false;
        });
      }
    }
  }

  void _showDeckSelectionError() {
    _showSnackBar(
      'Please select a deck first',
      isError: true,
      action: SnackBarAction(
        label: 'Settings',
        onPressed: () {
          // Navigate to deck selection or settings
          // This should be implemented based on your app's navigation structure
        },
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError, SnackBarAction? action}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
        action: action,
      ),
    );
  }

  Future<void> _handleTextSelection(String selectedText) async {
    final trimmedText = selectedText.trim();
    if (trimmedText.isEmpty) return;

    try {
      final wordEntry = await widget.apiService.fetchDefinition(trimmedText);
      if (mounted) {
        _showWordDetailBottomSheet(wordEntry);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Definition not found', isError: true);
      }
    }
  }

  void _showWordDetailBottomSheet(WordEntry wordEntry) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => _WordDetailBottomSheet(
        wordEntry: wordEntry,
        onPlayAudio: _playAudio,
        onCreateCard: () => _createFlashcard(wordEntry),
        isCreatingCard: _isCreatingCard,
      ),
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
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: EpubViewer(
          epubSource: EpubSource.fromFile(File(widget.filePath)),
          epubController: _epubController,
          displaySettings: EpubDisplaySettings(
            flow: EpubFlow.paginated,
            snap: true,
          ),
          onChaptersLoaded: (_) {},
          onEpubLoaded: () {},
          onRelocated: (_) {},
          onTextSelected: (selection) => _handleTextSelection(selection.selectedText),
        ),
      ),
    );
  }
}

// Extracted bottom sheet as a separate widget for better organization
class _WordDetailBottomSheet extends StatelessWidget {
  final WordEntry wordEntry;
  final Function(String) onPlayAudio;
  final VoidCallback onCreateCard;
  final bool isCreatingCard;

  const _WordDetailBottomSheet({
    required this.wordEntry,
    required this.onPlayAudio,
    required this.onCreateCard,
    required this.isCreatingCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {}, // Prevents dismissal on tap
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeader(context, colorScheme),
            _buildDivider(),
            _buildDefinitions(colorScheme),
            _buildCreateCardButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final audioUrl = _getAudioUrl();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wordEntry.word,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (wordEntry.phonetic.isNotEmpty)
                  Text(
                    '/${wordEntry.phonetic}/',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),
          if (audioUrl != null) _buildAudioButton(colorScheme, audioUrl),
        ],
      ),
    );
  }

  Widget _buildAudioButton(ColorScheme colorScheme, String audioUrl) {
    return Material(
      color: colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(40),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: () => onPlayAudio(audioUrl),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.volume_up,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  String? _getAudioUrl() {
    try {
      return wordEntry.phonetics
          .firstWhere(
            (p) => p.audio?.isNotEmpty == true,
          )
          .audio;
    } catch (e) {
      return null;
    }
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Colors.grey[200], height: 1),
    );
  }

  Widget _buildDefinitions(ColorScheme colorScheme) {
    return Flexible(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: wordEntry.meanings
                .map((meaning) => _buildMeaningSection(meaning, colorScheme))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMeaningSection(Meaning meaning, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPartOfSpeechChip(meaning.partOfSpeech, colorScheme),
        const SizedBox(height: 8),
        ...meaning.definitions.map(_buildDefinitionItem),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPartOfSpeechChip(String partOfSpeech, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        partOfSpeech,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDefinitionItem(Definition definition) {
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
                  definition.definition,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          if (definition.example?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 4),
              child: Text(
                '"${definition.example}"',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateCardButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ElevatedButton.icon(
        onPressed: isCreatingCard ? null : onCreateCard,
        icon: isCreatingCard
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_card),
        label: Text(isCreatingCard ? 'Creating...' : 'Add to Flashcards'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// Extension to make null checks more readable
extension StringExtension on String? {
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
}