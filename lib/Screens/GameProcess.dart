import 'package:flutter/material.dart';
import 'package:pragmatic/Models/Question.dart';
import 'package:pragmatic/Providers/QuestionProvider.dart';
import 'package:pragmatic/Services/WebSocketService.dart';
import 'package:pragmatic/Widgets/options.dart';
import 'package:provider/provider.dart';

class GameProcess extends StatefulWidget {
  final String username;
  final String gameRoomCode;
  final WebSocketService webSocketService;
  
  const GameProcess({
    super.key,
    required this.username,
    required this.gameRoomCode,
    required this.webSocketService,
  });

  @override
  State<GameProcess> createState() => _GameProcessState();
}

class _GameProcessState extends State<GameProcess> {
  bool _hasSubmittedAnswer = false;
  bool _isConnecting = false;
  Question? _lastQuestion;
  int _questionCount = 0;
  static const int maxQuestions = 20;
  late WebSocketService _webSocketService;

  @override
  void initState() {
    super.initState();
    _webSocketService = widget.webSocketService;
    _initializeGameProcess();
  }

  void _initializeGameProcess() async {
    print("🎮 GameProcess: Initializing...");
    
    // Wait a moment for navigation to complete
    await Future.delayed(Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    print("🔌 GameProcess: Checking WebSocket connection...");
    
    // Ensure WebSocket is connected
    if (!_webSocketService.isConnected) {
      print("❌ GameProcess: WebSocket not connected, attempting to connect...");
      try {
        await _webSocketService.connect();
      } catch (e) {
        print("❌ GameProcess: Failed to connect WebSocket: $e");
        return;
      }
    }
    
    print("✅ GameProcess: WebSocket is connected");
    
    // Check if we already have a question from GameScreen
    try {
      final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
      final currentQuestion = questionProvider.currentQuestion;
      
      if (currentQuestion != null) {
        print("📋 GameProcess: Found existing question from GameScreen: ${currentQuestion.question}");
        setState(() {
          _questionCount = 1; // We have the first question
          _hasSubmittedAnswer = false;
          _lastQuestion = currentQuestion;
        });
        
        // Continue subscription for subsequent questions
        print("📞 GameProcess: Continuing subscription for subsequent questions");
        _webSocketService.subscribeToQuestionUpdates(widget.gameRoomCode, _onQuestionReceived);
      } else {
        print("📞 GameProcess: No existing question, subscribing to questions for game: ${widget.gameRoomCode}");
        _webSocketService.subscribeToQuestionUpdates(widget.gameRoomCode, _onQuestionReceived);
      }
    } catch (e) {
      print("❌ GameProcess: Error checking existing question: $e");
      // Fallback to normal subscription
      print("📞 GameProcess: Fallback - subscribing to questions for game: ${widget.gameRoomCode}");
      _webSocketService.subscribeToQuestionUpdates(widget.gameRoomCode, _onQuestionReceived);
    }
  }

  void _onQuestionReceived(Question question) {
    print("📥 Received new question in GameProcess: ${question.question}");
    
    if (mounted) {
      setState(() {
        _questionCount++;
        _hasSubmittedAnswer = false; // Reset for new question
        _lastQuestion = question;
      });
      
      // Update the provider with the new question
      try {
        final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
        questionProvider.setQuestion(question);
        print("✅ Question set in provider successfully");
      } catch (e) {
        print("❌ Error setting question in provider: $e");
      }
      
      // Check if we've reached the maximum number of questions
      if (_questionCount >= maxQuestions) {
        print("🎉 Reached max questions, finishing game");
        _finishGame();
      }
    }
  }

  void _finishGame() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Game Complete!'),
            content: const Text('You have completed all 20 questions. Thank you for playing!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
                child: const Text('Return to Home'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Unsubscribe from questions when leaving GameProcess
    _webSocketService.unsubscribeFromQuestions(widget.gameRoomCode);
    print("🔄 GameProcess unsubscribed from questions on dispose");
    super.dispose();
  }

  void submitAnswer(int index, Question currentQuestion) {
    if (_hasSubmittedAnswer) {
      print("Answer already submitted for this question");
      return;
    }

    if (!_webSocketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to server. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final answer = {
        "username": widget.username,
        "gameroom": widget.gameRoomCode,
        "index": index,
      };
      
      _webSocketService.sendMessage("/app/game/submit", answer);
      
      setState(() {
        _hasSubmittedAnswer = true;
      });
      
      print("Selected option: $index");
      
      // Show confirmation to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Answer submitted: $index'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error submitting answer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit answer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_questionCount > 0 ? _questionCount : 1}/$maxQuestions'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevent back button Hero conflict
      ),
      floatingActionButton: null, // Explicitly disable FAB to prevent Hero conflicts
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<QuestionProvider>(
          builder: (context, questionProvider, child) {
            final currentQuestion = questionProvider.currentQuestion;
            
            // Add safety check for context and provider
            if (questionProvider == null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading game state...'),
                  ],
                ),
              );
            }
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Progress indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Question ${_questionCount} of $maxQuestions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _questionCount / maxQuestions,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Connection status
                  if (_isConnecting) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text('Connecting to server...'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Question display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      currentQuestion != null 
                          ? currentQuestion.question 
                          : "Waiting for first question...",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options
                  if (currentQuestion != null) ...[
                    const Text(
                      'Choose your answer:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Map through options
                    ...currentQuestion.options.asMap().entries.map((entry) {
                      int index = entry.key;
                      String option = entry.value;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: BlockButton(
                            text: option,
                            onPressed: (_hasSubmittedAnswer || _isConnecting) ? null : () {
                              submitAnswer(index, currentQuestion);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                    
                    if (_hasSubmittedAnswer) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Answer submitted! Waiting for next question...',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Waiting for first question...',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}