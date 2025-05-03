class Deck {
  final int id;
  final String title;
  final int userId;

  Deck({
    required this.id,
    required this.title,
    required this.userId,
  });

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
    id: json['id'],
    title: json['title'],
    userId: json['userId'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'userId': userId,
  };
}