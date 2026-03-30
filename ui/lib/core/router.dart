import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:readintent_flutter/features/auth/presentation/login_screen.dart';
import 'package:readintent_flutter/features/auth/presentation/registration_screen.dart';
import 'package:readintent_flutter/features/auth/presentation/splash_screen.dart';
import 'package:readintent_flutter/features/auth/providers/auth_provider.dart';
import 'package:readintent_flutter/features/articles/presentation/home.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final auth = ref.watch(authProvider);

  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final onAuthPage = state.uri.path == '/login' || state.uri.path == '/register';
    final onSplashPage = state.uri.path == '/';

    if (!onAuthPage && !onSplashPage) {
      // If the user is not authenticated, redirect to the login page
      if (auth is AuthUnauthenticated || auth is AuthError) {
        return '/login';
      }
    } else {
      // If the user is authenticated and tries to go to an auth page, redirect to home
      if (auth is AuthAuthenticated) {
        return '/home';
      }
    }
    return null; // no redirection
  }

  return GoRouter(initialLocation: '/', redirect: redirect, routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegistrationScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ]);
}
