import 'package:flutter/material.dart';
import 'package:pragmatic/Models/Question.dart';

import 'package:flutter/foundation.dart'; // Make sure the model is imported

class QuestionProvider extends ChangeNotifier {
  Question? _currentQuestion;

  Question? get currentQuestion => _currentQuestion;

  // Set a new question
  void setQuestion(Question question) {
    _currentQuestion = question;
    notifyListeners();
  }

  // Clear current question
  void clearQuestion() {
    _currentQuestion = null;
    notifyListeners();
  }
 
}
