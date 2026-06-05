import "dart:async";

import "package:fake_async/fake_async.dart";
import "package:fixnum/fixnum.dart";
import "package:flutter_test/flutter_test.dart";
import "package:readintent_flutter/features/articles/providers/article_updates_channel.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

articles_pb.StreamArticleUpdatesResponse _updated({int id = 1}) {
  return articles_pb.StreamArticleUpdatesResponse(
    eventType: "updated",
    article: articles_pb.ArticlePreview(id: Int64(id), title: "Article $id", status: "ready"),
  );
}

articles_pb.StreamArticleUpdatesResponse _heartbeat() {
  return articles_pb.StreamArticleUpdatesResponse(eventType: "heartbeat");
}

/// Hands out a fresh single-subscription controller per connect() call so the
/// test can drive each connection attempt independently.
class _FakeConnect {
  final List<StreamController<articles_pb.StreamArticleUpdatesResponse>> controllers = [];

  Stream<articles_pb.StreamArticleUpdatesResponse> call() {
    final c = StreamController<articles_pb.StreamArticleUpdatesResponse>();
    controllers.add(c);
    return c.stream;
  }

  StreamController<articles_pb.StreamArticleUpdatesResponse> get last => controllers.last;
  int get attempts => controllers.length;
}

void main() {
  late _FakeConnect connect;
  late bool online;
  late ArticleUpdatesChannel channel;
  late List<articles_pb.ArticlePreview> previews;
  late List<bool> pollingModes;
  late int resyncCount;

  // Short tunables so fake time advances are easy to reason about.
  const minReconnect = Duration(seconds: 1);
  const maxReconnect = Duration(seconds: 8);
  const maxStreamFailures = 3;
  const fallbackRetry = Duration(seconds: 60);

  void setUpChannel() {
    connect = _FakeConnect();
    online = true;
    previews = [];
    pollingModes = [];
    resyncCount = 0;
    channel = ArticleUpdatesChannel(
      connect: connect.call,
      isOnline: () => online,
      minReconnect: minReconnect,
      maxReconnect: maxReconnect,
      maxStreamFailures: maxStreamFailures,
      fallbackRetryInterval: fallbackRetry,
    );
    channel.previews.listen(previews.add);
    channel.pollingMode.listen(pollingModes.add);
    channel.resyncRequests.listen((_) => resyncCount++);
  }

  test("forwards updated events as previews and filters heartbeats", () {
    fakeAsync((async) {
      setUpChannel();
      channel.start();
      connect.last.add(_heartbeat());
      connect.last.add(_updated(id: 7));
      async.flushMicrotasks();

      expect(previews, hasLength(1));
      expect(previews.single.id.toInt(), 7);
    });
  });

  test("does not resync on first connect but does after a reconnect", () {
    fakeAsync((async) {
      setUpChannel();
      channel.start();

      // First connection: an event proves we're live, but no resync.
      connect.last.add(_updated());
      async.flushMicrotasks();
      expect(resyncCount, 0);

      // Drop the connection -> reconnect scheduled at min backoff.
      connect.last.close();
      async.flushMicrotasks();
      async.elapse(minReconnect);

      // Reconnect delivers an event -> resync requested to recover missed pushes.
      connect.last.add(_updated());
      async.flushMicrotasks();
      expect(resyncCount, 1);
      expect(connect.attempts, 2);
    });
  });

  test("reconnect backoff doubles between failed attempts", () {
    fakeAsync((async) {
      setUpChannel();
      channel.start();

      // Attempt 1 fails before any event -> reconnect at 1s.
      connect.last.addError(Exception("boom"));
      async.flushMicrotasks();
      async.elapse(minReconnect - const Duration(milliseconds: 1));
      expect(connect.attempts, 1); // not yet
      async.elapse(const Duration(milliseconds: 1));
      expect(connect.attempts, 2); // reconnected

      // Attempt 2 fails -> next backoff is 2s.
      connect.last.addError(Exception("boom"));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2) - const Duration(milliseconds: 1));
      expect(connect.attempts, 2);
      async.elapse(const Duration(milliseconds: 1));
      expect(connect.attempts, 3);
    });
  });

  test("falls back to polling after max failures, then recovers via probe", () {
    fakeAsync((async) {
      setUpChannel();
      channel.start();

      // Fail maxStreamFailures consecutive connects.
      var backoff = minReconnect;
      for (var i = 0; i < maxStreamFailures - 1; i++) {
        connect.last.addError(Exception("boom"));
        async.flushMicrotasks();
        async.elapse(backoff);
        backoff *= 2;
      }
      // Final failure trips the fallback.
      connect.last.addError(Exception("boom"));
      async.flushMicrotasks();
      expect(pollingModes, contains(true));
      expect(pollingModes.last, isTrue);

      // The periodic probe fires; its first event means streaming is back.
      async.elapse(fallbackRetry);
      connect.last.add(_updated());
      async.flushMicrotasks();
      expect(pollingModes.last, isFalse);
    });
  });

  test("suspend halts activity and resume restarts streaming", () {
    fakeAsync((async) {
      setUpChannel();
      channel.start();
      connect.last.add(_updated());
      async.flushMicrotasks();
      final attemptsBeforeSuspend = connect.attempts;

      channel.suspend();
      connect.last.close(); // a drop while suspended must not reconnect
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 5));
      expect(connect.attempts, attemptsBeforeSuspend);

      channel.resume();
      expect(connect.attempts, attemptsBeforeSuspend + 1);
    });
  });

  test("offline cancels the stream and online restarts it", () {
    fakeAsync((async) {
      setUpChannel();
      channel.start();
      final attempts = connect.attempts;

      online = false;
      channel.onConnectivity(false);
      async.elapse(const Duration(minutes: 1));
      expect(connect.attempts, attempts); // no reconnect attempts while offline

      online = true;
      channel.onConnectivity(true);
      expect(connect.attempts, attempts + 1);
    });
  });

  test("dispose closes output streams and stops reconnects", () {
    fakeAsync((async) {
      setUpChannel();
      var previewsDone = false;
      channel.previews.listen(null, onDone: () => previewsDone = true);

      channel.start();
      unawaited(channel.dispose());
      async.flushMicrotasks();
      expect(previewsDone, isTrue);

      // A late drop after dispose must not schedule any reconnect.
      final attempts = connect.attempts;
      connect.last.close();
      async.elapse(const Duration(minutes: 5));
      expect(connect.attempts, attempts);
    });
  });
}
