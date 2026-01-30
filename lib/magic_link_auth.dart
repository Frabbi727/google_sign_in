import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MagicLinkAuth {
  static const _emailKey = 'magic_email';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendLink({
    required String email,
    required String linkDomain, // can keep this param for future
  }) async {
    final acs = ActionCodeSettings(
      url: 'https://mail-auth-1673b.web.app/finishSignIn',
      handleCodeInApp: true,
      androidPackageName: 'com.example.demo_projects',
      androidInstallApp: true,
      androidMinimumVersion: '21',
      iOSBundleId: 'com.example.demoProjects',
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);

    try {
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: acs,
      );
      print('✅ Magic link sent successfully to $email');
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
    } catch (e) {
      print('❌ Unknown error: $e');
    }
  }


  Future<UserCredential?> trySignInWithLink(String emailLink) async {
    print('🔍 Checking if link is valid: $emailLink');

    if (!_auth.isSignInWithEmailLink(emailLink)) {
      if (kDebugMode) {
        print('❌ Firebase says this is NOT a valid sign-in link');
      }
      return null;
    }

    print('✅ Firebase confirmed this is a valid sign-in link');

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);

    debugPrint('📧 Saved email from SharedPreferences: $email');

    if (email == null) {
      debugPrint('❌ No email found in SharedPreferences');

      throw Exception('No saved email found. Ask user to enter email again.');
    }

    debugPrint('🔐 Attempting to sign in with email: $email');
    final cred = await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
    debugPrint('✅ Sign in successful! User: ${cred.user?.email}');
    debugPrint('✅ NAME: ${cred.user?.displayName}');

    await prefs.remove(_emailKey);
    return cred;
  }
}
