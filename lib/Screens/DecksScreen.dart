import 'package:flutter/material.dart';
import 'package:pragmatic/Providers/SelectedDeckProvider.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Models/Deck.dart';
import 'package:pragmatic/Screens/DeckSelectionDialog.dart';
import 'package:pragmatic/Screens/CardReviewScreen.dart';
import 'package:provider/provider.dart';

class DecksScreen extends StatefulWidget {
  final ApiService apiService;
  
  const DecksScreen({super.key, required this.apiService});
  
  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  List<Deck> _decks = [];
  bool _isLoading = false;
  Deck? _selectedDeck;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    if (_isLoading) return; // Prevent multiple simultaneous calls
    
    setState(() {
      _isLoading = true;
    });

    try {
      final decks = await widget.apiService.getUserDecks();
      
      if (mounted) { // Check if widget is still in tree
        setState(() {
          _decks = decks;
          _isLoading = false;
        });
        _updateSelectedDeck();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error loading decks: $e');
      }
    }
  }

  void _updateSelectedDeck() {
    final selectedDeckProvider = context.read<SelectedDeckProvider>();
    final globallySelected = selectedDeckProvider.selectedDeck;

    if (globallySelected != null && 
        _decks.any((d) => d.id == globallySelected.id)) {
      _selectedDeck = _decks.firstWhere((d) => d.id == globallySelected.id);
    } else if (_decks.isNotEmpty) {
      _selectedDeck = _decks.first;
    } else {
      _selectedDeck = null;
    }
  }

  Future<void> _createDeck() async {
    final result = await _showCreateDeckDialog();
    
    if (result != null && result.isNotEmpty) {
      await _performCreateDeck(result);
    }
  }

  Future<String?> _showCreateDeckDialog() async {
    final nameController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Deck'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Deck Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                _showErrorSnackBar('Deck name is required');
                return;
              }
              Navigator.pop(context, name);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCreateDeck(String name) async {
    setState(() => _isLoading = true);

    try {
      final newDeck = await widget.apiService.createDeck(title: name);
      
      if (mounted) {
        setState(() {
          _decks.add(newDeck);
          _isLoading = false;
        });
        _showSuccessSnackBar('Deck "$name" created successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error creating deck: $e');
      }
    }
  }

  Future<void> _deleteDeck(int deckId) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      await widget.apiService.deleteDeck(deckId: deckId);
      
      if (mounted) {
        setState(() {
          _decks.removeWhere((deck) => deck.id == deckId);
          _isLoading = false;
        });
        _showSuccessSnackBar('Deck deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error deleting deck: $e');
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: const Text('Are you sure you want to delete this deck? This action cannot be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showDeckActionsDialog(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deck Actions: ${deck.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete deck'),
              onTap: () {
                Navigator.pop(context);
                _deleteDeck(deck.id);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeckSelectionDialog() async {
    if (_decks.isEmpty) {
      _showErrorSnackBar('No decks available to select from');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _DeckSelectionDialog(
        decks: _decks,
        selectedDeck: _selectedDeck,
        onDeckSelected: (deck) => _selectedDeck = deck,
      ),
    );

    if (result == true && _selectedDeck != null) {
      context.read<SelectedDeckProvider>().selectDeck(_selectedDeck!);
      _showSuccessSnackBar('${_selectedDeck!.title} is now the default deck');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDeckSelectionDialog,
            tooltip: 'Set Default Deck',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDecks,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createDeck,
        tooltip: 'Create Deck',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _decks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_decks.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(
            child: Column(
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No decks found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first deck',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: _decks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final deck = _decks[index];
        return ListTile(
          title: Text(deck.title),// Assuming Deck has cardCount
          trailing: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
          onTap: () => _navigateToCardReview(deck),
          onLongPress: () => _showDeckActionsDialog(deck),
        );
      },
    );
  }

  void _navigateToCardReview(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardReviewScreen(
          deckId: deck.id,
          apiService: widget.apiService,
        ),
      ),
    );
  }
}

// Extracted dialog as a separate widget for better organization
class _DeckSelectionDialog extends StatefulWidget {
  final List<Deck> decks;
  final Deck? selectedDeck;
  final Function(Deck) onDeckSelected;

  const _DeckSelectionDialog({
    required this.decks,
    required this.selectedDeck,
    required this.onDeckSelected,
  });

  @override
  State<_DeckSelectionDialog> createState() => _DeckSelectionDialogState();
}

class _DeckSelectionDialogState extends State<_DeckSelectionDialog> {
  Deck? _tempSelectedDeck;

  @override
  void initState() {
    super.initState();
    _tempSelectedDeck = widget.selectedDeck;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Default Deck'),
      content: DropdownButton<Deck>(
        value: _tempSelectedDeck,
        isExpanded: true,
        hint: const Text('Select a deck'),
        items: widget.decks.map((deck) {
          return DropdownMenuItem<Deck>(
            value: deck,
            child: Text(
              deck.title,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (Deck? newDeck) {
          setState(() {
            _tempSelectedDeck = newDeck;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_tempSelectedDeck != null) {
              widget.onDeckSelected(_tempSelectedDeck!);
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a deck')),
              );
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}