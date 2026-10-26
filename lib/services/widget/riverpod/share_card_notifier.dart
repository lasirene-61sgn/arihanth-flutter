import 'dart:async';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';

enum ShareCardStatus { initial, loading, loaded, error }

class ShareCardState {
  final ShareCardStatus status;
  final List<XFile> preparedFiles;
  final String statusMessage;
  final double progress;
  final int elapsedSeconds;
  final int totalCount;
  final int completedCount;
  final String? errorMessage;

  const ShareCardState({
    this.status = ShareCardStatus.initial,
    this.preparedFiles = const [],
    this.statusMessage = '',
    this.progress = 0.0,
    this.elapsedSeconds = 0,
    this.totalCount = 0,
    this.completedCount = 0,
    this.errorMessage,
  });

  bool get isLoading => status == ShareCardStatus.loading;
  bool get isLoaded => status == ShareCardStatus.loaded;
  bool get isError => status == ShareCardStatus.error;
  int get pendingCount => (totalCount - completedCount) < 0 ? 0 : (totalCount - completedCount);

  ShareCardState copyWith({
    ShareCardStatus? status,
    List<XFile>? preparedFiles,
    String? statusMessage,
    double? progress,
    int? elapsedSeconds,
    int? totalCount,
    int? completedCount,
    String? errorMessage,
  }) {
    return ShareCardState(
      status: status ?? this.status,
      preparedFiles: preparedFiles ?? this.preparedFiles,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      totalCount: totalCount ?? this.totalCount,
      completedCount: completedCount ?? this.completedCount,
      errorMessage: errorMessage,
    );
  }
}

class ShareCardNotifier extends StateNotifier<ShareCardState> {
  Timer? _timer;

  ShareCardNotifier() : super(const ShareCardState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isLoading) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      } else {
        timer.cancel();
      }
    });
  }

  /// Automatically prepare, render, and compress high-res card files when bottom sheet opens
  Future<void> prepareShareCards(BuildContext context, List<ShareCardItem> items) async {
    if (items.isEmpty) {
      state = state.copyWith(
        status: ShareCardStatus.error,
        errorMessage: "No items to share",
      );
      return;
    }

    state = ShareCardState(
      status: ShareCardStatus.loading,
      statusMessage: "Initializing share cards...",
      progress: 0.1,
      elapsedSeconds: 0,
      totalCount: items.length,
      completedCount: 0,
    );
    _startTimer();

    try {
      final files = await ShareCardService.captureCardFiles(
        context,
        items,
        onProgress: (completed, total) {
          final double computedProgress = 0.2 + (0.8 * (completed / total));
          state = state.copyWith(
            completedCount: completed,
            totalCount: total,
            progress: computedProgress,
            statusMessage: "Compressed $completed of $total cards...",
          );
        },
      );

      if (files.isEmpty) {
        _timer?.cancel();
        state = state.copyWith(
          status: ShareCardStatus.error,
          errorMessage: "Failed to generate share images",
        );
        return;
      }

      _timer?.cancel();
      state = state.copyWith(
        status: ShareCardStatus.loaded,
        preparedFiles: files,
        completedCount: items.length,
        totalCount: items.length,
        progress: 1.0,
        statusMessage: "Ready to share!",
      );
    } catch (e) {
      _timer?.cancel();
      state = state.copyWith(
        status: ShareCardStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    _timer?.cancel();
    state = const ShareCardState();
  }
}

final shareCardProvider =
    StateNotifierProvider.autoDispose<ShareCardNotifier, ShareCardState>((ref) {
  return ShareCardNotifier();
});
