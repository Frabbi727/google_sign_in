import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'providers/base_auth_provider.dart';
import 'providers/magic_link_provider.dart';
import 'providers/email_password_provider.dart';
import 'providers/google_auth_provider.dart' as google_provider;
import 'providers/facebook_auth_provider.dart' as facebook_provider;


class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication Providers (plug-and-play)
  late final MagicLinkAuthProvider magicLink;
  late final EmailPasswordAuthProvider emailPassword;
  late final google_provider.GoogleAuthProvider google;
  late final facebook_provider.FacebookAuthProvider facebook;

  // List of all providers for batch operations
  late final List<BaseAuthProvider> _allProviders;

  // Global callbacks (set by UI screens)
  AuthSuccessCallback? onSignInSuccess;
  AuthErrorCallback? onSignInError;

  bool _initialized = false;

  /// Initialize the service and all enabled providers
  Future<void> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ AuthService: Already initialized');
      return;
    }

    debugPrint('🚀 AuthService: Initializing...');

    // Initialize all providers
    magicLink = MagicLinkAuthProvider();
    emailPassword = EmailPasswordAuthProvider();
    google = google_provider.GoogleAuthProvider();
    facebook = facebook_provider.FacebookAuthProvider();

    _allProviders = [magicLink, emailPassword, google, facebook];

    // Set up callbacks for each provider
    for (var provider in _allProviders) {
      provider.onSuccess = (credential) {
        debugPrint('✅ AuthService: Sign-in successful via ${provider.providerName}');
        onSignInSuccess?.call(credential);
      };

      provider.onError = (error) {
        debugPrint('❌ AuthService: Sign-in failed via ${provider.providerName}: $error');
        onSignInError?.call(error);
      };
    }

    // Initialize only available providers
    final initFutures = _allProviders
        .where((p) => p.isAvailable)
        .map((p) => p.initialize());

    await Future.wait(initFutures);

    _initialized = true;

    // Log available providers
    final availableProviders = _allProviders
        .where((p) => p.isAvailable)
        .map((p) => p.providerName)
        .join(', ');

    debugPrint('✅ AuthService: Initialized');
    debugPrint('📦 Available providers: $availableProviders');
  }

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Check if a user is currently signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign out the current user from all providers
  Future<void> signOut() async {
    debugPrint('👋 AuthService: Signing out...');

    try {
      // Sign out from all providers
      await Future.wait([
        _auth.signOut(),
        google.signOut(),
        facebook.signOut(),
      ]);

      debugPrint('✅ AuthService: Signed out successfully');
    } catch (e) {
      debugPrint('❌ AuthService: Error during sign-out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }



  /// Reload the current user to get updated information
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Clean up resources
  void dispose() {
    debugPrint('🧹 AuthService: Disposing...');
    for (var provider in _allProviders) {
      provider.dispose();
    }
  }



  /// Quick access: Send magic link
  Future<void> sendMagicLink(String email) async {
    if (!magicLink.isAvailable) {
      throw Exception('Magic Link provider is not available');
    }
    await magicLink.sendMagicLink(email);
  }






}
