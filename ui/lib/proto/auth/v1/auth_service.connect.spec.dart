//
//  Generated code. Do not modify.
//  source: auth/v1/auth_service.proto
//

import "package:connectrpc/connect.dart" as connect;
import "auth_service.pb.dart" as authv1auth_service;

abstract final class AuthService {
  /// Fully-qualified name of the AuthService service.
  static const name = 'auth.v1.AuthService';

  static const passwordLogin = connect.Spec(
    '/$name/PasswordLogin',
    connect.StreamType.unary,
    authv1auth_service.PasswordLoginRequest.new,
    authv1auth_service.PasswordLoginResponse.new,
  );

  static const passwordRegistration = connect.Spec(
    '/$name/PasswordRegistration',
    connect.StreamType.unary,
    authv1auth_service.PasswordRegistrationRequest.new,
    authv1auth_service.PasswordRegistrationResponse.new,
  );

  static const logout = connect.Spec(
    '/$name/Logout',
    connect.StreamType.unary,
    authv1auth_service.LogoutRequest.new,
    authv1auth_service.LogoutResponse.new,
  );

  static const getSession = connect.Spec(
    '/$name/GetSession',
    connect.StreamType.unary,
    authv1auth_service.GetSessionRequest.new,
    authv1auth_service.GetSessionResponse.new,
  );

  static const health = connect.Spec(
    '/$name/Health',
    connect.StreamType.unary,
    authv1auth_service.HealthRequest.new,
    authv1auth_service.HealthResponse.new,
  );
}
