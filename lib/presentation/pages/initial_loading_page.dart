import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:awesomehabits/application/habits/habit_providers.dart';

class InitialLoadingPage extends ConsumerWidget {
  const InitialLoadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (prev, next) {
      final user = next.asData?.value;
      if (user == null) {
        context.go('/auth');
      } else {
        context.go('/habits');
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
