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
        // other providers...
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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
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


