import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton service that manages all authentication operations
/// including magic link sending, deep link handling, and user sessions
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Dependencies
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppLinks _appLinks = AppLinks();

  // State
  StreamSubscription<Uri>? _linkSubscription;
  static const _emailKey = 'magic_email';

  // Callback for when user successfully signs in
  Function(UserCredential)? onSignInSuccess;
  Function(String)? onSignInError;

  /// Initialize the service - sets up deep link listener
  /// Call this once when the app starts
  Future<void> initialize() async {
    debugPrint('🔧 AuthService: Initializing...');

    // Check if app was opened with a magic link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('🔗 AuthService: Found initial link');
      await _processDeepLink(initialLink);
    }

    // Listen for future deep links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        debugPrint('🔗 AuthService: Received deep link');
        await _processDeepLink(uri);
      },
      onError: (error) {
        debugPrint('❌ AuthService: Deep link error: $error');
      },
    );

    debugPrint('✅ AuthService: Initialized');
  }

  /// Send a magic link to the provided email
  Future<void> sendMagicLink(String email) async {
    debugPrint('📧 AuthService: Sending magic link to $email');

    // Configure the magic link settings
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://mail-auth-1673b.web.app/finishSignIn',
      handleCodeInApp: true,
      androidPackageName: 'com.example.demo_projects',
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.example.demoProjects',
    );

    // Save email to SharedPreferences (needed later for sign-in)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    debugPrint('💾 AuthService: Email saved to SharedPreferences');

    try {
      // Send the email via Firebase
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      debugPrint('✅ AuthService: Magic link sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthService: FirebaseAuthException');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ AuthService: Unknown error: $e');
      rethrow;
    }
  }

  /// Process an incoming deep link (private method)
  Future<void> _processDeepLink(Uri uri) async {
    try {
      debugPrint('🔍 AuthService: Processing link: ${uri.toString()}');

      // Validate the link with Firebase
      if (!_auth.isSignInWithEmailLink(uri.toString())) {
        debugPrint('⚠️ AuthService: Not a valid sign-in link');
        return;
      }

      debugPrint('✅ AuthService: Link is valid');

      // Retrieve the saved email
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey);

      if (email == null) {
        debugPrint('❌ AuthService: No saved email found');
        onSignInError?.call('No saved email found. Please try again.');
        return;
      }

      debugPrint('📧 AuthService: Found saved email: $email');

      // Sign in with Firebase
      debugPrint('🔐 AuthService: Attempting sign-in...');
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: uri.toString(),
      );

      debugPrint('✅ AuthService: Sign-in successful!');
      debugPrint('   User: ${credential.user?.email}');
      debugPrint('   UID: ${credential.user?.uid}');

      // Clean up - remove saved email
      await prefs.remove(_emailKey);
      debugPrint('🧹 AuthService: Cleaned up saved email');

      // Notify success
      onSignInSuccess?.call(credential);

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ AuthService: FirebaseAuthException');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      onSignInError?.call(e.message ?? 'Authentication failed');
    } catch (e) {
      debugPrint('❌ AuthService: Error processing deep link: $e');
      onSignInError?.call('Failed to sign in: $e');
    }
  }

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign out the current user
  Future<void> signOut() async {
    debugPrint('👋 AuthService: Signing out');
    await _auth.signOut();
    debugPrint('✅ AuthService: Signed out');
  }

  /// Clean up resources
  void dispose() {
    debugPrint('🧹 AuthService: Disposing...');
    _linkSubscription?.cancel();
  }
}