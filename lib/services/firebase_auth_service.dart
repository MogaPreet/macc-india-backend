import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firebase_constants.dart';

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

      // Check if user is authorized admin
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

  /// Create new admin user (for initial setup)
  Future<User?> createAdminUser({
    required String email,
    required String password,
  }) async {
    try {
      // Check if email is authorized
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
