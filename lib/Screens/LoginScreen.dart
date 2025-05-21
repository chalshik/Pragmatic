import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Services/AuthService.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthService authService;
  String email = '';
  String password = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                setState(() {
                  email = value;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All fields are required')),
                  );
                  return;
                }

                try {
                  User? user = await authService.signIn(email, password);
                  if (user != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Login successful')));
                    // Navigate to home screen
                    Navigator.of(context).pushReplacementNamed('/home');
                  }
                } on FirebaseAuthException catch (e) {
                  String errorMessage;
                  if (e.code == 'user-not-found') {
                    errorMessage = 'No user found with this email.';
                  } else if (e.code == 'wrong-password') {
                    errorMessage = 'Wrong password provided.';
                  } else if (e.code == 'invalid-email') {
                    errorMessage = 'The email address is not valid.';
                  } else {
                    errorMessage = 'An error occurred. Please try again.';
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(errorMessage)));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An unexpected error occurred')),
                  );
                }
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              child: Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}
