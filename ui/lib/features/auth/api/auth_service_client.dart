import "package:readintent_flutter/proto/auth/v1/auth_service.connect.client.dart";
import "package:readintent_flutter/proto/auth/v1/auth_service.pb.dart"
    as auth_pb;

/// Interface for the auth RPC calls. Wraps the generated connectRPC client
/// so it can be mocked in tests.
abstract class AuthServiceClientI {
  Future<auth_pb.ClaimGrantCodeResponse> claimGrantCode(
    auth_pb.ClaimGrantCodeRequest input,
  );
  Future<auth_pb.PasswordLoginResponse> passwordLogin(
    auth_pb.PasswordLoginRequest input,
  );
  Future<auth_pb.PasswordRegistrationResponse> passwordRegistration(
    auth_pb.PasswordRegistrationRequest input,
  );
  Future<auth_pb.GetSessionResponse> getSession(
    auth_pb.GetSessionRequest input,
  );
  Future<auth_pb.LogoutResponse> logout(auth_pb.LogoutRequest input);
  Future<auth_pb.HealthResponse> health(auth_pb.HealthRequest input);
  Future<auth_pb.OIDCLoginResponse> oIDCLogin(auth_pb.OIDCLoginRequest input);
}

// Concrete implementation of the AuthServiceClientI that uses the generated connectRPC client.
class ConnecAuthServiceClient implements AuthServiceClientI {
  final AuthServiceClient _client;
  ConnecAuthServiceClient(this._client);

  @override
  Future<auth_pb.ClaimGrantCodeResponse> claimGrantCode(
    auth_pb.ClaimGrantCodeRequest input,
  ) => _client.claimGrantCode(input);

  @override
  Future<auth_pb.PasswordLoginResponse> passwordLogin(
    auth_pb.PasswordLoginRequest input,
  ) => _client.passwordLogin(input);

  @override
  Future<auth_pb.PasswordRegistrationResponse> passwordRegistration(
    auth_pb.PasswordRegistrationRequest input,
  ) => _client.passwordRegistration(input);

  @override
  Future<auth_pb.GetSessionResponse> getSession(
    auth_pb.GetSessionRequest input,
  ) => _client.getSession(input);

  @override
  Future<auth_pb.LogoutResponse> logout(auth_pb.LogoutRequest input) =>
      _client.logout(input);

  @override
  Future<auth_pb.HealthResponse> health(auth_pb.HealthRequest input) =>
      _client.health(input);

  @override
  Future<auth_pb.OIDCLoginResponse> oIDCLogin(auth_pb.OIDCLoginRequest input) =>
      _client.oIDCLogin(input);
}
