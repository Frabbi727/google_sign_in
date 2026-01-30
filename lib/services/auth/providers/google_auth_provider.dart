import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'base_auth_provider.dart';

// Import Firebase's GoogleAuthProvider for credential creation
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;


class GoogleAuthProvider implements BaseAuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
  );

  // Callbacks
  @override
  AuthSuccessCallback? onSuccess;
  @override
  AuthErrorCallback? onError;

  @override
  String get providerName => 'Google';

  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {
    if (!isAvailable) {
      debugPrint('⚠️ [$providerName]: Provider not available (package not installed)');
      return;
    }

    debugPrint('🔧 [$providerName]: Initializing...');
    debugPrint('✅ [$providerName]: Initialized');
  }

  /// Sign in with Google
  ///
  /// Opens Google account picker and signs in the user
  Future<UserCredential> signInWithGoogle() async {
    if (!isAvailable) {
      throw Exception('Google Sign-In is not configured. Please add google_sign_in package.');
    }

    debugPrint('🔐 [$providerName]: Starting sign-in flow...');

    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('⚠️ [$providerName]: User canceled sign-in');
        throw Exception('Sign-in canceled');
      }

      debugPrint('📧 [$providerName]: User selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential using Firebase's GoogleAuthProvider
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      debugPrint('✅ [$providerName]: Sign-in successful!');
      debugPrint('   User: ${userCredential.user?.email}');
      debugPrint('   UID: ${userCredential.user?.uid}');
      debugPrint('   Display Name: ${userCredential.user?.displayName}');

      return userCredential;

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [$providerName]: FirebaseAuthException');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = 'An account already exists with this email using a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid Google credentials.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Google Sign-In is not enabled in Firebase.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to sign in with Google';
      }

      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('❌ [$providerName]: Unknown error: $e');
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    if (!isAvailable) return;

    try {
      await _googleSignIn.signOut();
      debugPrint('👋 [$providerName]: Signed out');
    } catch (e) {
      debugPrint('⚠️ [$providerName]: Error during sign-out: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 [$providerName]: Disposing...');
    // No cleanup needed
  }
}
