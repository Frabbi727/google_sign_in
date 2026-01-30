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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) await _handle(initial);

    _sub = _appLinks.uriLinkStream.listen((uri) async {
      await _handle(uri);
    });
  }

  Future<void> _handle(Uri uri) async {
    try {
      final cred = await _magic.trySignInWithLink(uri.toString());
      if (cred != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      debugPrint('Magic link error: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Waiting for magic link...')),
    );
  }
}
