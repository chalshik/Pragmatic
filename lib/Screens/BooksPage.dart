import 'EpubReaderScreen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pragmatic/Services/ApiService.dart';

class BooksPage extends StatefulWidget {
  final ApiService apiService;
  
  

  BooksPage({super.key, required this.apiService});@override
  _BooksPageState createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  List<File> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final directory = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${directory.path}/books');
    if (await booksDir.exists()) {
      final files = booksDir.listSync().whereType<File>().toList();
      setState(() {
        _books = files;
      });
    }
  }

  Future<void> _addBook() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['epub']);
    if (result != null && result.files.single.path != null) {
      final directory = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${directory.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }
      final file = File(result.files.single.path!);
      final newFile = await file.copy('${booksDir.path}/${file.uri.pathSegments.last}');
      setState(() {
        _books.add(newFile);
      });
    }
  }

  void _openBook(File book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EpubReaderScreen(filePath: book.path, apiService: widget.apiService,),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Books"),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return GestureDetector(
            onTap: () => _openBook(book),
            child: Card(
              child: Center(
                child: Text(
                  book.uri.pathSegments.last,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBook,
        child: Icon(Icons.add),
      ),
    );
  }
}