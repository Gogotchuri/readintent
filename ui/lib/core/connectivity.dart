import "dart:async";

import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/server_health.dart";

final connectivityMonitorProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  final controller = StreamController<bool>();

  // Check initial status
  connectivity.checkConnectivity().then((results) {
    controller.add(!results.contains(ConnectivityResult.none));
  });

  // Listen for changes
  final sub = connectivity.onConnectivityChanged.listen((results) {
    controller.add(!results.contains(ConnectivityResult.none));
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// isOnlineProvider reports whether the app can reach the backend. It combines
/// the device's network connectivity with the backend's health, so a healthy
/// device with an unreachable/unhealthy server is treated as offline.
final isOnlineProvider = Provider<bool>((ref) {
  final deviceOnline =
      ref.watch(connectivityMonitorProvider).whenData((v) => v).value ?? true;
  final serverHealthy = ref.watch(serverHealthProvider);
  return deviceOnline && serverHealthy;
});
