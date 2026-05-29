import "package:readintent_flutter/core/session_storage.dart";
import "package:readintent_flutter/features/auth/api/auth_client_exceptions.dart";
import "package:readintent_flutter/features/auth/api/auth_service_client.dart";
import "package:readintent_flutter/core/connect_transport.dart";
import "package:readintent_flutter/features/auth/providers/auth_provider.dart";
import "package:readintent_flutter/models/user.dart";
import "package:connectrpc/connect.dart";
import "package:connectrpc/protobuf.dart";
import "package:connectrpc/http2.dart";
import "package:connectrpc/protocol/connect.dart" as connect_p;
import "package:readintent_flutter/proto/auth/v1/auth_service.connect.client.dart";
import "package:readintent_flutter/proto/auth/v1/auth_service.pb.dart" as auth_pb;

import "package:riverpod_annotation/riverpod_annotation.dart";

part "auth_client.g.dart";

class Session {
  final String sessionToken;
  final User user;

  Session({required this.sessionToken, required this.user});
  factory Session.fromRpcSession(auth_pb.Session session) {
    return Session(sessionToken: session.sessionToken, user: User.fromRpcIdentity(session.identity));
  }
}

class AuthClient {
  final Future<void> Function() onUnauthorized;

  late final AuthServiceClientI _client;

  AuthClient({required this.onUnauthorized, required AuthServiceClientI client}) : _client = client;

  Future<Session> getSession() async {
    try {
      final response = await _client.getSession(auth_pb.GetSessionRequest());
      return Session.fromRpcSession(response.session);
    } on ConnectException catch (e) {
      handleConnectException(e, "validate session");
    } catch (e) {
      throw AuthException("Failed to validate session: $e");
    }
  }

  Future<void> claimGrantCode(String code) async {
    try {
      await _client.claimGrantCode(auth_pb.ClaimGrantCodeRequest(userCode: code));
    } on ConnectException catch (e) {
      handleConnectException(e, "claim grant code");
    } catch (e) {
      throw AuthException("Failed to claim grant code: $e");
    }
  }

  Future<Session> passwordLogin(String email, String password) async {
    try {
      final response = await _client.passwordLogin(
        auth_pb.PasswordLoginRequest(email: email, password: password),
      );
      return Session.fromRpcSession(response.session);
    } on ConnectException catch (e) {
      handleConnectException(e, "login");
    } catch (e) {
      throw AuthException("Failed to login: $e");
    }
  }

  Future<Session> oidcLogin(String provider, String idToken) async {
    try {
      final response = await _client.oIDCLogin(
        auth_pb.OIDCLoginRequest(provider: provider, idToken: idToken),
      );
      return Session.fromRpcSession(response.session);
    } on ConnectException catch (e) {
      handleConnectException(e, "sign in with Google");
    } catch (e) {
      throw AuthException("Failed to sign in with Google: $e");
    }
  }

  Future<Session> passwordRegistration(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      final response = await _client.passwordRegistration(
        auth_pb.PasswordRegistrationRequest(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
        ),
      );
      return Session.fromRpcSession(response.session);
    } on ConnectException catch (e) {
      handleConnectException(e, "register");
    } catch (e) {
      throw AuthException("Failed to register: $e");
    }
  }

  Future<void> logout() async {
    try {
      await _client.logout(auth_pb.LogoutRequest());
    } on ConnectException catch (e) {
      handleConnectException(e, "logout");
    } catch (e) {
      throw AuthException("Failed to logout: $e");
    }
  }
}

@riverpod
AuthClient authService(Ref ref) {
  final transport = ref.read(connectTransportProvider);

  return AuthClient(
    onUnauthorized: () => ref.read(authProvider.notifier).logout(),
    client: ConnecAuthServiceClient(AuthServiceClient(transport)),
  );
}
