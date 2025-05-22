import 'package:flutter/material.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';
import 'package:pragmatic/Screens/BooksPage.dart';
import 'package:pragmatic/Screens/GameScreen.dart';
import 'package:pragmatic/Screens/SettingsScreen.dart';
import 'package:pragmatic/Screens/DecksScreen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService();
    apiService.setAuthService(authService);
    pages = [
      BooksPage(apiService: apiService),
      DecksScreen(apiService: apiService),
      const SettingsScreen(),
      const GameScreen(),
    ];
  }

  final List<String> _titles = [
    'Books',
    'Flashcards',
    'Settings',
    'Vocabulary Game',
  ];

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          title: Text(_titles[_currentIndex]),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 22),
              tooltip: 'Logout',
              onPressed: () async {
                try {
                  await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                              'Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                final authService = Provider.of<AuthService>(
                                    context,
                                    listen: false);
                                await authService.signOut();
                                if (mounted) {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/login');
                                }
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        ));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error logging out: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            color: Colors.white,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            elevation: 0,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Books',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.credit_card_outlined),
                activeIcon: Icon(Icons.credit_card),
                label: 'Cards',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.gamepad_outlined),
                activeIcon: Icon(Icons.gamepad),
                label: 'Game',
              ),
            ],
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}