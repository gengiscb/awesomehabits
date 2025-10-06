import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:awesomehabits/presentation/pages/auth_prompt_page.dart';
import 'package:awesomehabits/presentation/pages/habit_list_page.dart';
import 'package:awesomehabits/presentation/pages/initial_loading_page.dart';
import 'package:awesomehabits/application/habits/habit_providers.dart';

class RouterNotifier extends Notifier<GoRouter> {
  @override
  GoRouter build() {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const InitialLoadingPage(),
        ),
        GoRoute(
          path: '/auth',
          name: 'auth',
          builder: (context, state) => const AuthPromptPage(),
        ),
        GoRoute(
          path: '/habits',
          name: 'habits',
          builder: (context, state) => const HabitListPage(),
        ),
      ],
      redirect: (context, state) {
        final isSplash = state.matchedLocation == '/';
        if (isSplash) return null; // Let the splash decide via InitialLoadingPage

        final auth = ref.read(authStateProvider).value;
        final isLoggedIn = auth != null;
        final isAuthRoute = state.matchedLocation == '/auth';

        if (!isLoggedIn && !isAuthRoute) return '/auth';
        if (isLoggedIn && isAuthRoute) return '/habits';
        return null;
      },
    );

    // Refresh router whenever auth state changes.
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (prev, next) {
      router.refresh();
    });

    return router;
  }
}

final routerProvider = NotifierProvider<RouterNotifier, GoRouter>(RouterNotifier.new);

