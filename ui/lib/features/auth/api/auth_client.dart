import 'package:readintent_flutter/core/session_storage.dart';
import 'package:readintent_flutter/features/auth/api/auth_client_exceptions.dart';
import 'package:readintent_flutter/features/auth/providers/auth_provider.dart';
import 'package:readintent_flutter/models/user.dart';
import 'package:connectrpc/connect.dart';
import 'package:connectrpc/protobuf.dart';
import 'package:connectrpc/http2.dart';
import 'package:connectrpc/protocol/connect.dart' as connect_p;
import 'package:readintent_flutter/proto/auth/v1/auth_service.connect.client.dart';
import 'package:readintent_flutter/proto/auth/v1/auth_service.pb.dart'
    as auth_pb;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_client.g.dart';

const String baseUrl = "http://localhost:8000"; //TODO: Move to config
const String tokenHeaderKey = "X-Session-Token";

class Session {
  final String sessionToken;
  final User user;

  Session({required this.sessionToken, required this.user});
  factory Session.fromRpcSession(auth_pb.Session session) {
    return Session(
      sessionToken: session.sessionToken,
      user: User.fromRpcIdentity(session.identity),
    );
  }
}

class AuthClient {
  final Future<String?> Function() getToken;
  final Future<void> Function() onUnauthorized;

  //TODO: Need to mock this client for testing. I have 2 options: A) Create an abstract class and use that and B) Use connectRPC's built in testing support (need to research this more)
  late final AuthServiceClient _client;

  AuthClient({required this.getToken, required this.onUnauthorized}) {
    final transport = connect_p.Transport(
      baseUrl: baseUrl,
      httpClient: createHttpClient(),
      interceptors: [getAuthInterceptor()],
      codec: const ProtoCodec(),
    );
    _client = AuthServiceClient(transport);
  }

  Interceptor getAuthInterceptor() {
    return <I extends Object, O extends Object>(AnyFn<I, O> next) {
      return (request) async {
        final sessionToken = await getToken();
        if (sessionToken != null) {
          request.headers[tokenHeaderKey] = sessionToken;
        }
        return next(request);
      };
    };
  }

  Future<Session> getSession() async {
    try {
      final response = await _client.getSession(auth_pb.GetSessionRequest());
      return Session.fromRpcSession(response.session);
    } on ConnectException catch (e) {
      handleConnectException(e, 'validate session');
    } catch (e) {
      throw AuthException('Failed to validate session: $e');
    }
  }

  Future<Session> passwordLogin(String email, String password) async {
    try {
      final response = await _client.passwordLogin(
        auth_pb.PasswordLoginRequest(email: email, password: password),
      );
      return Session.fromRpcSession(response.session);
    } on ConnectException catch (e) {
      handleConnectException(e, 'login');
    } catch (e) {
      throw AuthException('Failed to login: $e');
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
      handleConnectException(e, 'register');
    } catch (e) {
      throw AuthException('Failed to register: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _client.logout(auth_pb.LogoutRequest());
    } on ConnectException catch (e) {
      handleConnectException(e, 'logout');
    } catch (e) {
      throw AuthException('Failed to logout: $e');
    }
  }
}

@riverpod
AuthClient authService(Ref ref) {
  final sessionStorage = ref.read(sessionStorageProvider);
  return AuthClient(
    getToken: sessionStorage.getToken,
    onUnauthorized: () => ref.read(authProvider.notifier).logout(),
  );
}
