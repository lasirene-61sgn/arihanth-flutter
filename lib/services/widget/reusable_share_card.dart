import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdfx/pdfx.dart';
import 'package:internet_file/internet_file.dart';
import 'package:arianth/services/pdf/pdf_redaction_service.dart';
import 'dart:async';
import 'package:arianth/services/widget/universal_share_bottom_sheet.dart';

Future<Size?> _resolveImageSize(ImageProvider provider) {
  final completer = Completer<Size?>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool _) {
      completer.complete(
        Size(info.image.width.toDouble(), info.image.height.toDouble()),
      );
      stream.removeListener(listener);
    },
    onError: (dynamic exception, StackTrace? stackTrace) {
      completer.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future.timeout(
    const Duration(seconds: 4),
    onTimeout: () {
      stream.removeListener(listener);
      return null;
    },
  );
}

class ShareCardItem {
  final String? imageUrl;
  final String? title;
  final String? bpCode;
  final String? productCode;
  final String? category;
  final String? subtitle;
  final String? quantity;
  final String? weight;
  final String? size;
  final String? type;
  final String? narration;
  final String? orderNote;
  final String? refNo;
  final String? dueDate;
  final String? orderDate;
  final String? gramsDetail;
  final String? stone;
  final String? enamel;
  final String? hallmark;
  final String? rodium;
  final String? hook;
  final String? openClose;
  final String? workOrderNumber;
  final String? stockOrderNumber;
  final String? screwName;
  final bool isPdf;
  final bool isLocked;
  final bool showWatermark;
  final bool enableRedaction;
  final Uint8List? imageBytes;
  final double? imageWidth;
  final double? imageHeight;

  const ShareCardItem({
    this.imageUrl,
    this.title,
    this.bpCode,
    this.productCode,
    this.category,
    this.subtitle,
    this.quantity,
    this.type,
    this.weight,
    this.size,
    this.narration,
    this.orderNote,
    this.refNo,
    this.dueDate,
    this.orderDate,
    this.gramsDetail,
    this.stone,
    this.enamel,
    this.hallmark,
    this.rodium,
    this.hook,
    this.openClose,
    this.workOrderNumber,
    this.stockOrderNumber,
    this.screwName,
    this.isPdf = false,
    this.isLocked = false,
    this.showWatermark = false,
    this.enableRedaction = true,
    this.imageBytes,
    this.imageWidth,
    this.imageHeight,
  });
}

