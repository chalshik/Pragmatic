import 'package:flutter/material.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Screens/LoginScreen.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;
  final AuthService _authService = AuthService();

  AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _authService.authStateChanges(),
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