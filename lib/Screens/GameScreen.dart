import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pragmatic/Services/Game_Manager.dart';
import 'package:pragmatic/Services/AuthService.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      final gameManager = Provider.of<GameManager>(context, listen: false);
      
      // Initialize game with user's Firebase UID
      final String userId = auth.getCurrentUserUid() ?? 'default_uid';
      gameManager.initialize(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameManager = context.watch<GameManager>();
    final auth = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Korean Card Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              gameManager.leaveRoom();
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: _buildGameUI(gameManager, auth),
    );
  }

  Widget _buildGameUI(GameManager gameManager, AuthService auth) {
    if (gameManager.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gameManager.currentError != null) {
      return Center(child: Text('Error: ${gameManager.currentError}'));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (gameManager.roomCode != null)
            Text('Room Code: ${gameManager.roomCode}'),
          
          if (gameManager.isInLobby) _buildLobbyUI(gameManager),
          if (gameManager.isGameStarted) _buildGamePlayUI(gameManager),
          if (gameManager.isGameOver) _buildGameOverUI(gameManager),
        ],
      ),
    );
  }

  Widget _buildLobbyUI(GameManager gameManager) {
    return Column(
      children: [
        const Text('Waiting in Lobby...'),
        const SizedBox(height: 20),
        if (gameManager.isHost)
          ElevatedButton(
            onPressed: () => gameManager.startGame(),
            child: const Text('Start Game'),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            gameManager.leaveRoom();
            Navigator.pushReplacementNamed(context, '/home');
          },
          child: const Text('Leave Room'),
        ),
      ],
    );
  }

  Widget _buildGamePlayUI(GameManager gameManager) {
    return Column(
      children: [
        Text('Round ${gameManager.currentRound}'),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              gameManager.currentCard?.front ?? 'Loading card...',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Column(
          children: gameManager.currentOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                onPressed: () => gameManager.submitAnswer(index),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(option),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGameOverUI(GameManager gameManager) {
    return Column(
      children: [
        const Text('Game Over!', style: TextStyle(fontSize: 24)),
        Text('Winner: ${gameManager.gameResult?.winner ?? 'Unknown'}'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            gameManager.resetGame();
            Navigator.pushReplacementNamed(context, '/home');
          },
          child: const Text('Return to Home'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Don't dispose the provider instance itself
    super.dispose();
  }
}