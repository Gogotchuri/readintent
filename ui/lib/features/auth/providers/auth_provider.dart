import 'package:readintent_flutter/core/session_storage.dart';
import 'package:readintent_flutter/features/auth/api/auth_client.dart';
import 'package:readintent_flutter/models/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_provider.g.dart';

/// AuthState Sealed class used for auth state machine
/// This has the following implementations:
///
/// `AuthInitial` - State before we know / validated the actual login state, required splash screen
///
/// `AuthLoading` - Loading state after user requests login
///
/// `AuthAuthenticated` - Successful authentication state
///
/// `AuthUnauthenticated` - User is unauthenticated, but no error needs to be displayed, first time app open for example
///
/// `AuthError` - Authentication request returned error response and we need to alter the user
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String sessionToken;
  final User user;

  const AuthAuthenticated({required this.sessionToken, required this.user});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
}

/// AuthProvider is the main provider for authentication state management
@riverpod
class Auth extends _$Auth {
  late final AuthClient _authClient;
  late final SessionStorage _sessionStorage;

  @override
  AuthState build() {
    // Set state to initial while we check if we have a valid session, this should trigger the splash screen in the UI
    state = const AuthInitial();
    _authClient = ref.read(authServiceProvider);
    _sessionStorage = ref.read(sessionStorageProvider);
    // Start _restoreSession on provider initialization, which will alter the state as needed
    _restoreSession();
    return state;
  }

  /// _restoreSession checks if we have a valid session token and user,
  /// if we do we set the state to authenticated, otherwise unauthenticated
  Future<void> _restoreSession() async {
    final token = await _sessionStorage.getToken();
    if (token == null) {
      state = const AuthUnauthenticated();
      return;
    }
    try {
      // TODO differentiate between 401 and other errors and set state to unauthenticated or error accordingly
      final session = await _authClient.getSession();
      state = AuthAuthenticated(
        sessionToken: session.sessionToken,
        user: session.user,
      );
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  /// passwordLogin attempts to login with email and password,
  /// if successful it saves the session and user data and sets the state to AuthAuthenticated,
  /// otherwise sets the state to AuthError
  Future<void> passwordLogin(String email, String password) async {
    state = const AuthLoading();
    try {
      final session = await _authClient.passwordLogin(email, password);
      await _sessionStorage.saveToken(session.sessionToken);
      await _sessionStorage.saveUser(session.user);

      state = AuthAuthenticated(
        sessionToken: session.sessionToken,
        user: session.user,
      );
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  /// passwordRegistration attempts to create a new account with email and password
  Future<void> passwordRegistration(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    state = const AuthLoading();
    try {
      final session = await _authClient.passwordRegistration(
        email,
        password,
        firstName,
        lastName,
      );
      await _sessionStorage.saveToken(session.sessionToken);
      await _sessionStorage.saveUser(session.user);

      state = AuthAuthenticated(
        sessionToken: session.sessionToken,
        user: session.user,
      );
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  /// logout clears the session and user data and sets the state to unauthenticated
  Future<void> logout() async {
    if (state is! AuthAuthenticated) {
      return;
    }
    state = const AuthLoading();
    try {
      await _authClient.logout();
    } catch (e) {
      // We can ignore logout errors and proceed to clear session and set unauthenticated state
    } finally {
      await _sessionStorage.clearSession();
      state = const AuthUnauthenticated();
    }
  }
}
