// widgets/deck_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Providers/SelectedDeckProvider.dart';
import '../Models/Deck.dart';

class DeckDialog extends StatefulWidget {
  final List<Deck> decks;
  const DeckDialog(this.decks, {super.key});

  @override
  State<DeckDialog> createState() => _DeckDialogState();
}

class _DeckDialogState extends State<DeckDialog> {
  Deck? selectedDeck;

  @override
  void initState() {
    super.initState();
    selectedDeck = widget.decks.isNotEmpty ? widget.decks.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with question icon
            Row(
              children: [
                Text(
                  "Default deck",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(width: 6),
                Icon(Icons.help_outline, size: 18),
              ],
            ),
            SizedBox(height: 12),

            // Dropdown
            DropdownButton<Deck>(
              value: selectedDeck,
              isExpanded: true,
              items:
                  widget.decks.map((deck) {
                    return DropdownMenuItem<Deck>(
                      value: deck,
                      child: Text(deck.title),
                    );
                  }).toList(),
              onChanged: (Deck? newDeck) {
                setState(() {
                  selectedDeck = newDeck;
                });
              },
            ),
            SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text("CONFIRM"),
                  onPressed: () {
                    print('CONFIRM button pressed');
                    if (selectedDeck != null) {
                      print('Selecting deck with id: ${selectedDeck!.id}');
                      Provider.of<SelectedDeckProvider>(
                        context,
                        listen: false,
                      ).selectDeck(selectedDeck!);
                    } else {
                      print('No deck selected');
                    }
                    Navigator.pop(context);
                    print('Navigator.pop called, bottom sheet/dialog closed');
                  },
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text("CLOSE"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
