import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/common_notifiers/pdf_viewer_notifier.dart';

class PdfThumbnail extends ConsumerWidget {
  final String url;
  final BoxFit fit;
  final bool showAllPages;
  final bool enableRedaction;

  const PdfThumbnail({
    super.key,
    required this.url,
    this.fit = BoxFit.contain,
    this.showAllPages = false,
    this.enableRedaction = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = PdfViewerParams(
      url: url,
      enableRedaction: enableRedaction,
      showAllPages: showAllPages,
      isThumbnail: !showAllPages, // Single page is thumbnail
    );

    final state = ref.watch(pdfViewerProvider(params));

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
        ),
      );
    }

    if (state.errorMessage != null) {
      return const Center(
        child: Icon(
          Icons.picture_as_pdf,
          color: Colors.red,
          size: 40,
        ),
      );
    }

    if (showAllPages) {
      if (state.redactedPages.isNotEmpty) {
        return ListView.separated(
          itemCount: state.redactedPages.length,
          separatorBuilder: (context, index) => const Divider(height: 20),
          itemBuilder: (context, index) => Image.memory(
            state.redactedPages[index],
            fit: fit,
          ),
        );
      } else if (state.controller != null) {
        return PdfViewPinch(
          controller: state.controller!,
        );
      }
    }

    // Single page (Thumbnail)
    if (state.redactedPages.isNotEmpty) {
      return Image.memory(
        state.redactedPages.first,
        fit: fit,
      );
    } else if (state.controller != null) {
       // Controller view for single page (rare for thumbnail but supported)
       return PdfViewPinch(controller: state.controller!);
    }

    return const Center(
      child: Icon(
        Icons.picture_as_pdf,
        color: Colors.red,
        size: 40,
      ),
    );
  }
}
