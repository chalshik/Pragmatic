import 'package:flutter/material.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';
import 'package:pragmatic/Services/AuthService.dart';
import 'package:provider/provider.dart';
import 'package:pragmatic/Screens/BooksPage.dart';
import 'package:pragmatic/Screens/GameScreen.dart';
import 'package:pragmatic/Screens/SettingsScreen.dart';
import 'package:pragmatic/Screens/DecksScreen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = ApiService();
    apiService.setAuthService(authService);
    
    final List<Widget> pages = [
      BooksPage(apiService: apiService),
      DecksScreen(apiService: apiService),
      const SettingsScreen(),
      const GameScreen(),
    ];
    
    return AuthWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pragmatic Language App'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                try {
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
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
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
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}