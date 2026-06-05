import "dart:async";
import "dart:developer" as developer;

import "package:google_sign_in/google_sign_in.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/core/server_health.dart";
import "package:readintent_flutter/core/session_storage.dart";
import "package:readintent_flutter/features/auth/api/auth_client.dart";
import "package:readintent_flutter/features/auth/api/auth_client_exceptions.dart";
import "package:readintent_flutter/models/auth_state.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "auth_provider.g.dart";

const _googleServerClientId = String.fromEnvironment(
  "GOOGLE_WEB_CLIENT_ID",
  defaultValue: "1036129511964-3s27nho51k8fsukpkgmbqr7lha7pvq1k.apps.googleusercontent.com",
);

/// AuthProvider is the main provider for authentication state management
@riverpod
class Auth extends _$Auth {
  late final AuthClient _authClient;
  late final SessionStorage _sessionStorage;
  // Keeps track of whether we've validated the session with the server at least once since the provider was initialized
  bool _sessionValidated = false;
  Timer? _errorTimer;

  @override
  AuthState build() {
    // Set state to initial while we check if we have a valid session, this should trigger the splash screen in the UI
    state = const AuthInitial();
    _authClient = ref.read(authServiceProvider);
    _sessionStorage = ref.read(sessionStorageProvider);
    // Validate the session if we got back online and the session is not validated
    ref.listen(isOnlineProvider, (previous, isOnlineNow) {
      if (state is! AuthAuthenticated) {
        return;
      }
      if (isOnlineNow && !_sessionValidated) {
        _validateSession();
      }
    });
    // Make sure a scheduled error-clear timer doesn't outlive the provider.
    ref.onDispose(() {
      _errorTimer?.cancel();
      _errorTimer = null;
    });
    // We attempt to restore the session on provider initialization, which will update the state accordingly
    _restoreSession();
    return state;
  }

  /// _restoreSession checks if we have a valid session token and user,
  /// if we do we set the state to authenticated, otherwise unauthenticated
  /// If we're offline but have a token, we optimistically set the state to authenticated with cached user data,
  /// and mark the session as not validated until we can validate it with the server.
  /// This is assumed to be called ONLY during the provider initialization.
  Future<void> _restoreSession() async {
    final token = await _sessionStorage.getToken();
    if (token == null) {
      state = const AuthUnauthenticated();
      return;
    }

    final isOnline = await ref.read(connectivityMonitorProvider.future);
    if (isOnline) {
      // If we're online, we validate the session with the server to ensure it's still valid
      return _validateSession();
    }
    // Since _restoreSession is called only during initialization, this will not interrup disconnected users with a valid session
    _sessionValidated = false; // We haven't validated the session with the server yet
    // If we're offline but have a token, we can optimistically set the state to authenticated with cached user data
    final cachedUser = await _sessionStorage.getUser();
    if (cachedUser != null) {
      state = AuthAuthenticated(sessionToken: token, user: cachedUser);
    } else {
      // If we don't have cached user data, we can't be sure about authentication status, so clear token and set unauthenticated
      await _sessionStorage.clearSession();
      state = const AuthUnauthenticated();
    }
  }

