import 'package:pragmatic/Services/AuthService.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
// import 'package:web_socket_channel/web_socket_channel.dart'; // Removing unused import
import 'dart:convert';

class WebSocketService {
  late StompClient _stompClient;
  bool _isConnected = false;
  final AuthService _authService = AuthService();
  String? firebaseUid;
  final Map<String, Function> _subscriptionCallbacks = {};

  WebSocketService() {
    firebaseUid = _authService.getCurrentUserUid();
  }
  
  Future<void> connect() async {
    _stompClient = StompClient(
      config: StompConfig(
        url: 'https://specific-backend.onrender.com/ws-game',
        onConnect: _onConnectCallback,
        onWebSocketError: (error) => print('WebSocket Error: $error'),
        stompConnectHeaders: {'X-Firebase-Uid': "$firebaseUid"},
        webSocketConnectHeaders: {'X-Firebase-Uid': "$firebaseUid"},
      ),
    );
    
    _stompClient.activate();
    _isConnected = true;
  }

  void _onConnectCallback(StompFrame frame) {
    print('WebSocket Connected!');
    // Set up subscriptions after connection
    _subscriptionCallbacks.forEach((destination, _) {
      _setupSubscription(destination);
    });
  }

  void onMessage(String destination, Function(Map<String, dynamic>) callback) {
    _subscriptionCallbacks[destination] = callback;
    if (_isConnected) {
      _setupSubscription(destination);
    }
  }

  void _setupSubscription(String destination) {
    _stompClient.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body != null && _subscriptionCallbacks.containsKey(destination)) {
          final Map<String, dynamic> message = jsonDecode(frame.body!);
          _subscriptionCallbacks[destination]!(message);
        }
      },
    );
  }

  void sendMessage(String destination, Map<String, dynamic> body) {
    if (!_isConnected) throw Exception('Not connected to WebSocket');
    _stompClient.send(
      destination: destination,
      body: jsonEncode(body),
    );
  }

  // Method to send messages with headers
  void sendWithHeader(String destination, String body, Map<String, String> headers) {
    if (!_isConnected) throw Exception('Not connected to WebSocket');
    _stompClient.send(
      destination: destination,
      body: body,
      headers: headers,
    );
  }

  void subscribe(String destination, Function(StompFrame) callback) {
    _stompClient.subscribe(
      destination: destination,
      callback: callback,
    );
  }

  void disconnect() {
    _stompClient.deactivate();
    _isConnected = false;
  }
}