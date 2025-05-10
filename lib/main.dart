import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:pragmatic/Screens/HomeScreen.dart';
import 'package:pragmatic/Screens/LoginScreen.dart';
import 'package:pragmatic/Screens/RegisterScrenn.dart';
import 'package:pragmatic/Screens/BooksScreen.dart';
import 'package:pragmatic/Screens/CardsScreen.dart';
import 'package:pragmatic/Screens/GameScreen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Pragmatic',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/books': (context) => const BooksScreen(),
          '/cards': (context) => const CardsScreen(),
          '/game':(contex) => const GameScreen(),
        },
      ),
    );
  }
}


