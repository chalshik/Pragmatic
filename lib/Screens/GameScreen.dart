import 'package:flutter/material.dart';
import 'package:pragmatic/Models/Question.dart';
import 'package:pragmatic/Providers/QuestionProvider.dart';
import 'package:pragmatic/Screens/GameProcess.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Services/WebSocketService.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Controllers
  final TextEditingController _createUsernameController = TextEditingController();
  final TextEditingController _joinUsernameController = TextEditingController();
  final TextEditingController _gameCodeController = TextEditingController();
  
  // Services
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();
  
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
  bool isWaitingForFirstQuestion = false;

  @override
  void initState() {
    super.initState();
    _webSocketService.connect();
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
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
  void _subscribeToPlayerUpdates(String code, {bool subscribeToQuestions = true}) {
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

    // Subscribe to question updates for all players (not just the one who starts)
    if (subscribeToQuestions) {
      _webSocketService.subscribeToQuestionUpdates(code, (question) {
        print("Received question in lobby: ${question.question}");

        if (mounted) {
          setState(() {
            currentQuestion = question;
            isWaitingForFirstQuestion = false;
            isStartingGame = false;
          });
          
          // Update the provider with the new question
          try {
            if (mounted && context.mounted) {
              final questionProvider = Provider.of<QuestionProvider>(context, listen: false);
              questionProvider.setQuestion(question);
            }
          } catch (e) {
            print("Error setting question in provider: $e");
          }
          
          // Automatically navigate ALL players to GameProcess when question arrives
          if (isInLobby && currentUsername != null && gameCode != null) {
            print("Auto-navigating to GameProcess for user: $currentUsername");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameProcess(
                  gameRoomCode: gameCode!, 
                  username: currentUsername!
                ),
              ),
            );
          }
        }
      });
    }
  }

  // Helper method to show snack bar messages
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message))
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
          isWaitingForFirstQuestion = false;
        });
        _showSnackBar("Game could not be started. Please try again.");
        return;
      }
      
      // Update state to show we're waiting for the first question
      setState(() {
        isStartingGame = false;
        isWaitingForFirstQuestion = true;
      });
      
      // Show loading state while waiting for first question
      _showSnackBar("Game started! Waiting for first question...");
      
      // Set a timeout in case no question is received
      Timer(const Duration(seconds: 15), () {
        if (mounted && isWaitingForFirstQuestion) {
          setState(() {
            isWaitingForFirstQuestion = false;
          });
          _showSnackBar("Timeout waiting for question. Please try again.");
        }
      });
      
    } catch (e) {
      print("Error starting game: $e");
      if (mounted) {
        setState(() {
          isStartingGame = false;
          isWaitingForFirstQuestion = false;
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
      isWaitingForFirstQuestion = false;
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
        Text(
          'Game Lobby',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
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
        
        // Show waiting for question indicator
        if (isWaitingForFirstQuestion) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Game started! Waiting for first question...',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        
        ElevatedButton(
          onPressed: readyToStart && !isStartingGame && !isWaitingForFirstQuestion ? _startGame : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: readyToStart ? Colors.green : Colors.grey,
            foregroundColor: Colors.white,
          ),
          child: (isStartingGame || isWaitingForFirstQuestion)
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Welcome to Game Lobby',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 40),
          
          // Create Game Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a New Game',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _createUsernameController,
                  decoration: const InputDecoration(
                    labelText: "Your Username",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isCreatingGame ? null : onCreateGame,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
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
                      : const Text('Create Game'),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),

          // Join Game Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join an Existing Game',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _joinUsernameController,
                  decoration: const InputDecoration(
                    labelText: "Your Username",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _gameCodeController,
                  decoration: const InputDecoration(
                    labelText: "Game Code",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.code),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isJoiningGame ? null : onJoinGame,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.green,
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
                      : const Text('Join Game'),
                ),
              ],
            ),
          ),
        ],
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isInLobby ? _buildLobbyScreen() : _buildGameSetupScreen(),
        ),
      ),
    );
  }
}