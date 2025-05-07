import 'package:flutter/material.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Screen'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                try {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.signOut();
                  // No need to navigate - AuthWrapper will handle redirection
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              },
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'Books Page',
            style: TextStyle(fontSize: 24),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Books',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: 'Cards',
            ),
          ],
          currentIndex: 0,
          onTap: (index) {
            // Handle navigation based on index
            if (index == 0) {
              Navigator.pushNamed(context, '/books');
            } else if (index == 1) {
              Navigator.pushNamed(context, '/cards');
            }
          },
        ),
      ),
    );
  }
}