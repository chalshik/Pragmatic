import 'package:flutter/material.dart';
import 'package:pragmatic/Models/Question.dart';
import 'package:pragmatic/Providers/QuestionProvider.dart';
import 'package:pragmatic/Screens/GameProcess.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Services/WebSocketService.dart';
import 'package:pragmatic/Services/QrCodeService.dart';
import 'package:provider/provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _createUsernameController = TextEditingController();
  final TextEditingController _joinUsernameController = TextEditingController();
  final TextEditingController _gameCodeController = TextEditingController();
  
  // Services
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  
  // Tab Controller
  late TabController _tabController;
  
  // State variables
  Question? currentQuestion;
  String? gameCode;
  List<String> players = [];
  bool isCreatingGame = false;
  bool isJoiningGame = false;
  bool isInLobby = false;
  String? currentUsername;
  bool readyToStart = false;
  bool isStartingGame = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _webSocketService.connect();
  }

  @override
  void dispose() {
    // Clean up all subscriptions before disconnecting
    if (gameCode != null) {
      _webSocketService.unsubscribeFromPlayerUpdates(gameCode!);
      _webSocketService.unsubscribeFromGameStatus(gameCode!);
      // DON'T unsubscribe from game end events - let GameProcess handle this
      // to ensure continuous subscription without gaps
      // _webSocketService.unsubscribeFromGameEnd(gameCode!);
    }
    // DON'T disconnect WebSocket as it will be used in GameProcess
    // _webSocketService.disconnect();
    _tabController.dispose();
    _createUsernameController.dispose();
    _joinUsernameController.dispose();
    _gameCodeController.dispose();
    super.dispose();
  }

  List<String> parsePlayersFromData(dynamic playerData) {
    try {
      print("Parsing playerData: $playerData (type: ${playerData.runtimeType})");

      if (playerData is List) {
        return playerData.map((e) {
          if (e is Map<String, dynamic>) {
            return e['id']?.toString() ?? e['username']?.toString() ?? 'Unknown';
          }
          return e.toString();
        }).toList();
      }

      if (playerData is Map<String, dynamic>) {
        if (playerData.containsKey('players') && playerData['players'] is List) {
          return parsePlayersFromData(playerData['players']);
        }
        return [playerData['id']?.toString() ?? 'Unknown'];
      }

      return [playerData.toString()];
    } catch (e, stack) {
      print("Error parsing players: $e");
      print(stack);
      return [];
    }
  }

  // Method to handle creating a new game
  void onCreateGame() async {
    if (isCreatingGame) return;
    
    setState(() => isCreatingGame = true);
    
    final String username = _createUsernameController.text.trim();
    if (username.isEmpty) {
      _showSnackBar("Please enter a username");
      setState(() => isCreatingGame = false);
      return;
    }

    try {
      final String? createdGameCode = await _apiService.createGame(username);
      
      if (createdGameCode != null) {
        setState(() {
          gameCode = createdGameCode;
          currentUsername = username;
          isInLobby = true;
          players = [username]; // Add creator to the initial players list
          readyToStart = false; // Creator needs to wait for other players
        });
        
        // Subscribe to player updates
        _subscribeToPlayerUpdates(createdGameCode);
      } else {
        _showSnackBar("Failed to create game");
      }
    } catch (e) {
      print("Error creating game: $e");
      _showSnackBar("Failed to create game: $e");
    }
    
    setState(() => isCreatingGame = false);
  }

  // Method to handle joining an existing game
  void onJoinGame() async {
    if (isJoiningGame) return;
    
    setState(() => isJoiningGame = true);
    
    final String username = _joinUsernameController.text.trim();
    final String joinCode = _gameCodeController.text.trim().toUpperCase();
    
    if (username.isEmpty) {
      _showSnackBar("Please enter a username");
      setState(() => isJoiningGame = false);
      return;
    }
    
    if (joinCode.isEmpty) {
      _showSnackBar("Please enter a game code");
      setState(() => isJoiningGame = false);
      return;
    }

    try {
      final List<String>? joinedRoom = await _apiService.joinGame(username, joinCode);
      
      if (joinedRoom != null) {
        setState(() {
          gameCode = joinCode;
          currentUsername = username;
          isInLobby = true;
          players = joinedRoom;
          readyToStart = players.length > 1;
        });
        
        // Subscribe to player updates
        _subscribeToPlayerUpdates(joinCode);
      } else {
        _showSnackBar("Failed to join game");
      }
    } catch (e) {
      print("Error joining game: $e");
      _showSnackBar("Failed to join game: $e");
    }
    
    setState(() => isJoiningGame = false);
  }

  // Helper method to subscribe to player updates via WebSocket
  void _subscribeToPlayerUpdates(String code) {
    // Subscribe to player updates
    _webSocketService.subscribeToPlayerUpdates(code, (List<Map<String, dynamic>> playerData) {
      print("Players raw data in room $code updated: $playerData");
      try {
        if (mounted) {
          setState(() {
            players = parsePlayersFromData(playerData);
            print("players type: ${players.runtimeType}, contents: $players");
            readyToStart = players.length > 1;
          });
        }
      } catch (e, stack) {
        print("Error parsing or setting players: $e");
        print(stack);
      }
    });
    
    // Subscribe to game end events early to not miss them
    print("🏁 GameScreen: Subscribing to game end events for $code");
    _webSocketService.subscribeToGameEnd(code, (Map<String, dynamic> gameEndData) {
      print("🏆 Game end received in GameScreen: $gameEndData");
      if (mounted) {
        // If we're still in GameScreen when game ends, show results here
        _showGameEndDialog(gameEndData);
      }
    });
    
    // Subscribe to game status updates for navigation
    _webSocketService.subscribeToGameStatus(code, (Map<String, dynamic> statusData) {
      print("Game status received: $statusData");
      if (mounted) {
        String? status = statusData['status'];
        String? message = statusData['message'];
        
        if (status == 'STARTING') {
          if (message != null) {
            _showSnackBar(message); // "Game will begin in 5 seconds"
          }
          
          // Clear the question provider to ensure clean state
          try {
            if (mounted && context.mounted) {
              final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
              questionProvider.clearQuestion();
            }
          } catch (e) {
            print("Error clearing question in provider: $e");
          }
          
          // Subscribe to questions and wait for first question before navigating
          print("🔔 Subscribing to questions after STARTING status received");
          _webSocketService.subscribeToQuestionUpdates(code, (Question firstQuestion) async {
            print("📥 First question received in GameScreen: ${firstQuestion.question}");
            
            if (!mounted || !context.mounted) {
              print("⚠️ Widget not mounted, skipping navigation");
              return;
            }
            
            // Set the question in provider before navigating
            try {
              final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
              questionProvider.setQuestion(firstQuestion);
              print("✅ First question set in provider before navigation");
            } catch (e) {
              print("❌ Error setting first question in provider: $e");
              return;
            }
            
            // Now navigate to GameProcess with the question ready
            print("🎮 Navigating to GameProcess with first question ready");
            
            // Add a small delay to prevent Hero widget conflicts
            await Future.delayed(const Duration(milliseconds: 200));
            
            if (mounted && context.mounted) {
              try {
                // Use pushReplacement with explicit Hero tag handling
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => GameProcess(
                      gameRoomCode: code, 
                      username: currentUsername!,
                      webSocketService: _webSocketService,
                    ),
                    transitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    settings: const RouteSettings(name: '/game-process'),
                  ),
                );
                print("✅ Navigation to GameProcess completed");
              } catch (e) {
                print("❌ Error during navigation: $e");
              }
            } else {
              print("⚠️ Context no longer mounted, navigation cancelled");
            }
          });
        }
      }
    });
  }

  // Helper method to show snack bar messages
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
      );
    }
  }

  // Helper method to show game end dialog with scores
  void _showGameEndDialog(Map<String, dynamic> gameEndData) {
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

  // Helper method to build scores list
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
      
      // Parse scores from the game end data
      // The server returns a Map where key is player name and value is score
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
          bool isCurrentUser = username == currentUsername;
          
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
      print("❌ Error building scores list in GameScreen: $e");
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

  // Method to handle starting the game
  void _startGame() async {
    if (isStartingGame || gameCode == null) return;
    
    setState(() => isStartingGame = true);
    
    try {
      // Start the game on the server
      final bool started = await _apiService.startGame(gameCode!);
      
      if (!mounted) return;
      
      if (!started) {
        setState(() {
          isStartingGame = false;
        });
        _showSnackBar("Game could not be started. Please try again.");
        return;
      }
      
      setState(() => isStartingGame = false);
      _showSnackBar("Game started! Players will be moved to the game screen shortly.");
      
    } catch (e) {
      print("Error starting game: $e");
      if (mounted) {
        setState(() {
          isStartingGame = false;
        });
        _showSnackBar("Error starting game: $e");
      }
    }
  }

  // Method to leave the lobby
  void _leaveLobby() {
    setState(() {
      isInLobby = false;
      gameCode = null;
      players = [];
      currentUsername = null;
      currentQuestion = null;
      readyToStart = false;
    });
    
    // Clear text controllers
    _createUsernameController.clear();
    _joinUsernameController.clear();
    _gameCodeController.clear();
  }

  // UI for the game lobby screen
  Widget _buildLobbyScreen() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue)
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Game Code: $gameCode',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Share this code with friends to join'),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      QrCodeService.showGameCodeDialog(
                        context: context,
                        gameCode: gameCode!,
                      );
                    },
                    icon: const Icon(Icons.qr_code),
                    iconSize: 32,
                    tooltip: 'Show QR Code',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Players (${players.length})', 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: players.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for players...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          player,
                          style: TextStyle(
                            fontWeight: player == currentUsername 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: player == currentUsername 
                            ? const Text('(You)', style: TextStyle(color: Colors.blue))
                            : null,
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 20),
        
        ElevatedButton(
          onPressed: readyToStart && !isStartingGame ? _startGame : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: readyToStart ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: isStartingGame
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Text(
                  readyToStart 
                    ? "Start Game" 
                    : "Waiting for Players",
                  style: const TextStyle(fontSize: 18),
                ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // UI for the initial screen with create/join options
  Widget _buildGameSetupScreen() {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primary,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.add_circle_outline),
                text: 'Create Game',
              ),
              Tab(
                icon: Icon(Icons.group_add),
                text: 'Join Game',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCreateGameTab(),
              _buildJoinGameTab(),
            ],
          ),
        ),
      ],
    );
  }

  // Create Game Tab Content
  Widget _buildCreateGameTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Create New Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new game room and invite friends to join',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _createUsernameController,
                    decoration: const InputDecoration(
                      labelText: "Your Username",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isCreatingGame ? null : onCreateGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isCreatingGame
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle),
                                SizedBox(width: 8),
                                Text('Create Game Room', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Join Game Tab Content
  Widget _buildJoinGameTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.group_add, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Join Existing Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a game code to join an existing room',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _joinUsernameController,
                    decoration: const InputDecoration(
                      labelText: "Your Username",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _gameCodeController,
                    decoration: InputDecoration(
                      labelText: "Game Code",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.code),
                      suffixIcon: IconButton(
                        onPressed: () {
                          QrCodeService.openQrScanner(
                            context: context,
                            onQrCodeScanned: (scannedCode) {
                              setState(() {
                                _gameCodeController.text = scannedCode.toUpperCase();
                              });
                              _showSnackBar("Game code scanned: $scannedCode");
                            },
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Scan QR Code',
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Enter 6-character code",
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isJoiningGame ? null : onJoinGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isJoiningGame
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login),
                                SizedBox(width: 8),
                                Text('Join Game Room', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
        centerTitle: true,
        // Add a back button when in lobby to return to the setup screen
        leading: isInLobby
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _leaveLobby,
              )
            : null,
      ),
      // Explicitly disable FAB to prevent Hero conflicts during navigation
      floatingActionButton: null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isInLobby ? _buildLobbyScreen() : _buildGameSetupScreen(),
        ),
      ),
    );
  }
}