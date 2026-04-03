import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/features/auth/presentation/login_screen.dart";
import "package:readintent_flutter/features/auth/presentation/registration_screen.dart";
import "package:readintent_flutter/features/auth/presentation/splash_screen.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/features/articles/presentation/home.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "router.g.dart";

@riverpod
GoRouter appRouter(Ref ref) {
  final auth = ref.watch(authProvider);

  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final onAuthPage = state.uri.path == "/login" || state.uri.path == "/register";
    final onSplashPage = state.uri.path == "/";
    final isUnauthenticated = auth is AuthUnauthenticated || auth is AuthError;
    final undeterminedAuthState = auth is AuthInitial || auth is AuthLoading;
    final isAuthenticated = auth is AuthAuthenticated;

    // If the use is authenticated but tries to access auth pages or splash screen, send them to the home page
    if (isAuthenticated) {
      if (onAuthPage || onSplashPage) {
        return "/home";
      }
      return null; // No redirection, stay on the current page
    }
    // If the user is unauthenticated but tries to access a protected page, send them to the login page
    if (isUnauthenticated) {
      if (!onAuthPage) {
        return "/login";
      }
      return null; // No redirection, stay on the current page
    }

    // If the user's authentication state is undetermined, stay on the current page
    if (undeterminedAuthState) {
      return null;
    }
    return null; // Default case, no redirection
  }

  return GoRouter(
    initialLocation: "/",
    redirect: redirect,
    routes: [
      GoRoute(path: "/", builder: (context, state) => const SplashScreen()),
      GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),
      GoRoute(path: "/register", builder: (context, state) => const RegistrationScreen()),
      GoRoute(path: "/home", builder: (context, state) => const HomeScreen()),
    ],
  );
}
