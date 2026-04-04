import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:pdfx/pdfx.dart';
import 'package:internet_file/internet_file.dart';
import '../pdf/pdf_redaction_service.dart';

class PdfViewerState {
  final bool isLoading;
  final String? errorMessage;
  final List<Uint8List> redactedPages;
  final PdfControllerPinch? controller;
  final int totalPages;

  PdfViewerState({
    this.isLoading = false,
    this.errorMessage,
    this.redactedPages = const [],
    this.controller,
    this.totalPages = 0,
  });

  PdfViewerState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Uint8List>? redactedPages,
    PdfControllerPinch? controller,
    int? totalPages,
  }) {
    return PdfViewerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      redactedPages: redactedPages ?? this.redactedPages,
      controller: controller ?? this.controller,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class PdfViewerParams {
  final String url;
  final bool enableRedaction;
  final bool showAllPages;
  final bool isThumbnail;

  PdfViewerParams({
    required this.url,
    required this.enableRedaction,
    this.showAllPages = false,
    this.isThumbnail = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfViewerParams &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          enableRedaction == other.enableRedaction &&
          showAllPages == other.showAllPages &&
          isThumbnail == other.isThumbnail;

  @override
  int get hashCode =>
      url.hashCode ^ enableRedaction.hashCode ^ showAllPages.hashCode ^ isThumbnail.hashCode;
}

class PdfViewerNotifier extends StateNotifier<PdfViewerState> {
  PdfViewerNotifier() : super(PdfViewerState(isLoading: true));

  Future<void> loadPdf(PdfViewerParams params) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    PdfDocument? document;
    try {
      final Uint8List bytes = await InternetFile.get(params.url);
      document = await PdfDocument.openData(bytes);

      final bool shouldRedact = params.enableRedaction;

      if (shouldRedact) {
        final List<Uint8List> pages = [];
        final int limit = params.isThumbnail ? 1 : document.pagesCount;
        
        for (int i = 1; i <= limit; i++) {
          PdfPage? page;
          try {
            page = await document.getPage(i);
            
            double scale = params.isThumbnail ? 1.0 : 1.5;
            int quality = params.isThumbnail ? 70 : 85;

            final pageImage = await page.render(
              width: page.width * scale,
              height: page.height * scale,
              format: PdfPageImageFormat.jpeg,
              quality: quality,
            );
            
            if (pageImage != null) {
              final redacted = await PdfRedactionService.redactImage(
                pageImage.bytes,
                [],
                redactAll: true,
              );
              pages.add(redacted);
            }
          } finally {
            await page?.close();
          }
        }
        
        state = state.copyWith(
          redactedPages: pages,
          isLoading: false,
          totalPages: document.pagesCount,
        );
        await document.close();
      } else {
        // Direct PDF view using controller
        // Note: PdfControllerPinch opens its own document instance from bytes
        final controller = PdfControllerPinch(
          document: PdfDocument.openData(bytes),
        );
        
        state = state.copyWith(
          controller: controller,
          isLoading: false,
          totalPages: document.pagesCount,
        );
        await document.close();
      }
    } catch (e) {
      debugPrint('PdfViewerNotifier Error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
      await document?.close();
    }
  }

  String _parseError(Object e) {
    final String err = e.toString().toLowerCase();
    if (err.contains('socketexception') || err.contains('handshake') || err.contains('http')) {
      return 'Network error: Check your connection.';
    } else if (err.contains('password')) {
      return 'PDF is password protected.';
    } else if (err.contains('invalid') || err.contains('format')) {
      return 'Invalid PDF format.';
    }
    return 'Failed to load PDF.';
  }

  @override
  void dispose() {
    state.controller?.dispose();
    super.dispose();
  }
}

final pdfViewerProvider = StateNotifierProvider.family<PdfViewerNotifier, PdfViewerState, PdfViewerParams>((ref, params) {
  final notifier = PdfViewerNotifier();
  notifier.loadPdf(params);
  return notifier;
});
