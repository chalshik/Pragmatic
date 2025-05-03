class Book {
  final int id;
  final int userId;
  final String title;

  Book({
    required this.id,
    required this.userId,
    required this.title,
  }) {
    if (title.isEmpty) {
      throw ArgumentError('Title is required');
    }
    if (title.length > 255) {
      throw ArgumentError('Title must be between 1 and 255 characters');
    }
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      userId: json['userId'],
      title: json['title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
    };
  }
}