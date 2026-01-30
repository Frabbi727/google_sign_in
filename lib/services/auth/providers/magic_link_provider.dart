import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_auth_provider.dart';

/// Magic Link Authentication Provider
///
/// Handles passwordless authentication via email links.
/// Users receive an email with a magic link, clicking it signs them in.
///
/// Features:
/// - Passwordless authentication
/// - Deep link handling
/// - Email persistence via SharedPreferences
class MagicLinkAuthProvider implements BaseAuthProvider {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  static const _emailKey = 'magic_email';

  // Callbacks
  @override
  AuthSuccessCallback? onSuccess;
  @override
  AuthErrorCallback? onError;

  @override
  String get providerName => 'Magic Link';

  @override
  bool get isAvailable => true; // Always available

  @override
  Future<void> initialize() async {
    debugPrint('🔧 [$providerName]: Initializing...');

    // Check if app was opened with a magic link
    final initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      debugPrint('🔗 [$providerName]: Found initial link');
      await _handleDeepLink(initialLink);
    }

    // Listen for future deep links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        debugPrint('🔗 [$providerName]: Received deep link');
        await _handleDeepLink(uri);
      },
      onError: (error) {
        debugPrint('❌ [$providerName]: Deep link error: $error');
      },
    );

    debugPrint('✅ [$providerName]: Initialized');
  }

  /// Send a magic link to the provided email
  Future<void> sendMagicLink(String email) async {
    debugPrint('📧 [$providerName]: Sending magic link to $email');

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
    debugPrint('💾 [$providerName]: Email saved to SharedPreferences');

    try {
      // Send the email via Firebase
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      debugPrint('✅ [$providerName]: Magic link sent successfully');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [$providerName]: FirebaseAuthException');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [$providerName]: Unknown error: $e');
      rethrow;
    }
  }

  /// Process an incoming deep link (private method)
  Future<void> _handleDeepLink(Uri uri) async {
    try {
      debugPrint('🔍 [$providerName]: Processing link: ${uri.toString()}');

      // Validate the link with Firebase
      if (!_auth.isSignInWithEmailLink(uri.toString())) {
        debugPrint('⚠️ [$providerName]: Not a valid sign-in link');
        return;
      }

      debugPrint('✅ [$providerName]: Link is valid');

      // Retrieve the saved email
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_emailKey);

      if (email == null) {
        debugPrint('❌ [$providerName]: No saved email found');
        onError?.call('No saved email found. Please try again.');
        return;
      }

      debugPrint('📧 [$providerName]: Found saved email: $email');

      // Sign in with Firebase
      debugPrint('🔐 [$providerName]: Attempting sign-in...');
      final credential = await _auth.signInWithEmailLink(
        email: email,
        emailLink: uri.toString(),
      );

      debugPrint('✅ [$providerName]: Sign-in successful!');
      debugPrint('   User: ${credential.user?.email}');
      debugPrint('   UID: ${credential.user?.uid}');

      // Clean up - remove saved email
      await prefs.remove(_emailKey);
      debugPrint('🧹 [$providerName]: Cleaned up saved email');

      // Notify success
      onSuccess?.call(credential);

    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [$providerName]: FirebaseAuthException');
      debugPrint('   Code: ${e.code}');
      debugPrint('   Message: ${e.message}');
      onError?.call(e.message ?? 'Authentication failed');
    } catch (e) {
      debugPrint('❌ [$providerName]: Error processing deep link: $e');
      onError?.call('Failed to sign in: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('🧹 [$providerName]: Disposing...');
    _linkSubscription?.cancel();
  }
}
