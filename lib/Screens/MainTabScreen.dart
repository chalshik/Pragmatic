import 'package:flutter/material.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:pragmatic/Screens/HomeTabScreen.dart';
import 'package:pragmatic/Screens/FlashcardsTabScreen.dart';
import 'package:pragmatic/Screens/GameTabScreen.dart';
import 'package:pragmatic/Screens/SettingsTabScreen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;
  
  // Define the tabs we'll show in the bottom navigation
  final List<Widget> _tabs = [
    const HomeTabScreen(),
    const FlashcardsTabScreen(),
    const GameTabScreen(),
    const SettingsTabScreen(),
  ];
  
  // Tab titles
  final List<String> _titles = [
    'Home',
    'Flashcards',
    'Game',
    'Settings',
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                try {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.signOut();
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
        body: _tabs[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // Required for more than 3 items
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.credit_card),
              label: 'Flashcards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.games),
              label: 'Game',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
} 