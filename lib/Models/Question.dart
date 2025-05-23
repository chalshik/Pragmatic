class Question {
  String question;
  String answer;
  List<String> options;

  Question({
    required this.question,
    required this.answer,
    required this.options,
  });

  // From JSON factory
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      question: json['question'] as String,
      answer: json['answer'] as String,
      options: List<String>.from(json['options']),
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'options': options,
    };
  }
}
