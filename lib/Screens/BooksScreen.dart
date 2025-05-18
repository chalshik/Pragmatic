import 'package:flutter/material.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Screens/BooksPage.dart';
import 'package:provider/provider.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService();
    
    return BooksPage(apiService: apiService);
  }
} 