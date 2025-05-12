import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:provider/provider.dart';
import 'BooksPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Track the selected index

  // Pages to display for each BottomNavigationBar item
  final List<Widget> _pages = [
    BooksPage(), // Updated to include BooksPage
    const Center(child: Text('Cards Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Settings Page', style: TextStyle(fontSize: 24))),
    const Center(child: Text('Game Page', style: TextStyle(fontSize: 24))),
  ];

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
        body: _pages[_currentIndex], // Display the selected page
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.blueGrey,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Books',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: 'Cards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.gamepad),
              label: 'Game',
            ),
          ],
          currentIndex: _currentIndex, // Highlight the selected item
          onTap: (index) {
            setState(() {
              _currentIndex = index; // Update the selected index
            });
          },
        ),
      ),
    );
  }
}