import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:provider/provider.dart';
import 'package:pragmatic/Screens/HomeScreen.dart';
import 'package:pragmatic/Screens/LoginScreen.dart';
import 'package:pragmatic/Screens/RegisterScreen.dart';
import 'Providers/SelectedDeckProvider.dart';
import 'package:google_fonts/google_fonts.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SelectedDeckProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create instances
    final authService = AuthService();
    final apiService = ApiService();

    // Set up bidirectional dependency using the setter methods
    authService.setApiService(apiService);
    apiService.setAuthService(authService);

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<ApiService>(create: (_) => apiService),
      ],
      child: MaterialApp(
        title: 'Pragmatic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5271FF),
            primary: const Color(0xFF5271FF),
            secondary: const Color(0xFF03DAC5),
            tertiary: const Color(0xFFFFB865),
            background: const Color(0xFFF8F9FA),
            surface: Colors.white,
            error: const Color(0xFFB00020),
            onPrimary: Colors.white,
            onSecondary: Colors.black,
            onBackground: Colors.black87,
            onSurface: Colors.black87,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.interTextTheme(),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF5271FF),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5271FF),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF5271FF),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF5271FF), width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.grey),
          ),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            elevation: 8,
            selectedItemColor: Color(0xFF5271FF),
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
