import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'magic_link_auth.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _appLinks = AppLinks();
  final _magic = MagicLinkAuth();
  StreamSubscription<Uri>? _sub;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      await _handle(initial);
    } else {
      // No magic link detected, go to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }

    _sub = _appLinks.uriLinkStream.listen((uri) async {
      await _handle(uri);
    });

    if (mounted) {
      setState(() => _checking = false);
    }
  }

  Future<void> _handle(Uri uri) async {
    try {
      debugPrint('Processing magic link: ${uri.toString()}');
      final cred = await _magic.trySignInWithLink(uri.toString());
      if (cred != null && mounted) {
        debugPrint('✅ Magic link successful, navigating to home');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        debugPrint('⚠️ Magic link returned null credential');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      debugPrint('❌ Magic link error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e')),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_checking) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Checking magic link...'),
            ] else ...[
              const Text('Processing...'),
            ],
          ],
        ),
      ),
    );
  }
}
