import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../application/habits/habit_providers.dart';

class AuthPromptPage extends ConsumerStatefulWidget {
  const AuthPromptPage({super.key});

  @override
  ConsumerState<AuthPromptPage> createState() => _AuthPromptPageState();
}

class _AuthPromptPageState extends ConsumerState<AuthPromptPage> {
  bool _loading = false;

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInAnonymously();
      if (!mounted) return;
      context.go('/habits');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/images/login-banner.svg',
                      height: 180,
                      fit: BoxFit.contain,
                      semanticsLabel: 'Login banner',
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Awesome Habits',
                      style: Theme.of(context).textTheme.headlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Track your progress and keep going!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _handleSignIn,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Get started!'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
