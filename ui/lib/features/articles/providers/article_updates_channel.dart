import "dart:async";
import "dart:math";

import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

// Streaming reconnect with backoff.
const _defaultMinReconnect = Duration(seconds: 1);
const _defaultMaxReconnect = Duration(seconds: 30);
// After many consecutive stream failures we drop to the polling fallback.
const _defaultMaxStreamFailures = 3;
// While in fallback, how often we check whether the stream is reachable again.
const _defaultFallbackRetryInterval = Duration(seconds: 120);

/// Owns the article-update connection lifecycle: a primary server-push stream
/// with exponential-backoff reconnect, a polling fallback after repeated
/// failures, and a probe stream that detects when streaming is reachable again.
///
/// Surfaces three streams the consumer reacts to and exposes lifecycle hooks
/// (start/connectivity/suspend/resume/dispose). The consumer owns the actual polling and data state.
class ArticleUpdatesChannel {
  ArticleUpdatesChannel({
    required Stream<articles_pb.StreamArticleUpdatesResponse> Function() connect,
    required bool Function() isOnline,
    Duration minReconnect = _defaultMinReconnect,
    Duration maxReconnect = _defaultMaxReconnect,
    int maxStreamFailures = _defaultMaxStreamFailures,
    Duration fallbackRetryInterval = _defaultFallbackRetryInterval,
  }) : _connect = connect,
       _isOnline = isOnline,
       _minReconnect = minReconnect,
       _maxReconnect = maxReconnect,
       _maxStreamFailures = maxStreamFailures,
       _fallbackRetryInterval = fallbackRetryInterval,
       _reconnectBackoff = minReconnect;

  final Stream<articles_pb.StreamArticleUpdatesResponse> Function() _connect;
  final bool Function() _isOnline;
  final Duration _minReconnect;
  final Duration _maxReconnect;
  final int _maxStreamFailures;
  final Duration _fallbackRetryInterval;

  final _previews = StreamController<articles_pb.ArticlePreview>.broadcast();
  final _pollingMode = StreamController<bool>.broadcast();
  final _resyncRequests = StreamController<void>.broadcast();

  StreamSubscription<articles_pb.StreamArticleUpdatesResponse>? _streamSub;
  // Probe subscription used while in fallback to detect stream recovery.
  StreamSubscription<articles_pb.StreamArticleUpdatesResponse>? _probeSub;
  Timer? _reconnectTimer;
  Timer? _fallbackRetryTimer;
  // Bumped on every subscribe/cancel so stale stream callbacks are ignored.
  int _streamGen = 0;
  int _streamFailureCount = 0;
  Duration _reconnectBackoff;
  bool _inFallback = false;
  // True while the app is backgrounded; suppresses all stream/poll activity.
  bool _suspended = false;
  bool _disposed = false;
  // Whether we've ever had a live connection. The first connect does not
  // request a resync (the caller already has fresh data); later reconnects do.
  bool _connectedOnce = false;

  /// Reconciled preview pushes (heartbeats filtered out).
  Stream<articles_pb.ArticlePreview> get previews => _previews.stream;

  /// true  => consumer should run its polling fallback;
  /// false => streaming is healthy, stop polling.
  Stream<bool> get pollingMode => _pollingMode.stream;

  /// Fires when a (re)connection is established after a drop, so the consumer
  /// can refetch to recover updates missed while disconnected. Deliberately
  /// does not fire on the first successful connect.
  Stream<void> get resyncRequests => _resyncRequests.stream;

  /// Begins streaming. No-op while suspended/disposed; the connectivity
  /// listener restarts us when offline.
  void start() {
    if (_suspended || _disposed) return;
    _cancelStream();
    if (!_isOnline()) return;
    _subscribe(_streamGen);
  }

  /// React to connectivity changes by stopping/restarting the stream.
  void onConnectivity(bool online) {
    if (_disposed) return;
    if (online) {
      _resetBackoff();
      if (_inFallback) {
        _tryExitFallback();
      } else {
        start();
      }
    } else {
      _cancelStream();
    }
  }

