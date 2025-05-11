import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pragmatic/Services/AuthService.dart';
import 'package:pragmatic/Services/WebSocketService.dart';

class RoomCreator {
  final WebSocketService _wsService;
  final AuthService _authService;
  String? _roomCode;

  RoomCreator(this._wsService,this._authService);

  Future<String> createRoom() async {
    try {
      String? firebaseUid = _authService.getCurrentUserUid();
      // 1. Call API to create room
      final response = await http.post(
        Uri.parse('https://specific-backend.onrender.com/ws-game/api/game/room?firebaseUid=${firebaseUid}'),
        headers: {'X-Firebase-Uid': "$firebaseUid"},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create room: ${response.statusCode}');
      }

      // 2. Parse response
      final data = jsonDecode(response.body);
      _roomCode = data['roomCode'];

      // 3. Subscribe to room topic
      _wsService.subscribe(
        '/topic/game.room.$_roomCode',
        (frame) => _handleRoomMessage(frame.body!),
      );

      // 4. Notify room creation
      _wsService.sendMessage('/app/game.notify', {
        'type': 'ROOM_CREATED',
        'roomCode': _roomCode,
        'senderId':"$firebaseUid",
        'senderUsername': 'Player-${firebaseUid!.substring(0, 4)}'
      });

      return _roomCode!;
    } catch (e) {
      print('Error creating room: $e');
      rethrow;
    }
  }

  void _handleRoomMessage(String messageBody) {
    final message = jsonDecode(messageBody);
    print('Room message received: $message');
    // Handle room-specific messages here
  }
}