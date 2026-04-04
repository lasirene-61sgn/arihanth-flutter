import 'dart:io';
import 'package:arianth/services/widget/reusable_file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FileViewerUtil {
  /// Reusable Full Screen Viewer
  static void showFullScreenImage(BuildContext context, KycDocument doc, String label) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 5,
            child: _buildImageSource(doc),
          ),
        ),
      ),
    );
  }

  /// Multi-Image Gallery Viewer
  static void showGalleryViewer(BuildContext context, List<KycDocument> documents, {int initialIndex = 0, String label = "Gallery"}) {
    final PageController controller = PageController(initialPage: initialIndex);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 5,
                      child: _buildImageSource(documents[index]),
                    ),
                  );
                },
              ),
            ),
            // Pagination indicator/summary
            if (documents.length > 1) 
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: StreamBuilder<int>(
                  stream: Stream.periodic(const Duration(milliseconds: 100), (_) => controller.hasClients ? controller.page?.round() ?? initialIndex : initialIndex).distinct(),
                  initialData: initialIndex,
                  builder: (context, snapshot) {
                    return Text(
                      "${(snapshot.data ?? 0) + 1} / ${documents.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    );
                  }
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildImageSource(KycDocument doc) {
    // 1. Prioritize Local Files/Bytes (Newly picked)
    if (kIsWeb && doc.bytes != null) {
      return Image.memory(doc.bytes!, fit: BoxFit.contain);
    }
    if (!kIsWeb && doc.file != null) {
      return Image.file(doc.file!, fit: BoxFit.contain);
    }

    // 2. Fallback to Direct Network URL (Stored/Existing)
    if (doc.networkUrl != null && doc.networkUrl!.isNotEmpty) {
      return Image.network(
        doc.networkUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.broken_image, color: Colors.white, size: 100),
      );
    }

    return const Icon(Icons.image_not_supported, color: Colors.white, size: 100);
  }
}