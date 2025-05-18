import 'package:flutter/material.dart';
import 'dart:io';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Models/Deck.dart';
import 'package:pragmatic/Providers/SelectedDeckProvider.dart';
import 'package:provider/provider.dart';
class DecksScreen extends StatefulWidget {
  final ApiService apiService;
  
  const DecksScreen({super.key, required this.apiService});
  @override
  _DecksScreenState createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  List<Deck> _decks = [];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> showSelectDefaultDeckDialog(BuildContext context, List<Deck> decks) async {
    final selectedDeckProvider = Provider.of<SelectedDeckProvider>(context, listen: false);

    final selectedDeck = await showDialog<Deck>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Default Deck'),
          content: Container(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: decks.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final deck = decks[index];
                return ListTile(
                  title: Text(deck.title),
                  onTap: () {
                    Navigator.of(context).pop(deck); // Return the selected deck
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );
      },
    );

    if (selectedDeck != null) {
      selectedDeckProvider.selectDeck(selectedDeck);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected default deck: ${selectedDeck.title}')),
      );
    }
  }

  Future<void> _loadDecks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final decks = await widget.apiService.getUserDecks();

      setState(() {
        _decks = decks; // Assuming _decks is a List<Deck> declared in your state
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading decks: $e')),
      );
    }
  }
  Future<void> _createDeck() async {
    final nameController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Deck'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Deck Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deck name is required')),
                );
                return;
              }
              Navigator.pop(context, name);
            },
            child: Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        setState(() => _isLoading = true);

        final newDeck = await widget.apiService.createDeck(
          title: result,
        );

        setState(() {
          _decks.add(newDeck);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deck "$result" created successfully')),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating deck: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Decks'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => showSelectDefaultDeckDialog(context, _decks),
          ),
        ],
      ),
      body:RefreshIndicator(
        onRefresh: _loadDecks,
        child: _decks.isEmpty && !_isLoading
            ? ListView(
                children: [
                  SizedBox(height: 200),
                  Center(child: Text('No decks found')),
                ],
              )
            : _isLoading
                ? ListView(
                    children: [
                      SizedBox(height: 200),
                      Center(child: CircularProgressIndicator()),
                    ],
                  )
                : ListView.separated(
                    itemCount: _decks.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final deck = _decks[index];
                      return ListTile(
                        title: Text(deck.title),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          // Navigate to deck details or study screen
                        },
                      );
                    },
                  ),
           ),

      floatingActionButton: FloatingActionButton(
        onPressed: _createDeck,
        child: Icon(Icons.add),
        tooltip: 'Create Deck',
      ),
    );
  }
}