extension ShareCardItemExtension on ShareCardItem {
  ShareCardItem copyWith({
    Uint8List? imageBytes,
    double? imageWidth,
    double? imageHeight,
  }) {
    return ShareCardItem(
      imageUrl: imageUrl,
      title: title,
      bpCode: bpCode,
      productCode: productCode,
      category: category,
      subtitle: subtitle,
      quantity: quantity,
      type: type,
      weight: weight,
      size: size,
      narration: narration,
      orderNote: orderNote,
      refNo: refNo,
      dueDate: dueDate,
      orderDate: orderDate,
      gramsDetail: gramsDetail,
      stone: stone,
      enamel: enamel,
      hallmark: hallmark,
      rodium: rodium,
      hook: hook,
      openClose: openClose,
      workOrderNumber: workOrderNumber,
      stockOrderNumber: stockOrderNumber,
      screwName: screwName,
      isPdf: isPdf,
      isLocked: isLocked,
      showWatermark: showWatermark,
      enableRedaction: enableRedaction,
      imageBytes: imageBytes ?? this.imageBytes,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Call [ShareCardService.share] from anywhere to:
///   1. Render a 300×500 white share card off-screen
///   2. Capture it as a high-res PNG
///   3. Open the native share sheet (user picks WhatsApp, mail, etc.)
/// ─────────────────────────────────────────────────────────────────────────────
class ShareCardService {
  ShareCardService._();

  /// Default share entry point for all screens.
  /// Shows the bottom sheet with:
  ///   - Share via WhatsApp
  ///   - Share to App Chat
  static Future<void> share(
    BuildContext context,
    ShareCardItem item, {
    String title = 'Share Item',
  }) async {
    await UniversalShareOptionsBottomSheet.show(
      context: context,
      shareItems: [item],
      title: title,
    );
  }

  /// Default bulk share entry point for all screens.
  /// Shows the bottom sheet with:
  ///   - Share via WhatsApp
  ///   - Share to App Chat
  static Future<void> shareMultiple(
    BuildContext context,
    List<ShareCardItem> items, {
    String title = 'Share Items',
  }) async {
    await UniversalShareOptionsBottomSheet.show(
      context: context,
      shareItems: items,
      title: title,
    );
  }

  /// Direct WhatsApp / system share sheet for a single item (used when user selects WhatsApp).
  static Future<void> shareDirect(
    BuildContext context,
    ShareCardItem item,
  ) async {
    OverlayEntry? entry;
    try {
      // 0. Pre-render PDF if needed
      if (item.isPdf && item.imageUrl != null && item.imageBytes == null) {
        final pdfBytes = await _renderPdfToImage(item.imageUrl!, item.enableRedaction);
        if (pdfBytes != null) {
          item = item.copyWith(imageBytes: pdfBytes);
        }
      }

      // 1. Pre-cache and resolve real native image dimensions
      if (item.imageBytes != null) {
        final size = await _resolveImageSize(MemoryImage(item.imageBytes!));
        if (size != null && size.width > 0 && size.height > 0) {
          item = item.copyWith(imageWidth: size.width, imageHeight: size.height);
        }
      } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty && !item.isPdf) {
        final netProvider = NetworkImage(item.imageUrl!);
        await precacheImage(netProvider, context);
        final size = await _resolveImageSize(netProvider);
        if (size != null && size.width > 0 && size.height > 0) {
          item = item.copyWith(imageWidth: size.width, imageHeight: size.height);
        }
      }

      // 2. Insert off-screen share card widget
      final shareKey = GlobalKey();
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -9999,
          top: -9999,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: shareKey,
              child: _ShareCardWidget(item: item),
            ),
          ),
        ),
      );
      final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);
      overlay.insert(entry);

      // 3. Render the widget to an image
      await Future.delayed(const Duration(milliseconds: 2000));

      // 4. Capture PNG at 1:1 native pixel quality
      final boundary = shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image img = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData =
          await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // 5. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(byteData.buffer.asUint8List());

      // 6. Open system share sheet
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'image/png')],
          subject: item.title ?? 'Share',
        ),
      );
    } catch (e) {
      debugPrint('ShareCardService error: $e');
    } finally {
      entry?.remove();
    }
  }

  /// Direct WhatsApp / system share sheet for multiple items.
  static Future<void> shareMultipleDirect(
    BuildContext context,
    List<ShareCardItem> items,
  ) async {
    if (items.isEmpty) return;
    OverlayEntry? entry;
    try {
      // 0. Pre-render PDFs & resolve native image sizes
      List<ShareCardItem> updatedItems = [];
      for (var item in items) {
        if (item.isPdf && item.imageUrl != null && item.imageBytes == null) {
          final pdfBytes = await _renderPdfToImage(item.imageUrl!, item.enableRedaction);
          if (pdfBytes != null) {
            item = item.copyWith(imageBytes: pdfBytes);
          }
        }

        if (item.imageBytes != null) {
          final size = await _resolveImageSize(MemoryImage(item.imageBytes!));
          if (size != null && size.width > 0 && size.height > 0) {
            item = item.copyWith(imageWidth: size.width, imageHeight: size.height);
          }
        } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty && !item.isPdf) {
          try {
            final netProvider = NetworkImage(item.imageUrl!);
            // Resolve image size directly without waiting long on precache
            final size = await _resolveImageSize(netProvider);
            if (size != null && size.width > 0 && size.height > 0) {
              item = item.copyWith(imageWidth: size.width, imageHeight: size.height);
            }
          } catch (e) {
            debugPrint('Failed to resolve image size: ${item.imageUrl}');
          }
        }
        updatedItems.add(item);
      }
      items = updatedItems;

      // 1. Insert off-screen share card widget
      final List<GlobalKey> keys = List.generate(items.length, (i) => GlobalKey());
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -9999,
          top: -9999,
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(items.length, (i) {
                  return RepaintBoundary(
                    key: keys[i],
                    child: _ShareCardWidget(item: items[i]),
                  );
                }),
              ),
            ),
          ),
        ),
      );
      final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);
      overlay.insert(entry);

      // 2. Render the widget to an image
      await Future.delayed(const Duration(milliseconds: 2000));

      final tempDir = await getTemporaryDirectory();
      List<XFile> xFiles = [];

      for (int i = 0; i < items.length; i++) {
        final boundary = keys[i].currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;

        try {
          final ui.Image img = await boundary.toImage(pixelRatio: 1.0);
          final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final filePath = '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}_$i.png';
            await File(filePath).writeAsBytes(byteData.buffer.asUint8List());
            xFiles.add(XFile(filePath, mimeType: 'image/png'));
          }
        } catch (e) {
          debugPrint('Error capturing image $i: $e');
        }
      }

      // 3. Open system share sheet
      if (xFiles.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            files: xFiles,
            subject: items.first.title ?? 'Share',
          ),
        );
      }
    } catch (e) {
      debugPrint('ShareCardService _shareMultiple error: $e');
    } finally {
      entry?.remove();
    }
  }

  static Future<Uint8List?> _renderPdfToImage(String url, bool enableRedaction) async {
    try {
      final Uint8List bytes = await InternetFile.get(url);
      final document = await PdfDocument.openData(bytes);
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );

      Uint8List? finalBytes = pageImage?.bytes;

      if (finalBytes != null && enableRedaction) {
        finalBytes = await PdfRedactionService.redactImage(
          finalBytes,
          [],
          redactAll: true,
        );
      }

      await page.close();
      await document.close();
      return finalBytes;
    } catch (e) {
      debugPrint('Error rendering PDF to image: $e');
      return null;
    }
  }

  static Future<List<XFile>> captureCardFiles(
    BuildContext context,
    List<ShareCardItem> items, {
    void Function(int completed, int total)? onProgress,
  }) async {
    if (items.isEmpty) return [];
    OverlayEntry? entry;
    try {
      // 0. Pre-render PDFs and detect real original image dimensions
      List<ShareCardItem> updatedItems = [];
      for (var item in items) {
        if (item.isPdf && item.imageUrl != null && item.imageBytes == null) {
          final pdfBytes = await _renderPdfToImage(item.imageUrl!, item.enableRedaction);
          if (pdfBytes != null) {
            item = item.copyWith(imageBytes: pdfBytes);
          }
        }

        if (item.imageBytes != null) {
          final size = await _resolveImageSize(MemoryImage(item.imageBytes!));
          if (size != null && size.width > 0 && size.height > 0) {
            item = item.copyWith(imageWidth: size.width, imageHeight: size.height);
          }
        } else if (item.imageUrl != null && item.imageUrl!.isNotEmpty && !item.isPdf) {
          try {
            final netProvider = NetworkImage(item.imageUrl!);
            // Resolve image size directly without waiting long on precache
            final size = await _resolveImageSize(netProvider);
            if (size != null && size.width > 0 && size.height > 0) {
              item = item.copyWith(imageWidth: size.width, imageHeight: size.height);
            }
          } catch (e) {
            debugPrint('Failed to resolve image size: ${item.imageUrl}');
          }
        }
        updatedItems.add(item);
      }
      items = updatedItems;

      // 1. Insert off-screen share card widget
      final List<GlobalKey> keys = List.generate(items.length, (i) => GlobalKey());
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -9999,
          top: -9999,
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(items.length, (i) {
                  return RepaintBoundary(
                    key: keys[i],
                    child: _ShareCardWidget(item: items[i]),
                  );
                }),
              ),
            ),
          ),
        ),
      );
      final overlay = Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.of(context);
      overlay.insert(entry);

      // 2. Render the widget to an image
      await Future.delayed(const Duration(milliseconds: 2000));

      final tempDir = await getTemporaryDirectory();
      List<XFile> xFiles = [];

      for (int i = 0; i < items.length; i++) {
        final boundary = keys[i].currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          try {
            final ui.Image img = await boundary.toImage(pixelRatio: 1.0);
            final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
            if (byteData != null) {
              final filePath = '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}_$i.png';
              await File(filePath).writeAsBytes(byteData.buffer.asUint8List());
              xFiles.add(XFile(filePath, mimeType: 'image/png'));
            }
          } catch (e) {
            debugPrint('Error capturing card file $i: $e');
          }
        }
        onProgress?.call(i + 1, items.length);
      }
      return xFiles;
    } catch (e) {
      debugPrint('ShareCardService captureCardFiles error: $e');
      return [];
    } finally {
      entry?.remove();
    }
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Dynamic Share Card Widget: Renders at 1:1 real image dimensions,
/// preserving 100% original image quality without downsizing, with extra
/// space added solely for the text details below.
/// ─────────────────────────────────────────────────────────────────────────────
class _ShareCardWidget extends StatelessWidget {
  final ShareCardItem item;
  const _ShareCardWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    // Use actual image dimensions if available, falling back to a crisp default (800)
    final double cardWidth = (item.imageWidth != null && item.imageWidth! > 0)
        ? item.imageWidth!
        : 800.0;
    final double? naturalHeight = (item.imageHeight != null && item.imageHeight! > 0)
        ? item.imageHeight!
        : null;

