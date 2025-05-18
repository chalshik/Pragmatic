import 'package:firebase_auth/firebase_auth.dart';
import 'package:pragmatic/Services/ApiService.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  ApiService? apiService;

  AuthService();

  // Add a method to safely set the ApiService
  void setApiService(ApiService service) {
    apiService = service;
  }

  // Add auth state changes stream
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Sign up with email, password, and optional username
  Future<User?> signUp(String email, String password, {String? username}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      // Save username to Firestore if provided
      if (user != null && username != null && username.isNotEmpty && apiService != null) {
        try {
          await apiService!.registerUser(
            firebaseUid: user.uid,
            username: username,
          );
        } catch (e) {
          // Log the error but don't fail the sign-up process
          // The user is already created in Firebase Authentication
          print('Error registering with API server: $e');
        }
      }

      return user;
    } catch (e) {
      print('Error during sign up: $e'); // Keep for debugging
      rethrow; // Rethrow the error to be handled by UI
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(getCurrentUserToken());
      return userCredential.user;
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current user token
  Future<String?> getCurrentUserToken() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting user token: $e');
      rethrow;
    }
  }

  // Get current user UID
  String? getCurrentUserUid() {
    User? user = _auth.currentUser;
    return user?.uid;
  }
}