//
//  Generated code. Do not modify.
//  source: auth/v1/auth_service.proto
//

import "package:connectrpc/connect.dart" as connect;
import "auth_service.pb.dart" as authv1auth_service;
import "auth_service.connect.spec.dart" as specs;

extension type AuthServiceClient (connect.Transport _transport) {
  Future<authv1auth_service.PasswordLoginResponse> passwordLogin(
    authv1auth_service.PasswordLoginRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.passwordLogin,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<authv1auth_service.PasswordRegistrationResponse> passwordRegistration(
    authv1auth_service.PasswordRegistrationRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.passwordRegistration,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<authv1auth_service.LogoutResponse> logout(
    authv1auth_service.LogoutRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.logout,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<authv1auth_service.GetSessionResponse> getSession(
    authv1auth_service.GetSessionRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.getSession,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<authv1auth_service.HealthResponse> health(
    authv1auth_service.HealthRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.health,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }

  Future<authv1auth_service.ClaimGrantCodeResponse> claimGrantCode(
    authv1auth_service.ClaimGrantCodeRequest input, {
    connect.Headers? headers,
    connect.AbortSignal? signal,
    Function(connect.Headers)? onHeader,
    Function(connect.Headers)? onTrailer,
  }) {
    return connect.Client(_transport).unary(
      specs.AuthService.claimGrantCode,
      input,
      signal: signal,
      headers: headers,
      onHeader: onHeader,
      onTrailer: onTrailer,
    );
  }
}
