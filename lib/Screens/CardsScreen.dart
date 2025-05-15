import 'package:flutter/material.dart';
import 'package:pragmatic/Widgets/AuthWrapper.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Models/Deck.dart';
import 'package:pragmatic/Services/AuthService.dart';

class CardsScreen extends StatefulWidget {
  final AuthService authService;
  const CardsScreen({super.key, required this.authService});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  late Future<List<Deck>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _decksFuture = ApiService(widget.authService).getUserDecks();
  }

  void _showCreateDeckDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Deck'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Deck title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await ApiService(widget.authService).createDeck(title: result);
        setState(() {
          _decksFuture = ApiService(widget.authService).getUserDecks();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deck created!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create deck: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cards'),
        ),
        body: FutureBuilder<List<Deck>>(
          future: _decksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              debugPrint('DecksScreen error: ${snapshot.error}');
              debugPrintStack(stackTrace: snapshot.stackTrace);
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Error loading decks.'),
                    Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No decks found.'));
            } else {
              final decks = snapshot.data!;
              return ListView.builder(
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  return ListTile(
                    title: Text(deck.title),
                    onTap: () {
                      // TODO: Navigate to deck details or cards
                    },
                  );
                },
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDeckDialog,
          tooltip: 'Create Deck',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}