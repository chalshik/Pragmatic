import 'package:flutter/material.dart';
import '../Models/Deck.dart';

class SelectedDeckProvider extends ChangeNotifier {
  Deck? _selectedDeck;

  Deck? get selectedDeck => _selectedDeck;

  void selectDeck(Deck deck) {
    print('SelectedDeckProvider: Selecting deck ${deck.title} (ID: ${deck.id})');
    _selectedDeck = deck;
    notifyListeners();
    print('SelectedDeckProvider: Notified listeners of deck selection');
  }

  void clearDeck() {
    print('SelectedDeckProvider: Clearing selected deck');
    _selectedDeck = null;
    notifyListeners();
    print('SelectedDeckProvider: Notified listeners of deck clearing');
  }
}
