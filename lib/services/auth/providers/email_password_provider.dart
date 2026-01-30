import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'base_auth_provider.dart';

/// Email/Password Authentication Provider
///
/// Handles traditional email and password authentication with email verification.
///
/// Features:
/// - Sign up with email and password
/// - Sign in with email and password
/// - Email verification
/// - Password reset
class EmailPasswordAuthProvider implements BaseAuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Callbacks
  AuthSuccessCallback? onSuccess;
  AuthErrorCallback? onError;

  @override
  String get providerName => 'Email/Password';

  @override
  bool get isAvailable => true; // Always available

  @override
  Future<void> initialize() async {
    debugPrint('🔧 [$providerName]: Initializing...');
    debugPrint('✅ [$providerName]: Initialized');
  }

  /// Sign up a new user with email and password
  ///
  /// Automatically sends verification email after successful registration
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    debugPrint('📝 [$providerName]: Creating account for $email');

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ [$providerName]: Account created successfully');
      debugPrint('   User: ${credential.user?.email}');
      debugPrint('   UID: ${credential.user?.uid}');

      // Send verification email
      await sendEmailVerification();

      return credential;

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [$providerName]: FirebaseAuthException');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');

      // Provide user-friendly error messages
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to create account';
      }

      throw Exception(errorMessage);
    }
  }

  /// Sign in an existing user with email and password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 [$providerName]: Signing in $email');

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ [$providerName]: Sign-in successful!');
      debugPrint('   User: ${credential.user?.email}');
      debugPrint('   UID: ${credential.user?.uid}');
      debugPrint('   Email verified: ${credential.user?.emailVerified}');

      return credential;

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [$providerName]: FirebaseAuthException');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');

      // Provide user-friendly error messages
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to sign in';
      }

      throw Exception(errorMessage);
    }
  }

  /// Send email verification to the current user
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    if (user.emailVerified) {
      debugPrint('ℹ️ [$providerName]: Email already verified');
      return;
    }

    try {
      debugPrint('📧 [$providerName]: Sending verification email to ${user.email}');
      await user.sendEmailVerification();
      debugPrint('✅ [$providerName]: Verification email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [$providerName]: Failed to send verification email');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      throw Exception('Failed to send verification email: ${e.message}');
    }
  }

  /// Check if the current user's email is verified
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Reload the current user to get updated verification status
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('🔑 [$providerName]: Sending password reset email to $email');

    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ [$providerName]: Password reset email sent');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [$providerName]: Failed to send password reset email');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to send password reset email';
      }

      throw Exception(errorMessage);
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 [$providerName]: Disposing...');
    // No cleanup needed for email/password
  }
}
