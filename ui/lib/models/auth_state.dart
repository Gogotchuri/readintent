import "package:readintent_flutter/features/auth/api/auth_client_exceptions.dart";
import "package:readintent_flutter/models/user.dart";

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
  final List<FieldError> fieldErrors;

  const AuthError({required this.message, this.fieldErrors = const []});

  /// getFieldErrors returns the error messages for a specific field if it exists, otherwise null
  List<String>? getFieldErrors(String field) {
    final errors = fieldErrors.where((e) => e.field == field).map((e) => e.description).toList();
    return errors.isEmpty ? null : errors;
  }

  String? getJoinedFieldErrors(String field) {
    final errors = getFieldErrors(field);
    if (errors == null || errors.isEmpty) return null;
    return errors.join(", ");
  }

  /// Get general field errors
  List<String>? getGeneralErrors() {
    var l = getFieldErrors("general");
    l ??= [];
    l.insert(0, message);
    return l;
  }
}
