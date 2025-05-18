import 'dart:convert';
import 'package:http/http.dart' as http;
import 'AuthService.dart';
import 'package:pragmatic/Models/TranslationRequest.dart';
import 'package:pragmatic/Models/TranslationResponse.dart';
import 'package:pragmatic/Models/Card.dart';
import 'package:pragmatic/Models/Deck.dart';
import 'package:pragmatic/Models/Book.dart';
import 'package:pragmatic/Models/ReviewRequest.dart';
import 'package:pragmatic/Models/Review.dart';

class ApiService {
  // Update this to your development machine's IP address or your API endpoint
  // final String baseUrl = 'http://10.0.2.2';  // Use this for Android emulator
  final String baseUrl = 'https://specific-backend-production.up.railway.app';  // Local development
  final AuthService _authService;
  ApiService(this._authService);

  // Make this method handle the case where the server is not reachable
  Future<Map<String, dynamic>> registerUser({
    required String firebaseUid,
    required String username,
  }) async {
    final token = await _authService.getCurrentUserToken();
    final url = Uri.parse('$baseUrl/user/register');
    print(token);
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firebaseUid': firebaseUid,
          'username': username,
        }),
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
      return {'status': 'success', 'message': 'Created user in Firebase only (API unavailable)'};
    }
  }

  Future<Deck> createDeck({
    required String title,
  }) async {
    final url = Uri.parse('$baseUrl/anki/add-deck');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'firebaseUid': firebaseUid,
        }),
      );
      print('createDeck response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 201) {
        return Deck.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid deck data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to create deck: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create deck: $e');
    }
  }

  Future<void> deleteDeck({
    required String deckId,
  }) async {
    final url = Uri.parse('$baseUrl/anki/delete-deck/$deckId');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firebaseUid': firebaseUid,
        }),
      );

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
    final firebaseUid = _authService.getCurrentUserUid();
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

  Future<Card> createCard({
    required String front,
    required String back,
    required int deckId,
    String? context,
    int? bookId,
  }) async {
    final url = Uri.parse('$baseUrl/anki/add-card');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'front': front,
          'back': back,
          'deckId': deckId,
          'firebaseUid': firebaseUid,
          if (context != null) 'context': context,
          if (bookId != null) 'bookId': bookId,
        }),
      );

      if (response.statusCode == 201) {
        return Card.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid card data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Deck not found');
      } else {
        throw Exception('Failed to create card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create card: $e');
    }
  }

  Future<void> deleteCard({
    required String cardId,
  }) async {
    final url = Uri.parse('$baseUrl/anki/delete-card/$cardId');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firebaseUid': firebaseUid,
        }),
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

  Future<Book> createBook({
    required String title,
  }) async {
    final url = Uri.parse('$baseUrl/api/books');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'firebaseUid': firebaseUid,
        }),
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

  Future<void> deleteBook({
    required int bookId,
  }) async {
    final url = Uri.parse('$baseUrl/api/books/$bookId');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firebaseUid': firebaseUid,
        }),
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
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firebaseUid': firebaseUid,
        }),
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
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      var requestData = request.toJson();
      requestData['firebaseUid'] = firebaseUid;
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 201) {
        return Review.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid review data');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Card not found');
      } else {
        throw Exception('Failed to process review: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to process review: $e');
    }
  }

  Future<TranslationResponse> getTranslation(TranslationRequest request) async {
    final url = Uri.parse('$baseUrl/translation');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      var requestData = request.toJson();
      requestData['firebaseUid'] = firebaseUid;
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        return TranslationResponse.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 400) {
        throw Exception('Invalid translation request');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to get translation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get translation: $e');
    }
  }
  
  Future<List<Card>> getDueCardsForDeck(int deckId) async {
    final url = Uri.parse('$baseUrl/anki/due-cards/$deckId');
    final token = await _authService.getCurrentUserToken();
    final firebaseUid = _authService.getCurrentUserUid();
    
    if (token == null || firebaseUid == null) {
      throw Exception('No authenticated user found');
    }
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'deckId': deckId,
          'firebaseUid': firebaseUid,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> cardsJson = jsonDecode(response.body);
        return cardsJson.map((json) => Card.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw Exception('Deck not found');
      } else {
        throw Exception('Failed to fetch due cards: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch due cards: $e');
    }
  }
}