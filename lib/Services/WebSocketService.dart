import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:pragmatic/Services/AuthService.dart';

class WebSocketService {
  late StompClient _stompClient;
  bool _isConnected = false;
  final AuthService _authService = AuthService();

  String? firebaseUid;

  final Map<String, Function(Map<String, dynamic>)> _subscriptionCallbacks = {};

  WebSocketService() {
    firebaseUid = _authService.getCurrentUserUid();
  }

  Future<void> connect() async {
    if (firebaseUid == null) {
      print("Firebase UID is null. Cannot connect.");
      return;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: 'wss://specific-backend-production.up.railway.app/ws',
        onConnect: _onConnectCallback,
        onStompError: (frame) => print("❌ STOMP Error: ${frame.body}"),
        onWebSocketError: (error) => print("❌ WebSocket Error: $error"),
        onDisconnect: (frame) => print("⚠️ Disconnected from WebSocket"),
        stompConnectHeaders: {'X-Firebase-Uid': firebaseUid!},
        webSocketConnectHeaders: {'X-Firebase-Uid': firebaseUid!},
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        reconnectDelay: const Duration(seconds: 5),
        onDebugMessage: (msg) => print('🐛 DEBUG: $msg'),
      ),
    );

    _stompClient.activate();
  }

  void _onConnectCallback(StompFrame frame) {
    print('✅ WebSocket Connected!');
    _isConnected = true;

    _subscriptionCallbacks.forEach((destination, callback) {
      _setupSubscription(destination, callback);
    });
  }

  void onMessage(String destination, Function(Map<String, dynamic>) callback) {
    _subscriptionCallbacks[destination] = callback;
    if (_isConnected) {
      _setupSubscription(destination, callback);
    }
  }

  void _setupSubscription(
    String destination,
    Function(Map<String, dynamic>) callback,
  ) {
    _stompClient.subscribe(
      destination: destination,
      callback: (frame) {
        if (frame.body != null) {
          final Map<String, dynamic> message = jsonDecode(frame.body!);
          callback(message);
        }
      },
    );
  }

  void sendMessage(String destination, Map<String, dynamic> body) {
    if (!_isConnected) {
      throw Exception("Not connected to WebSocket");
    }

    _stompClient.send(destination: destination, body: jsonEncode(body));
  }

  void sendWithHeader(
    String destination,
    String body,
    Map<String, String> headers,
  ) {
    if (!_isConnected) {
      throw Exception("Not connected to WebSocket");
    }

    _stompClient.send(destination: destination, body: body, headers: headers);
  }

  void subscribeToPlayerUpdates(
  String? gameCode,
  Function(List<Map<String, dynamic>>) onPlayerUpdate,
) {
  final destination = "/topic/game/$gameCode/players";

  if (_isConnected) {
    _stompClient.subscribe(
      destination: destination,
      callback: (frame) {
        try {
          if (frame.body == null) {
            print('Received empty frame body');
            return;
          }
          
          print('Raw message received: ${frame.body}');
          final dynamic data = jsonDecode(frame.body!);
          print('Parsed data: $data');
          
          if (data is List) {
            onPlayerUpdate(List<Map<String, dynamic>>.from(data));
          } else if (data is Map<String, dynamic>) {
            if (data.containsKey('players') && data['players'] is List) {
              onPlayerUpdate(List<Map<String, dynamic>>.from(data['players']));
            } else {
              print('Unexpected data structure: $data');
            }
          } else {
            print('Received data of unexpected type: ${data.runtimeType}');
          }
        } catch (e, stack) {
          print('Error processing player update: $e');
          print(stack);
        }
      },
    );
  }
}
  void disconnect() {
    _stompClient.deactivate();
    _isConnected = false;
    print("🔌 WebSocket disconnected manually.");
  }

  bool get isConnected => _isConnected;
}
