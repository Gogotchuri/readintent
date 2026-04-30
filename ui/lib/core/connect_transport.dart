import "package:connectrpc/connect.dart";
import "package:connectrpc/protobuf.dart";
import "package:connectrpc/http2.dart";
import "package:connectrpc/protocol/connect.dart" as connect_p;
import "package:readintent_flutter/core/session_storage.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "connect_transport.g.dart";

const String connectBaseUrl = "http://localhost:5050"; //TODO: Move to config
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

@Riverpod(keepAlive: true)
connect_p.Transport connectTransport(Ref ref) {
  final sessionStorage = ref.read(sessionStorageProvider);
  return connect_p.Transport(
    baseUrl: connectBaseUrl,
    httpClient: createHttpClient(),
    interceptors: [_createAuthInterceptor(sessionStorage)],
    codec: const ProtoCodec(),
  );
}
