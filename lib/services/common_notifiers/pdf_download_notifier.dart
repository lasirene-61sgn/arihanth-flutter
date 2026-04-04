import 'dart:io';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PDFDownloadState {
  final bool isLoading;
  final String? error;
  final String? filePath;
  final double progress;

  PDFDownloadState({
    this.isLoading = false,
    this.error,
    this.filePath,
    this.progress = 0,
  });

  PDFDownloadState copyWith({
    bool? isLoading,
    String? error,
    String? filePath,
    double? progress,
  }) {
    return PDFDownloadState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Clear error if not provided
      filePath: filePath ?? this.filePath,
      progress: progress ?? this.progress,
    );
  }
}

class PDFDownloadNotifier extends StateNotifier<PDFDownloadState> {
  final ApiClient _apiClient = ApiClient();

  PDFDownloadNotifier() : super(PDFDownloadState());

  Future<void> downloadPDF({String? endpoint, String? fileName}) async {
    if (endpoint == null) {
      state = state.copyWith(error: "No endpoint provided");
      return;
    }

    state = state.copyWith(isLoading: true, progress: 0);

    try {
      final directory = await getTemporaryDirectory();
      final name = fileName ?? "document_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final savePath = "${directory.path}/$name";

      final response = await _apiClient.downloadFile(
        urlPath: endpoint,
        savePath: savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            state = state.copyWith(progress: received / total);
          }
        },
      );

      if (response['status'] == 1) {
        state = state.copyWith(isLoading: false, filePath: savePath, progress: 1);
        
        // On mobile, trigger share/save dialog
        if (!kIsWeb) {
          await Share.shareXFiles([XFile(savePath)], text: name);
        } else {
          // Web handling if needed, though ApiClient downloadFile might need web-specific logic
        }
      } else {
        state = state.copyWith(isLoading: false, error: response['message'] ?? "Download failed");
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearState() {
    state = PDFDownloadState();
  }
}

final pdfDownloadProvider = StateNotifierProvider<PDFDownloadNotifier, PDFDownloadState>((ref) {
  return PDFDownloadNotifier();
});
