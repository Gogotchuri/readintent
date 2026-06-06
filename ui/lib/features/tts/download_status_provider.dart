import "package:flutter_riverpod/flutter_riverpod.dart";

class DownloadStatus {
  final String label;

  /// 0.0-1.0 for determinate progress, -1 for indeterminate
  final double progress;

  const DownloadStatus(this.label, this.progress);
}

class DownloadStatusNotifier extends Notifier<DownloadStatus?> {
  @override
  DownloadStatus? build() => null;

  void set(DownloadStatus? status) {
    state = status;
  }
}

final downloadStatusProvider =
    NotifierProvider<DownloadStatusNotifier, DownloadStatus?>(
      DownloadStatusNotifier.new,
    );
