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

class _GameProcessState extends State<GameProcess> with TickerProviderStateMixin {
  bool _hasSubmittedAnswer = false;
  final bool _isConnecting = false;
  Question? _lastQuestion;
  int _questionCount = 0;
  late WebSocketService _webSocketService;
  late AnimationController _submitAnimationController;
  late Animation<double> _submitAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Kahoot-like colors
  final List<Color> optionColors = [
    const Color(0xFFE21B3C), // Red
    const Color(0xFF1368CE), // Blue  
    const Color(0xFFD89E00), // Yellow
    const Color(0xFF26890C), // Green
  ];

  final List<IconData> optionIcons = [
    Icons.crop_square,
    Icons.circle,
    Icons.change_history,
    Icons.diamond,
  ];

  @override
  void initState() {
    super.initState();
    _webSocketService = widget.webSocketService;
    
    // Subscribe to game end events IMMEDIATELY to ensure no gaps
    print("🏁 GameProcess: Subscribing to game end events immediately");
    _webSocketService.subscribeToGameEnd(widget.gameRoomCode, _onGameEnd);
    
    // Initialize animations
    _submitAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _submitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _submitAnimationController, curve: Curves.elasticOut),
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _initializeGameProcess();
  }

  @override
  void dispose() {
    _submitAnimationController.dispose();
    _pulseController.dispose();
    // Unsubscribe from questions and game end when leaving GameProcess
    _webSocketService.unsubscribeFromQuestions(widget.gameRoomCode);
    _webSocketService.unsubscribeFromGameEnd(widget.gameRoomCode);
    print("🔄 GameProcess unsubscribed from questions and game end on dispose");
    super.dispose();
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
      
      // Reset animations for new question
      _submitAnimationController.reset();
      _pulseController.reset();
      
      // Update the provider with the new question
      try {
        final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
        questionProvider.setQuestion(question);
        print("✅ Question set in provider successfully");
      } catch (e) {
        print("❌ Error setting question in provider: $e");
      }
      
      print("📋 Question $_questionCount received, waiting for next question or game end from server");
    }
  }

  void _onGameEnd(Map<String, dynamic> gameEndData) {
    print("🏆 [GameProcess] Game ended! Received scores: $gameEndData");
    
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
    }
  }

  Widget _buildScoresList(Map<String, dynamic> gameEndData) {
    try {
      print("🏆 [DEBUG] Building scores list with data: $gameEndData");
      
      // Check if we received the malformed {"g":3} format
      if (gameEndData.containsKey("g") && gameEndData.length == 1) {
        print("⚠️ [DEBUG] Received malformed game end data: $gameEndData");
        return Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Game completed, but scores are not available.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Server sent: $gameEndData',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This appears to be a server-side issue with the scores format.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
      
      Map<String, dynamic> scoresMap = gameEndData;
      
      if (scoresMap.isEmpty) {
        return const Text('No scores available');
      }
      
      // Validate that all entries are player name -> score pairs
      bool hasValidScores = scoresMap.entries.every((entry) {
        return entry.key is String && 
               (entry.value is int || entry.value is num) &&
               entry.key.isNotEmpty;
      });
      
      if (!hasValidScores) {
        print("⚠️ [DEBUG] Invalid scores format detected: $gameEndData");
        return Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Invalid scores format received from server.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Expected: {"player1": score1, "player2": score2}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Received: $gameEndData',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
      
      List<MapEntry<String, dynamic>> scoreEntries = scoresMap.entries.toList();
      
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
      return Column(
        children: [
          const Icon(
            Icons.error,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error displaying scores: $e',
            style: const TextStyle(fontSize: 14, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Raw data: $gameEndData',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  void submitAnswer(int index, Question currentQuestion) {
    if (_hasSubmittedAnswer) {
      print("Answer already submitted for this question");
      return;
    }

    if (!_webSocketService.isConnected) {
      return; // Removed snackbar
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
      
      // Start animations
      _submitAnimationController.forward();
      _pulseController.repeat(reverse: true);
      
      print("✅ Answer submitted successfully: $index");
      
      // Removed snackbar - no visual feedback needed as we have animated UI
    } catch (e) {
      print("❌ Error submitting answer: $e");
      // Removed error snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E), // Dark Kahoot-like background
      appBar: AppBar(
        title: Text(
          'Question $_questionCount',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.gameRoomCode,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
      body: Consumer<QuestionProvider>(
        builder: (context, questionProvider, child) {
          final currentQuestion = questionProvider.currentQuestion;
          
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6C5CE7),
                  Color(0xFF1E1E2E),
                ],
                stops: [0.0, 0.3],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Question Card
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (currentQuestion != null) ...[
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _hasSubmittedAnswer ? _pulseAnimation.value : 1.0,
                                    child: Text(
                                      currentQuestion.question,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2D3436),
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                            ] else ...[
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Waiting for question...',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF636E72),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    
                    // Answer Options
                    Expanded(
                      flex: 4,
                      child: currentQuestion != null
                          ? GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: currentQuestion.options.length,
                              itemBuilder: (context, index) {
                                final option = currentQuestion.options[index];
                                final color = optionColors[index % optionColors.length];
                                final icon = optionIcons[index % optionIcons.length];
                                
                                return AnimatedBuilder(
                                  animation: _submitAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _hasSubmittedAnswer 
                                          ? 0.95 + (0.05 * _submitAnimation.value)
                                          : 1.0,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: (_hasSubmittedAnswer || _isConnecting) 
                                              ? null 
                                              : () => submitAnswer(index, currentQuestion),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _hasSubmittedAnswer 
                                                  ? color.withOpacity(0.7)
                                                  : color,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: color.withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  icon,
                                                  size: 32,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(height: 12),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text(
                                                    option,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 3,
                              ),
                            ),
                    ),
                    
                    // Status indicator (replaces the waiting message)
                    if (_hasSubmittedAnswer)
                      AnimatedBuilder(
                        animation: _submitAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _submitAnimation.value,
                            child: Container(
                              margin: const EdgeInsets.only(top: 20),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B894),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00B894).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Answer Submitted!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}