import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:pragmatic/Services/AuthService.dart';
import '../Models/Question.dart';

class WebSocketService {
  static WebSocketService? _instance;
  late StompClient _stompClient;
  bool _isConnected = false;
  final AuthService _authService = AuthService();

  String? firebaseUid;

  final Map<String, Function(Map<String, dynamic>)> _subscriptionCallbacks = {};
  final Map<String, StompUnsubscribe> _activeSubscriptions = {}; // Track active subscriptions

  // Singleton pattern
  WebSocketService._internal() {
    firebaseUid = _authService.getCurrentUserUid();
  }

  factory WebSocketService() {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  Future<void> connect() async {
    if (_isConnected) {
      print("WebSocket already connected");
      return;
    }

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
    print('✅ [DEBUG] Connection frame: ${frame.headers}');
    print('✅ [DEBUG] Setting _isConnected to true');
    _isConnected = true;

    print('✅ [DEBUG] Pending subscription callbacks: ${_subscriptionCallbacks.keys.toList()}');
    _subscriptionCallbacks.forEach((destination, callback) {
      print('✅ [DEBUG] Setting up pending subscription for: $destination');
      _setupSubscription(destination, callback);
    });
    print('✅ [DEBUG] All pending subscriptions processed');
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
    final subscription = _stompClient.subscribe(
      destination: destination,
      callback: (frame) {
        if (frame.body != null) {
          final Map<String, dynamic> message = jsonDecode(frame.body!);
          callback(message);
        }
      },
    );
    _activeSubscriptions[destination] = subscription;
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

  void subscribeToQuestionUpdates(String gameCode, Function(Question) onQuestionReceived) {
    final destination = "/topic/game/$gameCode/questions";
    
    print("🔔 [DEBUG] Attempting to subscribe to questions:");
    print("🔔 [DEBUG] - Destination: $destination");
    print("🔔 [DEBUG] - WebSocket connected: $_isConnected");
    print("🔔 [DEBUG] - Current active subscriptions: ${_activeSubscriptions.keys.toList()}");
    
    // Unsubscribe from any existing question subscription first
    unsubscribeFromQuestions(gameCode);

    if (_isConnected) {
      print("🔔 Setting up question subscription for: $destination");
      try {
        final subscription = _stompClient.subscribe(
          destination: destination,
          callback: (frame) {
            print("📨 Raw frame received on $destination");
            print("📨 Frame headers: ${frame.headers}");
            print("📨 Frame body: ${frame.body}");
            
            if (frame.body != null) {
              try {
                final data = jsonDecode(frame.body!);
                print("✅ Question JSON parsed successfully: $data");
                final question = Question.fromJson(data);
                print("✅ Question object created: ${question.question}");
                onQuestionReceived(question);
                print("✅ Question callback executed successfully");
              } catch (e, stackTrace) {
                print("❌ Error parsing question: $e");
                print("❌ Stack trace: $stackTrace");
                print("❌ Raw body that failed: ${frame.body}");
              }
            } else {
              print("⚠️ Received frame with empty body on $destination");
            }
          },
        );
        _activeSubscriptions[destination] = subscription;
        print("✅ Successfully subscribed to questions: $destination");
        print("✅ [DEBUG] Active subscriptions after adding: ${_activeSubscriptions.keys.toList()}");
      } catch (e, stackTrace) {
        print("❌ Failed to subscribe to questions: $e");
        print("❌ Stack trace: $stackTrace");
      }
    } else {
      print("❌ Cannot subscribe to questions - WebSocket not connected");
      print("❌ [DEBUG] Connection state: $_isConnected");
      print("❌ [DEBUG] StompClient state: ${_stompClient.connected}");
    }
  }

  void unsubscribeFromQuestions(String gameCode) {
    final destination = "/topic/game/$gameCode/questions";
    if (_activeSubscriptions.containsKey(destination)) {
      _activeSubscriptions[destination]?.call();
      _activeSubscriptions.remove(destination);
      _subscriptionCallbacks.remove(destination);
      print("🔄 Unsubscribed from questions: $destination");
    }
  }

  void subscribeToPlayerUpdates(
    String? gameCode,
    Function(List<Map<String, dynamic>>) onPlayerUpdate,
  ) {
    final destination = "/topic/game/$gameCode/players";

    if (_isConnected) {
      final subscription = _stompClient.subscribe(
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
      _activeSubscriptions[destination] = subscription;
      print("✅ Subscribed to players: $destination");
    }
  }

  void unsubscribeFromPlayerUpdates(String gameCode) {
    final destination = "/topic/game/$gameCode/players";
    if (_activeSubscriptions.containsKey(destination)) {
      _activeSubscriptions[destination]?.call();
      _activeSubscriptions.remove(destination);
      print("🔄 Unsubscribed from players: $destination");
    }
  }

  void subscribeToGameStatus(String gameCode, Function(Map<String, dynamic>) onStatusUpdate) {
    final destination = "/topic/game/$gameCode/status";
    
    // Unsubscribe from any existing status subscription first
    unsubscribeFromGameStatus(gameCode);

    if (_isConnected) {
      final subscription = _stompClient.subscribe(
        destination: destination,
        callback: (frame) {
          if (frame.body != null) {
            try {
              final data = jsonDecode(frame.body!);
              print("Game status received on $destination: $data");
              onStatusUpdate(data);
            } catch (e) {
              print("Error parsing game status message: $e");
            }
          }
        },
      );
      _activeSubscriptions[destination] = subscription;
      print("✅ Subscribed to game status: $destination");
    }
  }

  void unsubscribeFromGameStatus(String gameCode) {
    final destination = "/topic/game/$gameCode/status";
    if (_activeSubscriptions.containsKey(destination)) {
      _activeSubscriptions[destination]?.call();
      _activeSubscriptions.remove(destination);
      _subscriptionCallbacks.remove(destination);
      print("🔄 Unsubscribed from game status: $destination");
    }
  }

  void subscribeToGameEnd(String gameCode, Function(Map<String, dynamic>) onGameEnd) {
    final destination = "/topic/game/$gameCode/end";
    
    print("🏁 [DEBUG] Attempting to subscribe to game end:");
    print("🏁 [DEBUG] - Destination: $destination");
    print("🏁 [DEBUG] - WebSocket connected: $_isConnected");
    
    // DON'T unsubscribe existing game end subscription to prevent gaps
    // Multiple subscriptions to the same topic are allowed for reliability
    // unsubscribeFromGameEnd(gameCode);

    if (_isConnected) {
      print("🏁 Setting up game end subscription for: $destination");
      try {
        final subscription = _stompClient.subscribe(
          destination: destination,
          callback: (frame) {
            print("🏆 Raw frame received on $destination");
            print("🏆 Frame headers: ${frame.headers}");
            print("🏆 Frame body: ${frame.body}");
            
            if (frame.body != null) {
              try {
                final data = jsonDecode(frame.body!);
                print("✅ Game end data parsed successfully: $data");
                onGameEnd(data);
                print("✅ Game end callback executed successfully");
              } catch (e, stackTrace) {
                print("❌ Error parsing game end data: $e");
                print("❌ Stack trace: $stackTrace");
                print("❌ Raw body that failed: ${frame.body}");
              }
            } else {
              print("⚠️ Received frame with empty body on $destination");
            }
          },
        );
        
        // Store subscription with a unique key to allow multiple subscriptions
        final subscriptionKey = "${destination}_${DateTime.now().millisecondsSinceEpoch}";
        _activeSubscriptions[subscriptionKey] = subscription;
        print("✅ Successfully subscribed to game end: $destination with key: $subscriptionKey");
        print("✅ [DEBUG] Active subscriptions after adding: ${_activeSubscriptions.keys.toList()}");
      } catch (e, stackTrace) {
        print("❌ Failed to subscribe to game end: $e");
        print("❌ Stack trace: $stackTrace");
      }
    } else {
      print("❌ Cannot subscribe to game end - WebSocket not connected");
      print("❌ [DEBUG] Connection state: $_isConnected");
      print("❌ [DEBUG] StompClient state: ${_stompClient.connected}");
    }
  }

  void unsubscribeFromGameEnd(String gameCode) {
    final destination = "/topic/game/$gameCode/end";
    print("🔄 Attempting to unsubscribe from game end: $destination");
    
    // Find all subscriptions for this game end destination
    final keysToRemove = _activeSubscriptions.keys
        .where((key) => key.startsWith(destination))
        .toList();
    
    for (final key in keysToRemove) {
      final subscription = _activeSubscriptions[key];
      if (subscription != null) {
        try {
          subscription(); // Call the function to unsubscribe
          _activeSubscriptions.remove(key);
          print("✅ Successfully unsubscribed from game end: $key");
        } catch (e) {
          print("❌ Error unsubscribing from game end $key: $e");
        }
      }
    }
    
    if (keysToRemove.isEmpty) {
      print("⚠️ No active game end subscriptions found for: $destination");
    }
    
    print("🔄 [DEBUG] Active subscriptions after removal: ${_activeSubscriptions.keys.toList()}");
  }

  void unsubscribeAll() {
    _activeSubscriptions.forEach((destination, subscription) {
      subscription.call();
      print("🔄 Unsubscribed from: $destination");
    });
    _activeSubscriptions.clear();
    _subscriptionCallbacks.clear();
  }

  void disconnect() {
    unsubscribeAll();
    _stompClient.deactivate();
    _isConnected = false;
    print("🔌 WebSocket disconnected manually.");
  }

  bool get isConnected => _isConnected;
}
