import 'package:flutter/material.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Screens/LoginScreen.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        return child;
      },
    );
  }
}