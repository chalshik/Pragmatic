import 'Review.dart';

class ReviewRequest {
  final int cardId;
  final Rating rating;

  ReviewRequest._internal({
    required this.cardId,
    required this.rating,
  });

  factory ReviewRequest({
    required int cardId,
    required Rating rating,
  }) {
    if (!Rating.values.contains(rating)) {
      throw ArgumentError('Rating must be one of: again, hard, good, easy');
    }

    return ReviewRequest._internal(
      cardId: cardId,
      rating: rating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'rating': rating.toString().split('.').last.toLowerCase(),
    };
  }

  factory ReviewRequest.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('cardId')) {
      throw ArgumentError('Card ID is required');
    }
    if (!json.containsKey('rating')) {
      throw ArgumentError('Rating is required');
    }

    final ratingStr = json['rating'].toString().toUpperCase();
    try {
      return ReviewRequest(
        cardId: json['cardId'],
        rating: Rating.values.firstWhere(
          (e) => e.toString() == 'Rating.$ratingStr',
          orElse: () => throw ArgumentError('Rating must be one of: again, hard, good, easy'),
        ),
      );
    } catch (e) {
      throw ArgumentError('Rating must be one of: again, hard, good, easy');
    }
  }
}