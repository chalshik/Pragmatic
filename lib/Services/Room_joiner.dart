import 'dart:convert';

import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Services/WebSocketService.dart';

class RoomJoiner {
  final WebSocketService _wsService;
  String? _roomCode;
  final AuthService _authService;

  RoomJoiner(this._wsService,this._authService);

  Future<void> joinRoom(String roomCode) async {
    try {
      String? firebaseUid = _authService.getCurrentUserUid();
      _roomCode = roomCode;

      // 1. Subscribe to room topic
      _wsService.subscribe(
        '/topic/game.room.$_roomCode',
        (frame) => _handleRoomMessage(frame.body!),
      );

      // 2. Send join message
      _wsService.sendMessage('/app/game.join', {
        'type': 'ROOM_JOINED',
        'roomCode': _roomCode,
        'senderId': "$firebaseUid",
        'senderUsername': 'Player-${firebaseUid!.substring(0, 4)}'
      });
    } catch (e) {
      print('Error joining room: $e');
      rethrow;
    }
  }

  void _handleRoomMessage(String messageBody) {
    final message = jsonDecode(messageBody);
    print('Room message received: $message');
    // Handle room-specific messages here
  }
}