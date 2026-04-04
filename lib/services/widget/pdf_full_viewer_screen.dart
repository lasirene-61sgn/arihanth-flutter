import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:get/get.dart';
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/common_notifiers/pdf_viewer_notifier.dart';

class PdfFullViewerScreen extends ConsumerWidget {
  final String url;
  final String? title;
  final bool enableRedaction;
  final Color? backgroundColor;
  final Color? appBarColor;
  final Color? textColor;

  const PdfFullViewerScreen({
    super.key,
    required this.url,
    this.title,
    this.enableRedaction = false,
    this.backgroundColor,
    this.appBarColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = PdfViewerParams(url: url, enableRedaction: enableRedaction);
    final state = ref.watch(pdfViewerProvider(params));
    
    final Color bg = backgroundColor ?? Colors.black;
    final Color appBarBg = appBarColor ?? Colors.black;
    final Color textCol = textColor ?? Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        title: Text(
          title ?? 'PDF Viewer',
          style: TextStyle(color: textCol, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: textCol),
          onPressed: () => Get.back(),
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColor.primary,
              ),
            )
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: textCol.withOpacity(0.5), size: 64),
                        const SizedBox(height: 16),
                        Text(
                          state.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textCol.withOpacity(0.8), fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(pdfViewerProvider(params).notifier).loadPdf(params),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : state.redactedPages.isNotEmpty
                  ? ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.redactedPages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => InteractiveViewer(
                        child: Image.memory(
                          state.redactedPages[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : PdfViewPinch(
                      controller: state.controller!,
                    ),
    );
  }
}
