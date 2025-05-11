import 'package:flutter/material.dart';
import 'package:pragmatic/Models/Card.dart' as CardModel;
import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Services/WebSocketService.dart';
import 'package:pragmatic/Services/room_creator.dart';
import 'package:pragmatic/Services/Room_joiner.dart';
import 'dart:convert';

class GameResult {
  final String winner;
  
  GameResult({required this.winner});
}

class GameManager extends ChangeNotifier {
  late final WebSocketService _wsService;
  late final RoomCreator _roomCreator;
  late final RoomJoiner _roomJoiner;
  
  String? _currentRoomCode;
  bool _isHost = false;
  bool _isLoading = false;
  String? _currentError;
  bool _isInLobby = true;
  bool _isGameStarted = false;
  bool _isGameOver = false;
  int _currentRound = 0;
  CardModel.Card? _currentCard;
  List<String> _currentOptions = [];
  GameResult? _gameResult;
  
  // Getters
  String? get roomCode => _currentRoomCode;
  bool get isHost => _isHost;
  bool get isLoading => _isLoading;
  String? get currentError => _currentError;
  bool get isInLobby => _isInLobby;
  bool get isGameStarted => _isGameStarted;
  bool get isGameOver => _isGameOver;
  int get currentRound => _currentRound;
  CardModel.Card? get currentCard => _currentCard;
  List<String> get currentOptions => _currentOptions;
  GameResult? get gameResult => _gameResult;

  GameManager() {
    _wsService = WebSocketService();
    _roomCreator = RoomCreator(_wsService, AuthService());
    _roomJoiner = RoomJoiner(_wsService, AuthService());
  }

  Future<void> initialize(String userId) async {
    _setLoading(true);
    try {
      await _wsService.connect();
      _setupWebSocketListeners();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to connect: $e');
    }
  }

  void _setupWebSocketListeners() {
    // Setup websocket subscription for game status
    _wsService.subscribe(
      '/topic/game.status',
      (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          // Handle game status updates
          notifyListeners();
        }
      },
    );
    
    // Setup websocket subscription for round updates
    _wsService.subscribe(
      '/topic/game.round',
      (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _currentRound = data['round'] ?? 0;
          _currentCard = CardModel.Card.fromJson(data['card']);
          _currentOptions = List<String>.from(data['options'] ?? []);
          _isGameStarted = true;
          _isInLobby = false;
          notifyListeners();
        }
      },
    );
    
    // Setup websocket subscription for game over
    _wsService.subscribe(
      '/topic/game.over',
      (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _isGameOver = true;
          _isGameStarted = false;
          _gameResult = GameResult(winner: data['winner'] ?? 'Unknown');
          notifyListeners();
        }
      },
    );
  }

  Future<String> createGame() async {
    _setLoading(true);
    try {
      _currentRoomCode = await _roomCreator.createRoom();
      _isHost = true;
      _isInLobby = true;
      _setLoading(false);
      notifyListeners();
      return _currentRoomCode!;
    } catch (e) {
      _setError('Failed to create game: $e');
      return '';
    }
  }

  Future<void> joinGame(String roomCode) async {
    _setLoading(true);
    try {
      await _roomJoiner.joinRoom(roomCode);
      _currentRoomCode = roomCode;
      _isHost = false;
      _isInLobby = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to join game: $e');
    }
  }

  void startGame() {
    final authService = AuthService();
    if (_currentRoomCode == null || !_isHost) return;
    
    String? firebaseUid = authService.getCurrentUserUid();
    if (firebaseUid == null) {
      _setError('User ID not found');
      return;
    }
    
    _wsService.sendMessage('/app/game.start', {
      'type': 'GAME_STARTED',
      'roomCode': _currentRoomCode,
      'senderId': firebaseUid,
      'senderUsername': 'Player-${firebaseUid.substring(0, 4)}'
    });
  }

  void submitAnswer(int optionIndex) {
    if (_currentRoomCode == null) {
      _setError('Room code not found');
      return;
    }
    
    _wsService.sendWithHeader(
      '/app/game.submitAnswer',
      optionIndex.toString(),
      {'roomCode': _currentRoomCode!}
    );
  }

  void leaveRoom() {
    final authService = AuthService();
    String? firebaseUid = authService.getCurrentUserUid();
    
    if (firebaseUid == null) {
      _setError('User ID not found');
      return;
    }
    
    if (_currentRoomCode != null) {
      _wsService.sendMessage('/app/game.leave', {
        'type': 'LEAVE_ROOM',
        'roomCode': _currentRoomCode,
        'senderId': firebaseUid,
        'senderUsername': 'Player-${firebaseUid.substring(0, 4)}'
      });
    }
    
    _currentRoomCode = null;
    _isHost = false;
    _isInLobby = false;
    notifyListeners();
  }
  
  void resetGame() {
    _isGameOver = false;
    _isGameStarted = false;
    _isInLobby = false;
    _currentRoomCode = null;
    _isHost = false;
    _currentRound = 0;
    _gameResult = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _currentError = error;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}