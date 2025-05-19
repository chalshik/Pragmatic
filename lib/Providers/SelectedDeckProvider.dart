import 'package:flutter/material.dart';
import '../Models/Deck.dart';

class SelectedDeckProvider extends ChangeNotifier {
  Deck? _selectedDeck;

  Deck? get selectedDeck => _selectedDeck;

  void selectDeck(Deck deck) {
    _selectedDeck = deck;
    notifyListeners();
  }

  void clearDeck() {
    _selectedDeck = null;
    notifyListeners();
  }
}