    // Scale font size and padding proportionately so text looks crisp and balanced at any resolution
    final double scaleRatio = (cardWidth / 400.0).clamp(1.0, 3.5);
    final double fontSize = (30.0 * scaleRatio).clamp(28.0, 76.0);
    final double horizontalPadding = (16.0 * scaleRatio).clamp(16.0, 48.0);
    final double verticalPadding = (18.0 * scaleRatio).clamp(18.0, 50.0);
    final double logoSize = (80.0 * scaleRatio).clamp(70.0, 160.0);

    // Build the pipe-separated details string
    final details = <String>[];
    if (item.workOrderNumber != null && item.workOrderNumber!.isNotEmpty) details.add('Work Order No: ${item.workOrderNumber}');
    if (item.stockOrderNumber != null && item.stockOrderNumber!.isNotEmpty) details.add('Stock Order No: ${item.stockOrderNumber}');
    if (item.productCode != null && item.productCode!.isNotEmpty) details.add('PO#: ${item.productCode}');
    if (item.refNo != null && item.refNo!.isNotEmpty) details.add('Ref No: ${item.refNo}');
    if (item.category != null && item.category!.isNotEmpty) details.add('Category Name: ${item.category}');
    if (item.quantity != null && item.quantity!.isNotEmpty) details.add('Quantity: ${item.quantity}');
    if (item.type != null && item.type!.isNotEmpty) details.add('Type: ${item.type}');
    if (item.weight != null && item.weight!.isNotEmpty) details.add('Weight: ${item.weight}');
    if (item.size != null && item.size!.isNotEmpty) details.add('Size: ${item.size}');
    if (item.bpCode != null && item.bpCode!.isNotEmpty) details.add('BP Code: ${item.bpCode}');
    if (item.dueDate != null && item.dueDate!.isNotEmpty) details.add('Due: ${item.dueDate}');
    if (item.orderDate != null && item.orderDate!.isNotEmpty) details.add('Order Date: ${item.orderDate}');
    if (item.screwName != null && item.screwName!.isNotEmpty) details.add('Screw: ${item.screwName}');
    if (item.gramsDetail != null && item.gramsDetail!.isNotEmpty) details.add('Grams Detail:\n${item.gramsDetail}');
    if (item.narration != null && item.narration!.isNotEmpty) details.add('Item Note: ${item.narration}');
    if (item.orderNote != null && item.orderNote!.isNotEmpty) details.add('Order Note: ${item.orderNote}');
    // Show these fields only if the value is "yes"
    if (item.stone?.toLowerCase() == 'yes') details.add('Stone: Yes');
    if (item.enamel?.toLowerCase() == 'yes') details.add('Enamel: Yes');
    if (item.hallmark?.toLowerCase() == 'yes') details.add('Hallmark: Yes');
    if (item.rodium?.toLowerCase() == 'yes') details.add('Rodium: Yes');
    if (item.hook?.toLowerCase() == 'yes') details.add('Hook: Yes');
    if (item.openClose != null && item.openClose!.isNotEmpty && item.openClose?.toLowerCase() != 'no' && item.openClose?.toLowerCase() != 'null') details.add('Open/Close: ${item.openClose}');

