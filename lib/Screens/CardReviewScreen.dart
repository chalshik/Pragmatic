import 'package:flutter/material.dart';
import 'package:pragmatic/Models/Card.dart' as anki;
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Models/ReviewRequest.dart';
import 'package:pragmatic/Models/Review.dart';

class CardReviewScreen extends StatefulWidget {
  final int deckId;
  final ApiService apiService;

  const CardReviewScreen({
    required this.deckId,
    required this.apiService,
    super.key,
  });

  @override
  _CardReviewScreenState createState() => _CardReviewScreenState();
}

class _CardReviewScreenState extends State<CardReviewScreen> {
  List<anki.Card> _cards = [];
  int _currentIndex = 0;
  bool _showBack = false;
  bool _isLoading = true;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await widget.apiService.getCardsForDeck(widget.deckId);

      // ✅ Log each card's content
      for (var card in cards) {
        print(
          '📋 Loaded card: ID=${card.id}, Front="${card.front}", Back="${card.back}"',
        );
      }

      setState(() {
        _cards = cards;
        _remaining = cards.length;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Failed to load cards for deck ID ${widget.deckId}');
      print('🛑 Error: $e');
      print('📌 Stack trace:\n$stackTrace');
    }
  }

  void _nextCard(String label) async {
    final currentCard = _cards[_currentIndex];

    // Convert string label to enum
    final ratingMap = {
      "Again": Rating.AGAIN,
      "Hard": Rating.HARD,
      "Good": Rating.GOOD,
      "Easy": Rating.EASY,
    };

    final rating = ratingMap[label];

    if (rating == null) {
      print('⚠️ Invalid rating label: $label');
      return;
    }

    try {
      final request = ReviewRequest(cardId: currentCard.id, rating: rating);
      await widget.apiService.processReview(request);
      print(
        '✅ Review processed for card ID ${currentCard.id} with rating $rating',
      );
    } catch (e) {
      print('❌ Failed to process review for card ID ${currentCard.id}: $e');
    }

    setState(() {
      _showBack = false;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
        _remaining = _cards.length - _currentIndex;
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                "No cards due",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Back to Decks"),
              ),
            ],
          ),
        ),
      );
    }

    final card = _cards[_currentIndex];
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Review'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Remaining: $_remaining',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
        ],
      ),
      body: Column(
        children: [
          // Card content - expanded to fill available space
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showBack = !_showBack),
              child: Container(
                margin: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Card content
                    Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          _showBack ? card.back : card.front,
                          style: TextStyle(
                            fontSize: 24, 
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Indicator for which side is showing
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _showBack ? "BACK" : "FRONT",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Review buttons
          if (_showBack)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ankiStyleButton("Again", Colors.red.shade500),
                  _ankiStyleButton("Hard", Colors.orange.shade600),
                  _ankiStyleButton("Good", Colors.green.shade600),
                  _ankiStyleButton("Easy", Colors.blue.shade600),
                ],
              ),
            ),
          
          // Space at the bottom for better ergonomics
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _ankiStyleButton(String label, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () => _nextCard(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
