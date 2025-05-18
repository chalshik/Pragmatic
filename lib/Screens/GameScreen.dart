import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Services/WebSocketService.dart';

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
  String? gameCode;
  List<String> players = [];
  bool isCreatingGame = false;
  bool isJoiningGame = false;
  bool isInLobby = false;
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _initWebSocketConnection();
  }

  void _initWebSocketConnection() async {
    try {
      await _webSocketService.connect();
      debugPrint("WebSocket connected successfully in GameScreen");
    } catch (e) {
      debugPrint("Error connecting to WebSocket: $e");
      // Optionally show an error to the user
    }
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _createUsernameController.dispose();
    _joinUsernameController.dispose();
    _gameCodeController.dispose();
    super.dispose();
  }

  // Helper method to parse player data from WebSocket
  List<String> parsePlayersFromData(dynamic playerData) {
    debugPrint("Parsing player data: $playerData");
    
    try {
      // Case 1: Direct list of player names
      if (playerData is List) {
        return playerData.map((e) => e.toString()).toList();
      }
      
      // Case 2: Map containing players as a list
      else if (playerData is Map<String, dynamic>) {
        // Check for 'players' key
        if (playerData.containsKey('players')) {
          final List<dynamic> playersData = playerData['players'];
          return playersData.map((e) => e.toString()).toList();
        }
        
        // Check if there's another key that might contain players
        for (var entry in playerData.entries) {
          if (entry.value is List) {
            return (entry.value as List).map((e) => e.toString()).toList();
          }
        }
      }
      
      // Default: return empty list for unsupported formats
      return [];
    } catch (e) {
      debugPrint("Error parsing player data: $e");
      return [];
    }
  }

  // Method to handle creating a new game
  void onCreateGame() async {
    if (isCreatingGame) return;
    
    setState(() => isCreatingGame = true);
    
    try {
      final String username = _createUsernameController.text.trim();
      if (username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a username"))
        );
        return;
      }

      // Create game and get room code
      final String? roomCode = await _apiService.createGame(username);
      debugPrint("Received room code: $roomCode");
      
      if (roomCode != null && roomCode.isNotEmpty) {
        setState(() {
          gameCode = roomCode;
          currentUsername = username;
          isInLobby = true;
          players = [username]; // Add creator to the initial players list
        });
        
        // Subscribe to player updates
        _subscribeToPlayerUpdates(roomCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create game"))
        );
      }
    } catch (e) {
      debugPrint("Error creating game: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"))
      );
    } finally {
      if (mounted) {
        setState(() => isCreatingGame = false);
      }
    }
  }

  // Method to handle joining an existing game
  void onJoinGame() async {
    if (isJoiningGame) return;
    
    setState(() => isJoiningGame = true);
    
    try {
      final String username = _joinUsernameController.text.trim();
      final String joinCode = _gameCodeController.text.trim().toUpperCase();
      
      if (username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a username"))
        );
        return;
      }
      
      if (joinCode.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a game code"))
        );
        return;
      }

      // Join the game with the provided code
      final bool joinedRoom = await _apiService.joinGame(username, joinCode);
      debugPrint("Joined room result: $joinedRoom");
      
      if (joinedRoom) {
        setState(() {
          gameCode = joinCode;
          currentUsername = username;
          isInLobby = true;
          // Initially add yourself to the player list
          players = [username];
        });
        
        // Subscribe to player updates
        _subscribeToPlayerUpdates(joinCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to join game. Invalid code or game is full."))
        );
      }
    } catch (e) {
      debugPrint("Error joining game: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"))
      );
    } finally {
      if (mounted) {
        setState(() => isJoiningGame = false);
      }
    }
  }

  // Helper method to subscribe to player updates via WebSocket
  void _subscribeToPlayerUpdates(String code) {
    try {
      debugPrint("Subscribing to player updates for room: $code");
      
      _webSocketService.subscribeToPlayerUpdates(code, (playerData) {
        debugPrint("Received player update: $playerData");
        
        if (mounted) {
          setState(() {
            // Parse the players data
            final List<String> updatedPlayers = parsePlayersFromData(playerData);
            players = updatedPlayers;
            
            // Ensure current user is in the list
            if (currentUsername != null && currentUsername!.isNotEmpty && 
                !players.contains(currentUsername)) {
              players.add(currentUsername!);
            }
          });
        }
      });
    } catch (e) {
      debugPrint("Error subscribing to player updates: $e");
      // Show error to user if critical
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to game updates: ${e.toString()}"))
      );
    }
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
            child: ListView.builder(
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
          onPressed: () {
            // Logic to start the game - would be implemented later
            // This could send a WebSocket message to all players
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('Start Game', style: TextStyle(fontSize: 18)),
        ),
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
                  onPressed: onCreateGame,
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
                  onPressed: onJoinGame,
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
                onPressed: () {
                  setState(() {
                    isInLobby = false;
                    gameCode = null;
                    players = [];
                    currentUsername = null;
                  });
                },
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