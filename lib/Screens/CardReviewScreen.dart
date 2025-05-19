import 'package:flutter/material.dart';
import 'package:pragmatic/Models/Card.dart' as anki;
import 'package:pragmatic/Services/ApiService.dart';

class CardReviewScreen extends StatefulWidget {
  final int deckId;
  final ApiService apiService;

  const CardReviewScreen({
    required this.deckId,
    required this.apiService,
    Key? key,
  }) : super(key: key);

  @override
  _CardReviewScreenState createState() => _CardReviewScreenState();
}

class _CardReviewScreenState extends State<CardReviewScreen> {
  List<anki.Card> _cards = [];
  int _currentIndex = 0;
  bool _showBack = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await widget.apiService.getDueCardsForDeck(widget.deckId);
      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  void _nextCard(String rating) {
    // TODO: Send review result (rating) to backend if needed

    setState(() {
      _showBack = false;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
      } else {
        // All done
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cards.isEmpty) {
      return Scaffold(body: Center(child: Text("No cards due.")));
    }

    final card = _cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Review')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showBack = !_showBack),
            child: Card(
              elevation: 4,
              margin: EdgeInsets.all(16),
              child: Container(
                height: 250,
                alignment: Alignment.center,
                padding: EdgeInsets.all(20),
                child: Text(
                  _showBack ? card.back : card.front,
                  style: TextStyle(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (_showBack)
            Column(
              children: [
                Text("How was it?"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _reviewButton("Again", Colors.red),
                    _reviewButton("Hard", Colors.orange),
                    _reviewButton("Good", Colors.green),
                    _reviewButton("Easy", Colors.blue),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _reviewButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () => _nextCard(label),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}
