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
  late final ApiService _apiService;
  late final List<Widget> _pages;
  bool _isLoggingOut = false;

  static const List<String> _titles = [
    'Books',
    'Flashcards',
    'Settings',
    'Vocabulary Game',
  ];

  static const List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
      label: 'Books',
    ),
    _NavigationItem(
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card,
      label: 'Cards',
    ),
    _NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
    _NavigationItem(
      icon: Icons.gamepad_outlined,
      activeIcon: Icons.gamepad,
      label: 'Game',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    final authService = context.read<AuthService>();
    _apiService = ApiService()..setAuthService(authService);
    
    _pages = [
      BooksPage(apiService: _apiService),
      DecksScreen(apiService: _apiService),
      const SettingsScreen(),
      const GameScreen(),
    ];
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    final shouldLogout = await _showLogoutConfirmation();
    if (!shouldLogout) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error logging out: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<bool> _showLogoutConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _onTabChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AuthWrapper(
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: _buildAppBar(theme),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(theme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(_titles[_currentIndex]),
      elevation: 0,
      backgroundColor: theme.colorScheme.background,
      foregroundColor: theme.colorScheme.onBackground,
      actions: [
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      icon: _isLoggingOut
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout, size: 22),
      tooltip: 'Logout',
      onPressed: _isLoggingOut ? null : _handleLogout,
    );
  }

  Widget _buildBottomNavigationBar(ThemeData theme) {
    return Container(
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
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        elevation: 0,
        items: _navigationItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}

// Data class for navigation items
class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}