class Deck {
  final int id;
  final String title;
  final int userId;

  Deck({
    required this.id,
    required this.title,
    required this.userId,
  });

  factory Deck.fromJson(Map<String, dynamic> json) {
    int? userId = json['userId'];
    if (userId == null && json['user'] != null && json['user']['id'] != null) {
      userId = json['user']['id'];
    }
    if (json['id'] == null || userId == null || json['title'] == null) {
      print('Deck.fromJson error: missing field(s) in json: $json');
      throw Exception('Deck.fromJson: missing required field(s)');
    }
    return Deck(
      id: json['id'],
      title: json['title'],
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'userId': userId,
  };
}