  /// Suspends all background activity while the app is backgrounded.
  void suspend() {
    _suspended = true;
    _cancelStream();
    _cancelProbe();
    _exitFallback();
  }

  /// Resumes streaming when the app returns to the foreground.
  void resume() {
    if (!_suspended) return;
    _suspended = false;
    _resetBackoff();
    start();
  }

  Future<void> dispose() async {
    _disposed = true;
    _cancelStream();
    _cancelProbe();
    _fallbackRetryTimer?.cancel();
    _fallbackRetryTimer = null;
    await _previews.close();
    await _pollingMode.close();
    await _resyncRequests.close();
  }

  void _resetBackoff() {
    _streamFailureCount = 0;
    _reconnectBackoff = _minReconnect;
  }

  /// Cancels any active stream/reconnect and invalidates in-flight callbacks.
  void _cancelStream() {
    _streamGen++;
    _streamSub?.cancel();
    _streamSub = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _subscribe(int gen) {
    var gotEvent = false;
    _streamSub = _connect().listen(
      (resp) {
        if (gen != _streamGen) return; // superseded by a newer subscription
        if (!gotEvent) {
          gotEvent = true;
          _onConnected();
        }
        _handleEvent(resp);
      },
      onError: (_) => _handleDisconnect(gen),
      onDone: () => _handleDisconnect(gen),
      cancelOnError: true,
    );
  }

  /// Called once per subscription, on its first received event (any event,
  /// including a heartbeat, proves the connection is live).
  void _onConnected() {
    _resetBackoff();
    if (_connectedOnce) {
      _emit(_resyncRequests, null);
    } else {
      _connectedOnce = true;
    }
  }

  void _handleEvent(articles_pb.StreamArticleUpdatesResponse resp) {
    // Heartbeats only keep the connection alive; nothing to merge.
    if (resp.eventType == "heartbeat") return;
    _emit(_previews, resp.article);
  }

  void _handleDisconnect(int gen) {
    if (gen != _streamGen) return; // stale callback from an old subscription
    _cancelStream();
    if (_suspended || _disposed) return;
    _streamFailureCount++;
    if (_streamFailureCount >= _maxStreamFailures) {
      _enterFallback();
      return;
    }
    final backoff = _reconnectBackoff;
    _reconnectTimer = Timer(backoff, () {
      if (_suspended || _disposed || !_isOnline()) return;
      start();
    });
    _reconnectBackoff = Duration(
      milliseconds: min(_reconnectBackoff.inMilliseconds * 2, _maxReconnect.inMilliseconds),
    );
  }

  void _enterFallback() {
    if (_inFallback) return;
    _inFallback = true;
    _cancelStream();
    _emit(_pollingMode, true); // consumer starts its polling loop
    _fallbackRetryTimer = Timer.periodic(_fallbackRetryInterval, (_) {
      if (_suspended || _disposed || !_isOnline()) return;
      _tryExitFallback();
    });
  }

  /// Opens a probe stream; the first event it receives means the stream is
  /// reachable again, so we leave fallback and resume normal streaming.
  void _tryExitFallback() {
    if (_probeSub != null || _disposed) return; // a probe is already in flight
    _probeSub = _connect().listen(
      (resp) {
        _cancelProbe();
        _exitFallback();
        _handleEvent(resp);
        start();
      },
      onError: (_) => _cancelProbe(),
      onDone: _cancelProbe,
      cancelOnError: true,
    );
  }

  void _cancelProbe() {
    _probeSub?.cancel();
    _probeSub = null;
  }

  void _exitFallback() {
    _fallbackRetryTimer?.cancel();
    _fallbackRetryTimer = null;
    if (!_inFallback) return;
    _inFallback = false;
    _emit(_pollingMode, false); // consumer stops its polling loop
  }

  void _emit<T>(StreamController<T> controller, T value) {
    if (!controller.isClosed) controller.add(value);
  }
}
