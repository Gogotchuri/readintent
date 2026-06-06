import "dart:async";

import "package:dio/dio.dart";
import "package:readintent_flutter/core/connect_transport.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "server_health.g.dart";

const _healthyInterval = Duration(seconds: 30);
const _unhealthyInterval = Duration(seconds: 5);

/// ServerHealth tracks whether the backend is reachable and healthy by polling
/// the `/health` endpoint. A response with HTTP status >= 500, a timeout, or a
/// connection error is treated as unhealthy; any response < 500 means the
/// server is reachable. Polling only happens while the device itself has a
/// network connection (the device signal already covers the offline case).
@Riverpod(keepAlive: true)
class ServerHealth extends _$ServerHealth {
  Timer? _timer;
  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      // Inspect the status ourselves instead of letting Dio throw on >= 400.
      validateStatus: (_) => true,
    ),
  );

  @override
  bool build() {
    ref.onDispose(() {
      _timer?.cancel();
      _dio.close(force: true);
    });

    // Re-probe as soon as the device regains connectivity; stop probing when it drops off
    ref.listen(connectivityMonitorProvider, (_, next) {
      final deviceOnline = next.whenData((v) => v).value ?? true;
      if (deviceOnline) {
        _scheduleProbe(const Duration(milliseconds: 500));
      } else {
        _timer?.cancel();
      }
    });

    // Optimistically assume healthy until the first probe completes.
    _scheduleProbe(const Duration(milliseconds: 500));
    return true;
  }

  void _scheduleProbe(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _probe);
  }

  Future<void> _probe() async {
    final deviceOnline =
        ref.read(connectivityMonitorProvider).whenData((v) => v).value ?? true;
    if (!deviceOnline) {
      // The connectivity listener will reschedule when we're back online.
      return;
    }

    bool healthy;
    try {
      final res = await _dio.getUri<void>(Uri.parse("$connectBaseUrl/health"));
      healthy = (res.statusCode ?? 500) < 500;
    } catch (_) {
      healthy = false;
    }

    state = healthy;
    _scheduleProbe(healthy ? _healthyInterval : _unhealthyInterval);
  }

  /// Marks the backend unhealthy immediately and triggers a fast re-probe.
  /// Called by the transport interceptor when a request fails with a
  /// server-unavailable error, so the app reacts without waiting for the next
  /// scheduled poll. Bursts of failures collapse into a single re-probe because
  /// [_scheduleProbe] cancels any pending timer.
  void reportServerError() {
    state = false;
    _scheduleProbe(const Duration(milliseconds: 200));
  }
}
