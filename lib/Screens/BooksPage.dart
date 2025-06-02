import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Widgets/CustomUI.dart';
import 'package:epubx/epubx.dart' hide Image;
import 'EpubReaderScreen.dart';

// Model class with immutable properties and proper documentation
/// Represents book data with file reference, title, and optional cover image
@immutable
class BookData {
  const BookData({
    required this.file,
    required this.title,
    this.coverImage,
  });

  final File file;
  final String title;
  final Uint8List? coverImage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookData &&
          runtimeType == other.runtimeType &&
          file.path == other.file.path &&
          title == other.title;

  @override
  int get hashCode => file.path.hashCode ^ title.hashCode;
}

/// A page that displays and manages EPUB books
class BooksPage extends StatefulWidget {
  const BooksPage({
    super.key,
    required this.apiService,
  });

  final ApiService apiService;

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  static const List<String> _allowedExtensions = ['epub'];
  static const List<String> _coverPatterns = ['cover', 'title'];
  static const Duration _snackBarDuration = Duration(seconds: 3);
  static const Duration _loadingSnackBarDuration = Duration(minutes: 5);
  static const int _gridCrossAxisCount = 2;
  static const double _gridSpacing = 16.0;
  static const double _gridChildAspectRatio = 0.75;

  final List<BookData> _books = <BookData>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  /// Extracts book metadata from EPUB file
  Future<BookData> _extractBookData(File file) async {
    try {
      final List<int> bytes = await file.readAsBytes();
      final EpubBook epubBook = await EpubReader.readBook(bytes);

      final String title = epubBook.Title?.isNotEmpty == true
          ? epubBook.Title!
          : _formatFileName(file.uri.pathSegments.last);

      final Uint8List? coverImage = await _extractCoverImage(epubBook);

      return BookData(
        file: file,
        title: title,
        coverImage: coverImage,
      );
    } catch (e, stackTrace) {
      debugPrint('Error extracting book data: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return BookData(
        file: file,
        title: _formatFileName(file.uri.pathSegments.last),
      );
    }
  }

  /// Extracts cover image from EPUB book
  Future<Uint8List?> _extractCoverImage(EpubBook epubBook) async {
    if (epubBook.Content?.Images == null || 
        epubBook.Content!.Images!.isEmpty) {
      return null;
    }

    // Try to find cover image by name convention
    for (final entry in epubBook.Content!.Images!.entries) {
      final String key = entry.key.toLowerCase();
      if (_coverPatterns.any((pattern) => key.contains(pattern))) {
        if (entry.value.Content != null) {
          return Uint8List.fromList(entry.value.Content!);
        }
      }
    }

    // If no cover found, use first available image
    final firstImage = epubBook.Content!.Images!.entries.first.value;
    if (firstImage.Content != null) {
      return Uint8List.fromList(firstImage.Content!);
    }

    return null;
  }

  /// Loads books from the documents directory
  Future<void> _loadBooks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final Directory booksDir = Directory('${directory.path}/books');
      
      if (!await booksDir.exists()) {
        setState(() {
          _books.clear();
          _isLoading = false;
        });
        return;
      }

      final List<File> files = booksDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.epub'))
          .toList();

      _books.clear();

      for (final File file in files) {
        if (!mounted) return;
        
        final BookData bookData = await _extractBookData(file);
        _books.add(bookData);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
      if (mounted) {
        _safeShowErrorSnackBar(context, 'Error loading books: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Adds a new book from file picker
  Future<void> _addBook() async {
    // Capture context early to avoid accessing it after async operations
    final BuildContext currentContext = context;
    
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (result?.files.single.path == null) return;

      final File sourceFile = File(result!.files.single.path!);
      final String fileName = sourceFile.uri.pathSegments.last;

      await _processBookFile(sourceFile, fileName, currentContext);
    } catch (e) {
      debugPrint('Error in _addBook: $e');
      // Use the captured context and check if widget is still mounted
      if (mounted) {
        _safeShowErrorSnackBar(currentContext, 'Error selecting file: $e');
      }
    }
  }

  /// Processes and saves the selected book file
  Future<void> _processBookFile(File sourceFile, String fileName, BuildContext currentContext) async {
    if (!mounted) return;

    _safeClearSnackBars(currentContext);
    _safeShowLoadingSnackBar(currentContext, 'Adding $fileName...');

    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final Directory booksDir = Directory('${directory.path}/books');

      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final File newFile = await sourceFile.copy('${booksDir.path}/$fileName');
      final BookData bookData = await _extractBookData(newFile);

      if (mounted) {
        setState(() {
          _books.add(bookData);
        });

        _safeClearSnackBars(currentContext);
        _safeShowSuccessSnackBar(currentContext, 'Added ${bookData.title}');
      }
    } catch (e) {
      debugPrint('Error adding book: $e');
      if (mounted) {
        _safeClearSnackBars(currentContext);
        _safeShowErrorSnackBar(currentContext, 'Failed to add book: $e');
      }
    }
  }

  /// Opens the selected book in the reader
  void _openBook(BookData book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => EpubReaderScreen(
          filePath: book.file.path,
          apiService: widget.apiService,
        ),
      ),
    );
  }

  /// Formats filename to a readable title
  String _formatFileName(String fileName) {
    return fileName
        .replaceAll('.epub', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((String word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word)
        .join(' ');
  }

  // Helper methods for SnackBar management with safe context handling
  void _safeClearSnackBars(BuildContext currentContext) {
    try {
      if (mounted && currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).clearSnackBars();
      }
    } catch (e) {
      debugPrint('Error clearing snackbars: $e');
    }
  }

  void _safeShowLoadingSnackBar(BuildContext currentContext, String message) {
    try {
      if (!mounted || !currentContext.mounted) return;
      
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
          duration: _loadingSnackBarDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error showing loading snackbar: $e');
    }
  }

  void _safeShowSuccessSnackBar(BuildContext currentContext, String message) {
    try {
      if (!mounted || !currentContext.mounted) return;
      
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: _snackBarDuration,
        ),
      );
    } catch (e) {
      debugPrint('Error showing success snackbar: $e');
    }
  }

  void _safeShowErrorSnackBar(BuildContext currentContext, String message) {
    try {
      if (!mounted || !currentContext.mounted) return;
      
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('Error showing error snackbar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading books...');
    }

    if (_books.isEmpty) {
      return EmptyStateWidget(
        title: 'No Books Found',
        message: 'Add EPUB books to start reading and learning new vocabulary',
        icon: Icons.menu_book_outlined,
        actionLabel: 'Add Book',
        onActionPressed: _addBook,
      );
    }

    return _buildBooksGrid();
  }

  Widget _buildBooksGrid() {
    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: GridView.builder(
        padding: const EdgeInsets.all(_gridSpacing),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridCrossAxisCount,
          crossAxisSpacing: _gridSpacing,
          mainAxisSpacing: _gridSpacing,
          childAspectRatio: _gridChildAspectRatio,
        ),
        itemCount: _books.length,
        itemBuilder: _buildBookCard,
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, int index) {
    final BookData book = _books[index];

    return GestureDetector(
      onTap: () => _openBook(book),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBookCover(book),
            _buildBookTitle(book),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCover(BookData book) {
    return Expanded(
      flex: 4,
      child: book.coverImage != null
          ? Image.memory(
              book.coverImage!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading image: $error');
                return _buildDefaultCoverImage();
              },
            )
          : _buildDefaultCoverImage(),
    );
  }

  Widget _buildBookTitle(BookData book) {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCoverImage() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      color: colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.book,
          size: 50,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return FloatingActionButton(
      onPressed: _addBook,
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add),
    );
  }
}