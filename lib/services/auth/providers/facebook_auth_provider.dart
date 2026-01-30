import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'base_auth_provider.dart';

// Import Firebase's FacebookAuthProvider for credential creation
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Facebook Authentication Provider
///
/// Handles authentication via Facebook Login.
///
/// Setup required:
/// 1. Create Facebook App at https://developers.facebook.com
/// 2. Add package: flutter pub add flutter_facebook_auth
/// 3. Enable Facebook Sign-In in Firebase Console
/// 4. Configure Android: Add Facebook App ID to AndroidManifest.xml
/// 5. Configure iOS: Add Facebook App ID to Info.plist
///
/// Features:
/// - Native Facebook login
/// - Automatic account picker
/// - Access to Facebook profile data
class FacebookAuthProvider implements BaseAuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Callbacks
  AuthSuccessCallback? onSuccess;
  AuthErrorCallback? onError;

  @override
  String get providerName => 'Facebook';

  @override
  bool get isAvailable => true; // Package is now installed!

  @override
  Future<void> initialize() async {
    if (!isAvailable) {
      debugPrint('⚠️ [$providerName]: Provider not available (package not installed)');
      return;
    }

    debugPrint('🔧 [$providerName]: Initializing...');
    debugPrint('✅ [$providerName]: Initialized');
  }

  /// Sign in with Facebook
  ///
  /// Opens Facebook login flow and signs in the user
  Future<UserCredential> signInWithFacebook() async {
    if (!isAvailable) {
      throw Exception('Facebook Sign-In is not configured. Please add flutter_facebook_auth package.');
    }

    debugPrint('🔐 [$providerName]: Starting sign-in flow...');

    try {
      // Trigger the Facebook Sign-In flow
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.cancelled) {
        // User canceled the sign-in
        debugPrint('⚠️ [$providerName]: User canceled sign-in');
        throw Exception('Sign-in canceled');
      }

      if (result.status != LoginStatus.success) {
        debugPrint('❌ [$providerName]: Login failed: ${result.message}');
        throw Exception('Facebook login failed: ${result.message}');
      }

      // Get the access token
      final AccessToken? accessToken = result.accessToken;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      debugPrint('✅ [$providerName]: Access token obtained');

      // Create a credential from the access token using Firebase's FacebookAuthProvider
      final OAuthCredential credential = firebase_auth.FacebookAuthProvider.credential(
        accessToken.tokenString,
      );

      // Sign in to Firebase with the Facebook credential
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
          errorMessage = 'Invalid Facebook credentials.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Facebook Sign-In is not enabled in Firebase.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to sign in with Facebook';
      }

      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('❌ [$providerName]: Unknown error: $e');
      throw Exception('Failed to sign in with Facebook: $e');
    }
  }

  /// Sign out from Facebook
  Future<void> signOut() async {
    if (!isAvailable) return;

    try {
      await FacebookAuth.instance.logOut();
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
