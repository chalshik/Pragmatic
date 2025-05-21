import 'dart:convert';
import 'package:http/http.dart' as http;
import 'AuthService.dart';
import 'package:pragmatic/Models/Card.dart';
import 'package:pragmatic/Models/Deck.dart';
import 'package:pragmatic/Models/Book.dart';
import 'package:pragmatic/Models/ReviewRequest.dart';
import 'package:pragmatic/Models/Review.dart';
import 'package:pragmatic/Models/WordEntry.dart';

class ApiService {
  // Update this to your development machine's IP address or your API endpoint
  // final String baseUrl = 'http://10.0.2.2';  // Use this for Android emulator
  final String baseUrl =
      'https://specific-backend-production.up.railway.app'; // Local development
  AuthService? _authService;

  ApiService();

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  // Helper methods for auth that handle the case where _authService is not initialized

  Future<bool> joinGame(String username, String gameCode) async {
    final url = Uri.parse('$baseUrl/join/$gameCode'); // corrected endpoint

    final body = jsonEncode({'id': username});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Optionally parse response JSON for success status
        final json = jsonDecode(response.body);
        if (json['status'] == 'SUCCESS') {
          return true;
        } else {
          print('Join game failed: ${json['message']}');
          return false;
        }
      } else {
        print('Failed with status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception during joinGame: $e');
      return false;
    }
  }

  Future<String?> createGame(String username) async {
    final url = Uri.parse('$baseUrl/game/create'); // your endpoint
    final body = jsonEncode({'id': "hello"});

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 201) {
      final Map<String, String> roomCode = jsonDecode(response.body);
      print(roomCode["roomCode"]);
      return roomCode["roomCode"];
    } else {
      print('Error creating game: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  // Make this method handle the case where the server is not reachable
  Future<Map<String, dynamic>> registerUser({
    required String firebaseUid,
    required String username,
  }) async {
    final token = await _authService?.getCurrentUserToken();
    final url = Uri.parse('$baseUrl/user/register');
    print(token);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebaseUid': firebaseUid, 'username': username}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw Exception('Invalid request data');
      } else if (response.statusCode == 409) {
        throw Exception('User already exists');
      } else {
        throw Exception('Failed to register user: ${response.statusCode}');
      }
    } catch (e) {
      print('API Server connection error: $e');
      // Return an empty success response to avoid blocking auth flow when API server is unavailable
      return {
        'status': 'success',
        'message': 'Created user in Firebase only (API unavailable)',
      };
    }
  }

  Future<WordEntry> fetchDefinition(String word) async {
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/$word',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return WordEntry.fromJson(data.first);
    } else {
      throw Exception('Word not found or API error: ${response.statusCode}');
    }
  }

  Future<Deck> createDeck({required String title}) async {
    final url = Uri.parse('$baseUrl/anki/add-deck');
    final token = await _authService?.getCurrentUserToken();
    final firebaseUid = _authService?.getCurrentUserUid();

    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'firebaseUid': firebaseUid}),
      );
      print('createDeck response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Deck.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid deck data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception(
          'Failed to create deck: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to create deck: $e');
    }
  }

  Future<void> deleteDeck({required int deckId}) async {
    
    final token = await _authService?.getCurrentUserToken();
    final firebaseUid = _authService?.getCurrentUserUid();
    final url = Uri.parse(
          'https://specific-backend-production.up.railway.app/anki/delete-deck/$deckId',
    );
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    print('request body: ${jsonEncode({'firebaseUid': firebaseUid})}');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Firebase-Uid': firebaseUid,
        },
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Deck not found');
      } else {
        throw Exception('Failed to delete deck: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete deck: $e');
    }
  }

  Future<List<Deck>> getUserDecks() async {
    final firebaseUid = _authService?.getCurrentUserUid();
    if (firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    final url = Uri.parse('$baseUrl/anki/user-decks?firebaseUid=$firebaseUid');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Firebase-Uid': firebaseUid,
        },
      );
      print('getUserDecks raw response: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> decksJson = jsonDecode(response.body);
        return decksJson.map((json) => Deck.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to fetch user decks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user decks: $e');
    }
  }

  Future<http.Response> createCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final firebaseUid = _authService?.getCurrentUserUid();
    if (firebaseUid == null) {
      print('❌ No authenticated user found');
      throw Exception('No authenticated user found');
    }

    // 🔐 Log Firebase UID
    print('👤 Firebase UID: $firebaseUid');

    // Check if back content exceeds 250 symbols and truncate if necessary
    String processedBack = back;
    if (back.length > 250) {
      // Cut off at 247 characters and add "..." to indicate truncation
      processedBack = back.substring(0, 247) + "...";
      print(
        '⚠️ Back content exceeded 250 characters. Truncated to: $processedBack',
      );
    }

    final url = Uri.parse(
      'https://specific-backend-production.up.railway.app/api/cards/deck/$deckId?firebaseUid=$firebaseUid',
    );

    final headers = {
      'Content-Type': 'application/json',
      'X-Firebase-Uid': firebaseUid,
    };

    final body = jsonEncode({'front': front, 'back': processedBack});

    // 🧪 Equivalent curl log
    print('📎 Equivalent curl command:');
    print('curl -X POST "$url" \\');
    print('  -H "Content-Type: application/json" \\');
    print('  -H "X-Firebase-Uid: $firebaseUid" \\');
    print("  -d '$body'");

    final response = await http.post(url, headers: headers, body: body);

    print('✅ Response received');
    print('🔢 Status code: ${response.statusCode}');
    print('📄 Response body: ${response.body}');

    return response;
  }

  Future<void> deleteCard({required String cardId}) async {
    final url = Uri.parse('$baseUrl/anki/delete-card/$cardId');
    final token = await _authService?.getCurrentUserToken();
    final firebaseUid = _authService?.getCurrentUserUid();
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebaseUid': firebaseUid}),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Card not found');
      } else {
        throw Exception('Failed to delete card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  Future<Book> createBook({required String title}) async {
    final url = Uri.parse('$baseUrl/api/books');
    final token = await _authService?.getCurrentUserToken();
    final firebaseUid = _authService?.getCurrentUserUid();

    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'title': title, 'firebaseUid': firebaseUid}),
      );

      if (response.statusCode == 201) {
        return Book.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid book data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to create book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create book: $e');
    }
  }

  Future<void> deleteBook({required int bookId}) async {
    final url = Uri.parse('$baseUrl/api/books/$bookId');
    final token = await _authService?.getCurrentUserToken();
    final firebaseUid = _authService?.getCurrentUserUid();
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebaseUid': firebaseUid}),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Book not found');
      } else {
        throw Exception('Failed to delete book: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  Future<List<Book>> getUserBooks() async {
    final url = Uri.parse('$baseUrl/api/books');
    final token = await _authService?.getCurrentUserToken();
    final firebaseUid = _authService?.getCurrentUserUid();

    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firebaseUid': firebaseUid}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> booksJson = jsonDecode(response.body);
        return booksJson.map((json) => Book.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to fetch user books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch user books: $e');
    }
  }

  Future<Review> processReview(ReviewRequest request) async {
    final url = Uri.parse('$baseUrl/api/reviews');
    final token = await _authService?.getCurrentUserToken();
    final firebaseUid = _authService?.getCurrentUserUid();

    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    try {
      var requestData = request.toJson();
      requestData['firebaseUid'] = firebaseUid;

      print('📤 Sending review for card ID ${request.cardId}');
      print('📦 Request body: ${jsonEncode(requestData)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // Uncomment if needed
        },
        body: jsonEncode(requestData),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('✅ Parsed review response: $decoded');
        return Review.fromJson(decoded);
      } else if (response.statusCode == 400) {
        throw Exception('Invalid review data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Card not found');
      } else {
        throw Exception('Failed to process review: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('❌ Failed to process review for card ID ${request.cardId}: $e');
      print('📌 Stack trace:\n$stack');
      rethrow;
    }
  }

  Future<List<Card>> getCardsForDeck(int deckId) async {
    final firebaseUid = _authService?.getCurrentUserUid();

    if (firebaseUid == null) {
      throw Exception('No authenticated user found');
    }

    final url = Uri.parse(
      '$baseUrl/api/cards/deck/$deckId?firebaseUid=$firebaseUid',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Firebase-Uid': firebaseUid,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> cardsJson = jsonDecode(response.body);
      return cardsJson.map((json) => Card.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch cards: ${response.statusCode}');
    }
  }
}
