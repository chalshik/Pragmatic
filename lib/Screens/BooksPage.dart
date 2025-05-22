import 'EpubReaderScreen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Widgets/CustomUI.dart';
import 'package:epubx/epubx.dart' hide Image;

class BooksPage extends StatefulWidget {
  final ApiService apiService;

  const BooksPage({super.key, required this.apiService});
  @override
  _BooksPageState createState() => _BooksPageState();
}

class BookData {
  final File file;
  final String title;
  final Uint8List? coverImage;

  BookData({required this.file, required this.title, this.coverImage});
}

class _BooksPageState extends State<BooksPage> {
  List<BookData> _books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<BookData> _extractBookData(File file) async {
    try {
      // Read the EPUB file
      List<int> bytes = await file.readAsBytes();
      EpubBook epubBook = await EpubReader.readBook(bytes);

      // Extract title
      String title =
          epubBook.Title ?? _formatFileName(file.uri.pathSegments.last);

      // Extract cover image
      Uint8List? coverImage;

      // Try to find cover image by looking at the images in the EPUB
      if (epubBook.Content?.Images != null &&
          epubBook.Content!.Images!.isNotEmpty) {
        // Try to find a cover image by name convention
        List<String> coverPatterns = ['cover', 'title'];

        // First, try to find explicit cover image
        for (var entry in epubBook.Content!.Images!.entries) {
          String key = entry.key.toLowerCase();
          if (coverPatterns.any((pattern) => key.contains(pattern))) {
            if (entry.value.Content != null) {
              coverImage = Uint8List.fromList(entry.value.Content!);
              break;
            }
          }
        }

        // If we still don't have a cover, just use the first image
        if (coverImage == null && epubBook.Content!.Images!.isNotEmpty) {
          var firstImage = epubBook.Content!.Images!.entries.first.value;
          if (firstImage.Content != null) {
            coverImage = Uint8List.fromList(firstImage.Content!);
          }
        }
      }

      return BookData(file: file, title: title, coverImage: coverImage);
    } catch (e, stack) {
      print('Error extracting book data: $e');
      print(stack);
      // Return default book data if extraction fails
      return BookData(
        file: file,
        title: _formatFileName(file.uri.pathSegments.last),
        coverImage: null,
      );
    }
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${directory.path}/books');
      if (await booksDir.exists()) {
        final files = booksDir.listSync().whereType<File>().toList();

        // Clear the current list
        _books.clear();

        // Process each file to extract book data
        for (var file in files) {
          BookData bookData = await _extractBookData(file);
          _books.add(bookData);
        }

        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading books: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBook() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result != null && result.files.single.path != null) {
        final directory = await getApplicationDocumentsDirectory();
        final booksDir = Directory('${directory.path}/books');

        if (!await booksDir.exists()) {
          await booksDir.create(recursive: true);
        }

        final file = File(result.files.single.path!);
        final fileName = file.uri.pathSegments.last;

        // Show loading indicator with indefinite duration
        ScaffoldMessenger.of(
          context,
        ).clearSnackBars(); // Clear any existing snackbars

        final loadingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Text('Adding $fileName...'),
                ),
              ],
            ),
            duration: Duration(minutes: 5), // Much longer duration
            behavior: SnackBarBehavior.floating,
          ),
        );

        try {
          // Copy file
          final newFile = await file.copy('${booksDir.path}/$fileName');

          // Extract book data
          final bookData = await _extractBookData(newFile);

          // Update state
          if (mounted) {
            // Check if widget is still mounted
            setState(() {
              _books.add(bookData);
            });
          }

          // Hide loading snackbar and show success
          ScaffoldMessenger.of(context).clearSnackBars();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added ${bookData.title}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          // Hide loading snackbar and show error
          ScaffoldMessenger.of(context).clearSnackBars();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add book: ${e.toString()}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }

          print('Error adding book: $e');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }

      print('Error in _addBook: $e');
    }
  }

  void _openBook(File book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EpubReaderScreen(
              filePath: book.path,
              apiService: widget.apiService,
            ),
      ),
    );
  }

  String _formatFileName(String fileName) {
    // Remove file extension and replace underscores with spaces
    String name = fileName.replaceAll('.epub', '').replaceAll('_', ' ');

    // Capitalize each word
    List<String> words = name.split(' ');
    words =
        words.map((word) {
          if (word.isNotEmpty) {
            return word[0].toUpperCase() + word.substring(1);
          }
          return word;
        }).toList();

    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const LoadingIndicator(message: 'Loading books...')
              : _books.isEmpty
              ? EmptyStateWidget(
                title: 'No Books Found',
                message:
                    'Add EPUB books to start reading and learning new vocabulary',
                icon: Icons.menu_book_outlined,
                actionLabel: 'Add Book',
                onActionPressed: _addBook,
              )
              : RefreshIndicator(
                onRefresh: _loadBooks,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];

                    return GestureDetector(
                      onTap: () => _openBook(book.file),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Book cover
                            Expanded(
                              flex: 4,
                              child:
                                  book.coverImage != null
                                      ? Image.memory(
                                        book.coverImage!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          print("Error loading image: $error");
                                          return _buildDefaultCoverImage(
                                            context,
                                          );
                                        },
                                      )
                                      : _buildDefaultCoverImage(context),
                            ),
                            // Book title
                            Expanded(
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
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDefaultCoverImage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.book,
          size: 50,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
