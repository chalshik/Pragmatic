import 'package:flutter/material.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Books'),
        ),
        body: Center(
          child: const Text('Welcome to the Books Screen!'),
        ),
      ),
    );
  }
}