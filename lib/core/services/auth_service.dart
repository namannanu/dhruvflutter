import '../models/user.dart';

abstract class AuthService {
  /// Returns the current user, or null if not logged in.
  User? get currentUser;

  /// Returns the authentication token, or null if not logged in.
  String? get authToken;

  /// Stream of authentication state changes.
  Stream<bool> get authStateChanges;

  /// Returns whether the user is currently authenticated.
  bool get isAuthenticated;

  /// Logs in a user with email and password.
  Future<User> login({required String email, required String password});

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
