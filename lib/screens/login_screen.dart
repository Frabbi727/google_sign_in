import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isSignUp = false; // Toggle between sign-in and sign-up
  bool _useEmailPassword = false; // Toggle between Magic Link and Email/Password

  @override
  void initState() {
    super.initState();

    // Set up callbacks for AuthService
    _authService.onSignInSuccess = (credential) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    };

    _authService.onSignInError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendMagicLink(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Magic link sent! Check your email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _emailPasswordAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authService.emailPassword.signUp(email: email, password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Account created! Verification email sent. Please verify your email before signing in.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
          // Don't navigate - user needs to verify email first
          // Sign out the user so they must verify and sign in again
          await _authService.signOut();
        }
      } else {
        await _authService.emailPassword.signIn(email: email, password: password);

        // Check if email is verified
        await _authService.reloadUser();
        final isVerified = _authService.emailPassword.isEmailVerified;

        if (mounted) {
          if (isVerified) {
            // Email verified - navigate to home
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            // Email not verified - show message and sign out
            await _authService.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('⚠️ Please verify your email before signing in. Check your inbox.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Resend',
                  textColor: Colors.white,
                  onPressed: () async {
                    // Re-sign in temporarily to send verification email
                    await _authService.emailPassword.signIn(email: email, password: password);
                    await _authService.emailPassword.sendEmailVerification();
                    await _authService.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Verification email resent!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_authService.google.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In not configured')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.google.signInWithGoogle();

      // Navigate to home on success
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    if (!_authService.facebook.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facebook Sign-In not configured')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.facebook.signInWithFacebook();

      // Navigate to home on success
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Facebook sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Welcome Icon
              Icon(
                _useEmailPassword ? Icons.lock_outline : Icons.mail_outline,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                _useEmailPassword
                    ? (_isSignUp ? 'Create Account' : 'Welcome Back')
                    : 'Magic Link Sign In',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                _useEmailPassword
                    ? (_isSignUp
                        ? 'Sign up with email and password'
                        : 'Sign in with your credentials')
                    : 'We\'ll send you a passwordless link',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Password Input (only for Email/Password mode)
              if (_useEmailPassword) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 6 characters',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
              ],

              // Main Action Button
              FilledButton(
                onPressed: _isLoading
                    ? null
                    : (_useEmailPassword ? _emailPasswordAuth : _sendMagicLink),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _useEmailPassword
                            ? (_isSignUp ? 'Sign Up' : 'Sign In')
                            : 'Send Magic Link',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),

              const SizedBox(height: 12),

              // Toggle between Magic Link and Email/Password
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _useEmailPassword = !_useEmailPassword;
                          _passwordController.clear();
                        });
                      },
                child: Text(
                  _useEmailPassword
                      ? 'Use Magic Link instead'
                      : 'Use Email & Password instead',
                ),
              ),

              // Toggle between Sign In and Sign Up (for Email/Password)
              if (_useEmailPassword) ...[
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Divider
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // Google Sign-In Button
              if (_authService.google.isAvailable)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

              if (_authService.google.isAvailable) const SizedBox(height: 12),

              // Facebook Sign-In Button
              if (_authService.facebook.isAvailable)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _signInWithFacebook,
                  icon: const Icon(Icons.facebook, color: Colors.blue),
                  label: const Text('Continue with Facebook'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),

              const SizedBox(height: 24),

              // Info text
              if (!_useEmailPassword)
                const Text(
                  'The magic link will expire after 1 hour.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
