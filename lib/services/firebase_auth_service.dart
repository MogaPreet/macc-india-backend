import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/constants/firebase_constants.dart';
import '../firebase_options.dart';

/// Service for Firebase Authentication
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!isAuthorizedAdmin(email)) {
        await signOut();
        throw Exception(
          'Unauthorized: Only admin users can access this portal',
        );
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        case 'too-many-requests':
          throw Exception('Too many login attempts. Please try again later');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Check if email is in authorized admin list
  bool isAuthorizedAdmin(String email) {
    return FirebaseConstants.authorizedAdminEmails.contains(
      email.toLowerCase(),
    );
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found with this email');
        case 'invalid-email':
          throw Exception('Invalid email address');
        default:
          throw Exception('Failed to send reset email: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  /// Create employee Auth user via Identity Toolkit REST API.
  /// Avoids secondary Firebase Auth apps (broken on Flutter web) and does
  /// not replace the currently signed-in admin session.
  Future<String> createEmployeeAuthUser({
    required String email,
    required String password,
  }) async {
    final apiKey = DefaultFirebaseOptions.web.apiKey;
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final localId = body['localId'] as String?;
        if (localId == null || localId.isEmpty) {
          throw Exception('Account creation failed: no user id returned');
        }
        return localId;
      }

      final error = body['error'] as Map<String, dynamic>?;
      final message = (error?['message'] as String?) ?? 'UNKNOWN';
      switch (message) {
        case 'EMAIL_EXISTS':
          throw Exception('An account already exists with this email');
        case 'INVALID_EMAIL':
          throw Exception('Invalid email address');
        case 'WEAK_PASSWORD : Password should be at least 6 characters':
        case 'WEAK_PASSWORD':
          throw Exception('Password is too weak (min 6 characters)');
        case 'OPERATION_NOT_ALLOWED':
          throw Exception(
            'Email/password sign-in is disabled in Firebase Auth',
          );
        default:
          throw Exception('Account creation failed: $message');
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Account creation failed: $e');
    }
  }

  /// Create new admin user (for initial setup)
  Future<User?> createAdminUser({
    required String email,
    required String password,
  }) async {
    try {
      if (!isAuthorizedAdmin(email)) {
        throw Exception('Email not in authorized admin list');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('An account already exists with this email');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'weak-password':
          throw Exception('Password is too weak');
        default:
          throw Exception('Account creation failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Account creation failed: $e');
    }
  }
}
