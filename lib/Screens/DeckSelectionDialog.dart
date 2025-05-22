// widgets/deck_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/SelectedDeckProvider.dart'; // Ensure this path is correct
import '../Models/Deck.dart'; // Ensure this path is correct

class DeckDialog extends StatefulWidget {
  final List<Deck> decks;
  const DeckDialog(this.decks, {super.key});

  @override
  State<DeckDialog> createState() => _DeckDialogState();
}

class _DeckDialogState extends State<DeckDialog> {
  Deck? _selectedDeck;

  @override
  void initState() {
    super.initState();
    final selectedDeckProvider = Provider.of<SelectedDeckProvider>(context, listen: false);
    Deck? globallySelected = selectedDeckProvider.selectedDeck;

    if (globallySelected != null && widget.decks.any((d) => d.id == globallySelected!.id)) {
      _selectedDeck = widget.decks.firstWhere((d) => d.id == globallySelected!.id);
    } else if (widget.decks.isNotEmpty) {
      _selectedDeck = widget.decks.first;
    } else {
      _selectedDeck = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.decks.isEmpty) {
      return AlertDialog(
        title: const Text('No Decks'),
        content: const Text('There are no decks available to select.'),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Set Default Deck'),
      content: DropdownButton<Deck>(
        value: _selectedDeck,
        isExpanded: true,
        hint: const Text('Select a deck'),
        items: widget.decks.map((deck) {
          return DropdownMenuItem<Deck>(
            value: deck,
            child: Text(
              deck.title ?? 'Untitled Deck',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (Deck? newDeck) {
          setState(() {
            _selectedDeck = newDeck;
          });
        },
      ),
      actions: [
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('CONFIRM'),
          onPressed: () {
            if (_selectedDeck != null) {
              Provider.of<SelectedDeckProvider>(context, listen: false)
                  .selectDeck(_selectedDeck!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_selectedDeck!.title} is now the default deck')),
              );
              Navigator.of(context).pop(true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a deck')),
              );
            }
          },
        ),
      ],
    );
  }
}