    final detailsString = details.join(' | ');

    return SizedBox(
      width: cardWidth,
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Section (Real 1:1 size) ─────────────────────────────
            if (item.imageBytes != null || hasImage)
              item.isPdf
                  ? (item.imageBytes != null
                      ? Image.memory(
                          item.imageBytes!,
                          width: cardWidth,
                          height: naturalHeight,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        )
                      : _pdfPlaceholder())
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        ImageFiltered(
                          imageFilter: item.isLocked
                              ? ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0)
                              : ui.ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                          child: item.imageBytes != null
                              ? Image.memory(
                                  item.imageBytes!,
                                  width: cardWidth,
                                  height: naturalHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                )
                              : Image.network(
                                  item.imageUrl!,
                                  width: cardWidth,
                                  height: naturalHeight,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                ),
                        ),
                        if (item.showWatermark)
                          Image.asset(
                            'assets/image/tara_logo_color.jpeg',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                          ),
                      ],
                    ),
            if (item.imageBytes == null && !hasImage) _placeholder(),

            // ── Extra Details Section Below Image ─────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Text(
                detailsString,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 10 * scaleRatio),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey.shade100,
    child: const Center(
      child: Icon(Icons.image_outlined, size: 60, color: Colors.grey),
    ),
  );

  Widget _pdfPlaceholder() => PdfThumbnail(
    url: item.imageUrl!,
    fit: BoxFit.contain,
    enableRedaction: item.enableRedaction,
  );

  Widget _smallNote(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _codeBadge({
    required String label,
    required String value,
    required Color bg,
    required Color border,
    required Color text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
            fontSize: 10, color: text, fontWeight: FontWeight.bold),
      ),
    );
  }
}
