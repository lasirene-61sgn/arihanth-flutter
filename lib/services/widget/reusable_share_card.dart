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
  final String? screwName;
  final bool isPdf;
  final bool isLocked;
  final bool showWatermark;
  final bool enableRedaction;
  final Uint8List? imageBytes;

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
    this.screwName,
    this.isPdf = false,
    this.isLocked = false,
    this.showWatermark = false,
    this.enableRedaction = true,
    this.imageBytes,
  });
}

extension ShareCardItemExtension on ShareCardItem {
  ShareCardItem copyWith({Uint8List? imageBytes}) {
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
      screwName: screwName,
      isPdf: isPdf,
      isLocked: isLocked,
      showWatermark: showWatermark,
      enableRedaction: enableRedaction,
      imageBytes: imageBytes ?? this.imageBytes,
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

  static Future<void> share(
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

      // 1. Pre-cache image (skip if PDF or if we have imageBytes)
      if (item.imageUrl != null && item.imageUrl!.isNotEmpty && !item.isPdf && item.imageBytes == null) {
        await precacheImage(NetworkImage(item.imageUrl!), context);
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
      Overlay.of(context).insert(entry);

      // 3. Render the widget to an image
      // Increased delay to allow PDFs to load and redact
      await Future.delayed(const Duration(milliseconds: 2000));

      // 4. Capture PNG (2× pixel ratio → 600×1000 output)
      final boundary = shareKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image img = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // 5. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(filePath).writeAsBytes(byteData.buffer.asUint8List());

      // 6. Build share text
      final parts = <String>[];
      if (item.title?.isNotEmpty == true) parts.add('📦 *${item.title}*');
      if (item.bpCode?.isNotEmpty == true) parts.add('BP Code: ${item.bpCode}');
      if (item.productCode?.isNotEmpty == true) parts.add('PO#: ${item.productCode}');
      if (item.category?.isNotEmpty == true) parts.add('Category: ${item.category}');
      if (item.refNo?.isNotEmpty == true) parts.add('Ref No: ${item.refNo}');
      if (item.quantity?.isNotEmpty == true) parts.add('Qty: ${item.quantity}');
      if (item.type?.isNotEmpty == true) parts.add('Type: ${item.type}');
      if (item.weight?.isNotEmpty == true) parts.add('Weight: ${item.weight}');
      if (item.size?.isNotEmpty == true) parts.add('Size: ${item.size}');
      if (item.dueDate?.isNotEmpty == true) parts.add('Due: ${item.dueDate}');
      if (item.orderDate?.isNotEmpty == true) parts.add('Order Date/Time: ${item.orderDate}');
      if (item.narration?.isNotEmpty == true) parts.add('Item Note: ${item.narration}');
      if (item.orderNote?.isNotEmpty == true) parts.add('Order Note: ${item.orderNote}');
      if (item.screwName?.isNotEmpty == true) parts.add('Screw: ${item.screwName}');
      if (item.subtitle?.isNotEmpty == true) parts.add(item.subtitle!);

      // 7. Open system share sheet (user can pick WhatsApp, email, etc.)
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'image/png')],
          // text: parts.join('\n'),
          subject: item.title ?? 'Share',
        ),
      );
    } catch (e) {
      debugPrint('ShareCardService error: $e');
    } finally {
      entry?.remove();
    }
  }

  static Future<void> shareMultiple(
    BuildContext context,
    List<ShareCardItem> items,
  ) async {
    if (items.isEmpty) return;
    OverlayEntry? entry;
    try {
      // 0. Pre-render PDFs
      List<ShareCardItem> updatedItems = [];
      for (var item in items) {
        if (item.isPdf && item.imageUrl != null && item.imageBytes == null) {
          final pdfBytes = await _renderPdfToImage(item.imageUrl!, item.enableRedaction);
          if (pdfBytes != null) {
            updatedItems.add(item.copyWith(imageBytes: pdfBytes));
          } else {
            updatedItems.add(item);
          }
        } else {
          updatedItems.add(item);
        }
      }
      items = updatedItems;

      // 1. Pre-cache image
      for (var item in items) {
        if (item.imageUrl != null && item.imageUrl!.isNotEmpty && !item.isPdf && item.imageBytes == null) {
          try {
             await precacheImage(NetworkImage(item.imageUrl!), context);
          } catch (e) {
             debugPrint('Failed to precache image: ${item.imageUrl}');
          }
        }
      }

      // 2. Insert off-screen share card widget
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
      Overlay.of(context).insert(entry);

      // 3. Render the widget to an image
      // Increased delay to allow PDFs to load and redact
      await Future.delayed(const Duration(milliseconds: 2000));

      final tempDir = await getTemporaryDirectory();
      List<XFile> xFiles = [];
      List<String> combinedText = [];

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final boundary = keys[i].currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;

        try {
          final ui.Image img = await boundary.toImage(pixelRatio: 2.0);
          final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final filePath = '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}_$i.png';
            await File(filePath).writeAsBytes(byteData.buffer.asUint8List());
            xFiles.add(XFile(filePath, mimeType: 'image/png'));
          }
        } catch (e) {
          debugPrint('Error capturing image $i: $e');
        }

        final parts = <String>[];
        if (item.title?.isNotEmpty == true) parts.add('📦 *${item.title}*');
        if (item.bpCode?.isNotEmpty == true) parts.add('BP Code: ${item.bpCode}');
        if (item.productCode?.isNotEmpty == true) parts.add('PO#: ${item.productCode}');
        if (item.category?.isNotEmpty == true) parts.add('Category: ${item.category}');
        if (item.workOrderNumber?.isNotEmpty == true) parts.add('WO#: ${item.workOrderNumber}');
        if (item.refNo?.isNotEmpty == true) parts.add('Ref No: ${item.refNo}');
        if (item.quantity?.isNotEmpty == true) parts.add('Qty: ${item.quantity}');
        if (item.type?.isNotEmpty == true) parts.add('Type: ${item.type}');
        if (item.weight?.isNotEmpty == true) parts.add('Weight: ${item.weight}');
        if (item.size?.isNotEmpty == true) parts.add('Size: ${item.size}');
        if (item.dueDate?.isNotEmpty == true) parts.add('Due: ${item.dueDate}');
        if (item.orderDate?.isNotEmpty == true) parts.add('Order Date/Time: ${item.orderDate}');
        if (item.narration?.isNotEmpty == true) parts.add('Item Note: ${item.narration}');
        if (item.orderNote?.isNotEmpty == true) parts.add('Order Note: ${item.orderNote}');
        if (item.screwName?.isNotEmpty == true) parts.add('Screw: ${item.screwName}');
        if (item.subtitle?.isNotEmpty == true) parts.add(item.subtitle!);
        
        combinedText.add(parts.join('\n'));
      }

      // 7. Open system share sheet
      if (xFiles.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            files: xFiles,
            // text: combinedText.join('\n\n---\n\n'),
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
        format: PdfPageImageFormat.jpeg,
        quality: 100,
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
}

/// ─────────────────────────────────────────────────────────────────────────────
/// The actual 300×500 white share card widget (rendered off-screen only).
/// ─────────────────────────────────────────────────────────────────────────────
class _ShareCardWidget extends StatelessWidget {
  final ShareCardItem item;
  const _ShareCardWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    // Build the pipe-separated details string
    final details = <String>[];
    if (item.workOrderNumber != null && item.workOrderNumber!.isNotEmpty) details.add('Work Order No: ${item.workOrderNumber}');
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
      width: 400, // Slightly wider for better text flow
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image Section ──────────────────────────────────────────────
            if (item.imageBytes != null || hasImage)
              item.isPdf
                  ? (item.imageBytes != null
                      ? Image.memory(
                          item.imageBytes!,
                          width: 400,
                          fit: BoxFit.contain,
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
                                  width: 400,
                                  fit: BoxFit.contain,
                                )
                              : Image.network(
                                  item.imageUrl!,
                                  width: 400,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                ),
                        ),
                        if (item.showWatermark)
                          Image.asset(
                            'assets/image/tara_logo_color.jpeg',
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                      ],
                    ),
            if (item.imageBytes == null && !hasImage) _placeholder(),

            // ── Details Section ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                detailsString,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
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
