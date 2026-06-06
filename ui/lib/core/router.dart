import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/features/auth/presentation/login_screen.dart";
import "package:readintent_flutter/features/auth/presentation/registration_screen.dart";
import "package:readintent_flutter/features/auth/presentation/splash_screen.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/features/articles/presentation/article_detail_screen.dart";
import "package:readintent_flutter/features/articles/presentation/player_shell.dart";
import "package:readintent_flutter/features/auth/presentation/device_code_screen.dart";
import "package:readintent_flutter/features/articles/presentation/home.dart";
import "package:readintent_flutter/features/settings/presentation/voice_settings_screen.dart";
import "package:readintent_flutter/models/auth_state.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "router.g.dart";

@riverpod
GoRouter appRouter(Ref ref) {
  // Keep the router alive for the entire app lifecycle
  ref.keepAlive();

  // Notifier to let the router know about the authentication state change and trigger redirection reevaluation
  final notifier = ValueNotifier<AuthState>(const AuthInitial());
  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.value = next;
  });
  ref.onDispose(() => notifier.dispose());

  return GoRouter(
    initialLocation: "/",
    redirectLimit: 5,
    refreshListenable: notifier,
    redirect: (BuildContext context, GoRouterState state) {
      final auth = notifier.value;
      final onAuthPage =
          state.uri.path == "/login" || state.uri.path == "/register";
      final onSplashPage = state.uri.path == "/";
      final isUnauthenticated =
          auth is AuthUnauthenticated || auth is AuthError;
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
      // Unrechable code, but documents the intent
      return null; // Default case, no redirection
    },
    routes: [
      // Auth routes - outside the shell, no mini player
      GoRoute(path: "/", builder: (context, state) => const SplashScreen()),
      GoRoute(path: "/login", builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: "/register",
        builder: (context, state) => const RegistrationScreen(),
      ),

      // Authenticated routes - wrapped in PlayerShell for persistent mini player
      ShellRoute(
        builder: (context, state, child) => PlayerShell(child: child),
        routes: [
          GoRoute(
            path: "/home",
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: "/pair-extension",
            builder: (context, state) => const DeviceCodeScreen(),
          ),
          GoRoute(
            path: "/voice-settings",
            builder: (context, state) => const VoiceSettingsScreen(),
          ),
          GoRoute(
            path: "/articles/:id",
            builder: (context, state) {
              final id = state.pathParameters["id"]!;
              return ArticleDetailScreen(articleId: id);
            },
          ),
        ],
      ),
    ],
  );
}
