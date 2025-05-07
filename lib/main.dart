import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:pragmatic/Screens/LoginScreen.dart';
import 'package:pragmatic/Screens/RegisterScrenn.dart';
import 'package:pragmatic/Screens/MainTabScreen.dart';
import 'package:pragmatic/Screens/HomeTabScreen.dart';
import 'package:pragmatic/Screens/FlashcardsTabScreen.dart';
import 'package:pragmatic/Screens/GameTabScreen.dart';
import 'package:pragmatic/Screens/SettingsTabScreen.dart';

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
        initialRoute: '/',
        routes: {
          '/': (context) => const MainTabScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeTabScreen(),
          '/flashcards': (context) => const FlashcardsTabScreen(),
          '/game': (context) => const GameTabScreen(),
          '/settings': (context) => const SettingsTabScreen(),
        },
      ),
    );
  }
}


