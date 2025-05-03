enum Rating { AGAIN, HARD, GOOD, EASY }

class Review {
  final int id;
  final int userId;
  final int cardId;
  final DateTime reviewDate;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final Rating? lastResult;

  Review({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.reviewDate,
    required this.easeFactor,
    required this.interval,
    required this.repetitions,
    this.lastResult,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['userId'],
      cardId: json['cardId'],
      reviewDate: DateTime.parse(json['reviewDate']),
      easeFactor: json['easeFactor'].toDouble(),
      interval: json['interval'],
      repetitions: json['repetitions'],
      lastResult: json['lastResult'] != null ? Rating.values.firstWhere(
        (e) => e.toString() == 'Rating.${json['lastResult']}'
      ) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'cardId': cardId,
      'reviewDate': reviewDate.toIso8601String(),
      'easeFactor': easeFactor,
      'interval': interval,
      'repetitions': repetitions,
      'lastResult': lastResult?.toString().split('.').last,
    };
  }
}