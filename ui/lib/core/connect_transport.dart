import "package:connectrpc/connect.dart";
import "package:connectrpc/protobuf.dart";
import "package:connectrpc/http2.dart";
import "package:connectrpc/protocol/connect.dart" as connect_p;
import "package:readintent_flutter/core/server_health.dart";
import "package:readintent_flutter/core/session_storage.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "connect_transport.g.dart";

const String connectBaseUrl = String.fromEnvironment(
  "CONNECT_BASE_URL",
  defaultValue: "https://api.readintent.app",
);
const String tokenHeaderKey = "X-Session-Token";

Interceptor _createAuthInterceptor(SessionStorage sessionStorage) {
  return <I extends Object, O extends Object>(AnyFn<I, O> next) {
    return (request) async {
      final sessionToken = await sessionStorage.getToken();
      if (sessionToken != null) {
        request.headers[tokenHeaderKey] = sessionToken;
      }
      return next(request);
    };
  };
}

/// Observes request failures and flags the backend as unhealthy when one
/// reports a server-unavailable error (HTTP 502/503/504/429 -> Code.unavailable),
/// so the app trips offline immediately instead of waiting for the next health
/// poll. It never swallows the error - it rethrows so existing error handling is
/// unchanged. Code.unknown (HTTP 500) is intentionally excluded to avoid
/// false-offline flapping; the periodic probe still catches a sustained 500.
Interceptor _createServerHealthInterceptor(Ref ref) {
  return <I extends Object, O extends Object>(AnyFn<I, O> next) {
    return (request) async {
      try {
        return await next(request);
      } on ConnectException catch (e) {
        if (e.code == Code.unavailable) {
          ref.read(serverHealthProvider.notifier).reportServerError();
        }
        rethrow;
      }
    };
  };
}

@Riverpod(keepAlive: true)
connect_p.Transport connectTransport(Ref ref) {
  final sessionStorage = ref.read(sessionStorageProvider);
  return connect_p.Transport(
    baseUrl: connectBaseUrl,
    httpClient: createHttpClient(),
    interceptors: [
      _createAuthInterceptor(sessionStorage),
      _createServerHealthInterceptor(ref),
    ],
    codec: const ProtoCodec(),
  );
}