  /// _validateSession validates the session against the server, used to check if the session is still valid once we get back online
  /// This method throws exceptions if there's no internet connection
  Future<void> _validateSession() async {
    try {
      final session = await _authClient.getSession();
      _sessionValidated = true; // Session validation succeeded
      state = AuthAuthenticated(sessionToken: session.sessionToken, user: session.user);
    } on ServerUnavailableException {
      // The backend is unreachable/unhealthy - this is not an auth failure, so
      // keep the optimistic cached session rather than logging the user out.
      // The isOnlineProvider listener re-validates once health recovers.
      _sessionValidated = false;
      ref.read(serverHealthProvider.notifier).reportServerError();
      if (state is AuthAuthenticated) return; // Already showing cached session
      final token = await _sessionStorage.getToken();
      final cachedUser = await _sessionStorage.getUser();
      if (token != null && cachedUser != null) {
        state = AuthAuthenticated(sessionToken: token, user: cachedUser);
      } else {
        await _sessionStorage.clearSession();
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      _sessionValidated = false; // Session validation failed
      // Clear session and set unauthenticated if validation fails
      await _sessionStorage.clearSession();
      state = const AuthUnauthenticated();
    }
  }

  void clearError() {
    _errorTimer?.cancel();
    _errorTimer = null;
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  void _scheduleErrorClear(Duration duration) {
    _errorTimer?.cancel();
    _errorTimer = Timer(duration, clearError);
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
      _sessionValidated = true;
      _errorTimer?.cancel();
      state = AuthAuthenticated(sessionToken: session.sessionToken, user: session.user);
    } on ValidationException catch (e) {
      state = AuthError(message: e.message, fieldErrors: e.fieldErrors);
      _scheduleErrorClear(const Duration(seconds: 5));
    } catch (e) {
      state = AuthError(message: e.toString());
      _scheduleErrorClear(const Duration(seconds: 5));
    }
  }

  /// passwordRegistration attempts to create a new account with email and password
  Future<void> passwordRegistration(String email, String password, String firstName, String lastName) async {
    state = const AuthLoading();
    try {
      final session = await _authClient.passwordRegistration(email, password, firstName, lastName);
      await _sessionStorage.saveToken(session.sessionToken);
      await _sessionStorage.saveUser(session.user);

      _sessionValidated = true;
      state = AuthAuthenticated(sessionToken: session.sessionToken, user: session.user);
    } on ValidationException catch (e) {
      state = AuthError(message: e.message, fieldErrors: e.fieldErrors);
      _scheduleErrorClear(const Duration(seconds: 5));
    } catch (e) {
      state = AuthError(message: e.toString());
      _scheduleErrorClear(const Duration(seconds: 5));
    }
  }

  /// googleSignIn attempts to sign in with Google via OIDC
  Future<void> googleSignIn() async {
    state = const AuthLoading();
    try {
      developer.log("GoogleSignIn: starting with serverClientId=$_googleServerClientId", name: "auth");
      final gSignIn = GoogleSignIn(serverClientId: _googleServerClientId);
      final account = await gSignIn.signIn();
      if (account == null) {
        developer.log("GoogleSignIn: user cancelled", name: "auth");
        state = const AuthUnauthenticated();
        return;
      }
      developer.log("GoogleSignIn: account=${account.email}", name: "auth");
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      developer.log(
        "GoogleSignIn: idToken=${idToken != null ? '${idToken.substring(0, 20)}...' : 'null'}",
        name: "auth",
      );
      if (idToken == null) {
        state = const AuthError(message: "Failed to obtain ID token from Google");
        _scheduleErrorClear(const Duration(seconds: 5));
        return;
      }
      final session = await _authClient.oidcLogin("google", idToken);
      developer.log("GoogleSignIn: oidcLogin succeeded", name: "auth");
      await _sessionStorage.saveToken(session.sessionToken);
      await _sessionStorage.saveUser(session.user);
      _sessionValidated = true;
      _errorTimer?.cancel();
      state = AuthAuthenticated(sessionToken: session.sessionToken, user: session.user);
    } on ValidationException catch (e) {
      developer.log("GoogleSignIn: ValidationException: ${e.message}", name: "auth");
      state = AuthError(message: e.message, fieldErrors: e.fieldErrors);
      _scheduleErrorClear(const Duration(seconds: 5));
    } catch (e, st) {
      developer.log("GoogleSignIn: error: $e\n$st", name: "auth");
      state = AuthError(message: e.toString());
      _scheduleErrorClear(const Duration(seconds: 5));
    }
  }

  /// claimGrantCode is used for browser extension authentication flow
  Future<void> claimGrantCode(String code) async {
    await _authClient.claimGrantCode(code);
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
      _sessionValidated = false;
      _errorTimer?.cancel();
      state = const AuthUnauthenticated();
    }
  }
}
