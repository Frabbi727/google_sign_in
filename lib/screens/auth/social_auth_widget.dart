import 'package:flutter/material.dart';

/// Reusable Social Authentication Buttons Widget
/// Easy to copy and use in any screen
class SocialAuthWidget extends StatelessWidget {
  final Future<void> Function()? onGoogleSignIn;
  final Future<void> Function()? onFacebookSignIn;
  final bool showGoogle;
  final bool showFacebook;

  const SocialAuthWidget({
    super.key,
    this.onGoogleSignIn,
    this.onFacebookSignIn,
    this.showGoogle = true,
    this.showFacebook = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Sign-In Button
        if (showGoogle && onGoogleSignIn != null)
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await onGoogleSignIn!();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Google sign-in failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

        if (showGoogle && showFacebook && onGoogleSignIn != null && onFacebookSignIn != null)
          const SizedBox(height: 12),

        // Facebook Sign-In Button
        if (showFacebook && onFacebookSignIn != null)
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await onFacebookSignIn!();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Facebook sign-in failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.facebook, color: Colors.blue),
            label: const Text('Continue with Facebook'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
      ],
    );
  }
}
