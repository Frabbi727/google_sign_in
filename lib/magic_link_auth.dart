import 'package:firebase_auth/firebase_auth.dart';
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
    if (!_auth.isSignInWithEmailLink(emailLink)) return null;

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);

    if (email == null) {
      throw Exception('No saved email found. Ask user to enter email again.');
    }

    final cred = await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
    await prefs.remove(_emailKey);
    return cred;
  }
}
