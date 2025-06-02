class Card {
  final int id;
  final int deckId;
  final int userId;
  final String front;
  final String back;
  final String? context;
  final int? bookId;

  Card({
    required this.id,
    required this.deckId,
    required this.userId,
    required this.front,
    required this.back,
    this.context,
    this.bookId,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
  print('🧩 Raw card JSON: $json');

  return Card(
    id: json['id'],
    deckId: json['deck']?['id'], // safely get nested ID
    userId: json['user']?['id'],
    front: json['front'],
    back: json['back'],
    context: json['context'],
    bookId: json['bookId'], // this is already at top-level
  );
}



  Map<String, dynamic> toJson() => {
    'id': id,
    'deckId': deckId,
    'userId': userId,
    'front': front,
    'back': back,
    if (context != null) 'context': context,
    if (bookId != null) 'bookId': bookId,
  };
}