import 'package:talent/core/models/user.dart';

/// Interface for authentication services
abstract class AuthService {
  /// Returns the current user, or null if not logged in.
  User? get currentUser;

  /// Returns the authentication token, or null if not logged in.
  String? get authToken;

  /// Stream of authentication state changes.
  Stream<bool> get authStateChanges;

  /// Returns whether the user is currently authenticated.
  bool get isAuthenticated;

  /// Returns whether the service is still initializing.
  bool get isInitializing;

  /// Logs in a user with email and password.
  /// Returns a tuple of (User?, String) where:
  /// - User? is the logged in user or null if login failed
  /// - String is a message indicating success or the error reason
  Future<(User?, String)> login({
    required String email,
    required String password,
    String? type,
  });

  /// Signs up a new user.
  Future<User> signup({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required UserType userType,
  });

  /// Logs out the current user.
  Future<void> logout();

  /// Disposes any resources used by the service.
  void dispose();
}
