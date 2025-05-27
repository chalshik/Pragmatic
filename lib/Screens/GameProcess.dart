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
  final bool _isConnecting = false;
  Question? _lastQuestion;
  int _questionCount = 0;
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
    
    // Subscribe to game end events
    print("🏁 GameProcess: Subscribing to game end events");
    _webSocketService.subscribeToGameEnd(widget.gameRoomCode, _onGameEnd);
    
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
      
      // Don't force finish the game - let the server handle game end
      print("📋 Question $_questionCount received, waiting for next question or game end from server");
    }
  }

  void _onGameEnd(Map<String, dynamic> gameEndData) {
    print("🏆 [GameProcess] Game ended! Received scores: $gameEndData");
    print("🏆 [GameProcess] gameEndData type: ${gameEndData.runtimeType}");
    print("🏆 [GameProcess] gameEndData keys: ${gameEndData.keys.toList()}");
    
    if (mounted) {
      // Show game end dialog with scores
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: const Text('🏆 Game Completed!'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Final Scores:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildScoresList(gameEndData),
                  ],
                ),
              ),
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
    } else {
      print("🏆 [GameProcess] Widget not mounted, cannot show dialog");
    }
  }

  Widget _buildScoresList(Map<String, dynamic> gameEndData) {
    try {
      // Parse scores from the game end data
      // The server returns a Map where key is player name and value is score
      Map<String, dynamic> scoresMap = gameEndData;
      
      if (scoresMap.isEmpty) {
        return const Text('No scores available');
      }
      
      // Convert map to list of entries for sorting
      List<MapEntry<String, dynamic>> scoreEntries = scoresMap.entries.toList();
      
      // Sort scores in descending order
      scoreEntries.sort((a, b) {
        int scoreA = (a.value is int) ? a.value : (a.value as num).toInt();
        int scoreB = (b.value is int) ? b.value : (b.value as num).toInt();
        return scoreB.compareTo(scoreA);
      });
      
      return Column(
        children: scoreEntries.asMap().entries.map((entry) {
          int index = entry.key;
          String username = entry.value.key;
          int score = (entry.value.value is int) ? entry.value.value : (entry.value.value as num).toInt();
          bool isCurrentUser = username == widget.username;
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: isCurrentUser ? Border.all(color: Colors.blue, width: 2) : null,
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    username,
                    style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$score pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  const Text('(You)', style: TextStyle(color: Colors.blue)),
                ],
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      print("❌ Error building scores list: $e");
      return Text('Error displaying scores: $e');
    }
  }

  @override
  void dispose() {
    // Unsubscribe from questions and game end when leaving GameProcess
    _webSocketService.unsubscribeFromQuestions(widget.gameRoomCode);
    _webSocketService.unsubscribeFromGameEnd(widget.gameRoomCode);
    print("🔄 GameProcess unsubscribed from questions and game end on dispose");
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
      
      print("🎯 [DEBUG] Submitting answer:");
      print("🎯 [DEBUG] - Username: ${widget.username}");
      print("🎯 [DEBUG] - Game room: ${widget.gameRoomCode}");
      print("🎯 [DEBUG] - Selected index: $index");
      print("🎯 [DEBUG] - Question count: $_questionCount");
      print("🎯 [DEBUG] - Answer payload: $answer");
      
      _webSocketService.sendMessage("/app/game/submit", answer);
      
      setState(() {
        _hasSubmittedAnswer = true;
      });
      
      print("✅ Answer submitted successfully: $index");
      
      // Show confirmation to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Answer submitted: $index'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("❌ Error submitting answer: $e");
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
        title: Text('Question ${_questionCount > 0 ? _questionCount : 1}'),
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
            
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  
                  // Game info indicator
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
                          'Question $_questionCount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Game Code: ${widget.gameRoomCode}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
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
                    }),
                    
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}