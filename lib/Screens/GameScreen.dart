import 'package:flutter/material.dart';
import 'package:pragmatic/Services/ApiService.dart';
import 'package:pragmatic/Services/WebSocketService.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final WebSocketService webSocketService = WebSocketService();
  List<String> players = [];
  final ApiService apiService = ApiService();
  String? gameCode;
  bool isConnecting = false;
  @override
  void initState() {
    super.initState();
    webSocketService.connect();
  }

  @override
  void dispose() {
    webSocketService.disconnect();
    _usernameController.dispose();
    super.dispose();
  }

  List<String> parsePlayersFromData(dynamic playerData) {
    // playerData is expected to be a List<dynamic> containing strings
    if (playerData is List) {
      return playerData.map((e) => e.toString()).toList();
    } else {
      return [];
    }
  }

  void onCreateGame() async {
    if (isConnecting) return;
    setState(() => isConnecting = true);
    String username = _usernameController.text.trim();
    if (username.isEmpty) {
      // Optionally show error here
      setState(() => isConnecting = false);
      return;
    }
    String? createdGameCode = await apiService.createGame(username);
    if (createdGameCode != null) {
      setState(() {
        gameCode = createdGameCode;
      });
      webSocketService.subscribeToPlayerUpdates(gameCode!, (playerData) {
        print("Players in room $gameCode updated: $playerData");
        setState(() {
          players = parsePlayersFromData(playerData);
          players.add(username);
        });
      });
    }
    setState(() => isConnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Username",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: onCreateGame,
              child:
                  isConnecting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Create game"),
            ),
            SizedBox(height: 10),
            if (gameCode != null) ...[
              Text('Game Code: $gameCode', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              Text('Players:', style: TextStyle(fontSize: 16)),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    return ListTile(title: Text(players[index]));
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
