import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

class PdfRedactionService {
  // static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Redacts specific keywords or all text from an image of a PDF page.
  /// [imageBytes] The rendered image of the PDF page.
  /// [sensitiveKeywords] List of strings or patterns to hide.
  /// [redactAll] If true, masks every text block detected, ignoring keywords.
  static Future<Uint8List> redactImage(
    Uint8List imageBytes,
    List<String> sensitiveKeywords, {
    bool redactAll = true, // Default to true as per latest user request "all hide"
  }) async {
    // 🚩 SIMULATOR BYPASS: ML Kit is temporarily disabled for simulator compatibility
    return imageBytes;

    /*
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imageBytes, (ui.Image img) => completer.complete(img));
    final ui.Image originalImage = await completer.future;

    // ML Kit requires a file path or InputImage
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);

    final inputImage = InputImage.fromFilePath(tempFile.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    final List<ui.Rect> redactionRects = [];
    for (TextBlock block in recognizedText.blocks) {
      if (redactAll) {
        // Redact the entire block of text
        redactionRects.add(block.boundingBox);
      } else {
        for (TextLine line in block.lines) {
          final lineText = line.text.toLowerCase();
          for (String keyword in sensitiveKeywords) {
            if (lineText.contains(keyword.toLowerCase())) {
              redactionRects.add(line.boundingBox);
            }
          }
        }
      }
    }

    // Cleanup temp file
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    if (redactionRects.isEmpty) return imageBytes;

    // Draw redaction boxes on a canvas
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    // Draw original image first
    canvas.drawImage(originalImage, ui.Offset.zero, ui.Paint());

    // FIX: Change from BlendMode.clear to a solid White paint
    final ui.Paint redactPaint = ui.Paint()
      ..color = Colors.white
      ..style = ui.PaintingStyle.fill;

    for (ui.Rect rect in redactionRects) {
      // Draw a solid box to hide text instead of "clearing" it
      canvas.drawRect(rect.inflate(2), redactPaint);
    }

    final ui.Picture picture = recorder.endRecording();
    final ui.Image redactedImage = await picture.toImage(
      originalImage.width,
      originalImage.height,
    );

    // Encode as PNG or JPEG
    final ByteData? redactedByteData = await redactedImage.toByteData(format: ui.ImageByteFormat.png);
    
    // Explicitly dispose of images to free native memory
    originalImage.dispose();
    redactedImage.dispose();
    
    return redactedByteData!.buffer.asUint8List();
    // Draw original image first
    // canvas.drawImage(originalImage, ui.Offset.zero, ui.Paint());
    //
    // // Use BlendMode.clear to make the areas "transparent"
    // final ui.Paint clearPaint = ui.Paint()
    //   ..blendMode = ui.BlendMode.clear
    //   ..style = ui.PaintingStyle.fill;
    //
    //
    //
    // for (ui.Rect rect in redactionRects) {
    //   // Add padding for clean removal
    //   canvas.drawRect(rect.inflate(2), clearPaint);
    // }
    //
    // final ui.Picture picture = recorder.endRecording();
    // final ui.Image redactedImage = await picture.toImage(
    //   originalImage.width,
    //   originalImage.height,
    // );
    //
    // // Encode as PNG to preserve transparency
    // final ByteData? redactedByteData = await redactedImage.toByteData(format: ui.ImageByteFormat.png);
    // return redactedByteData!.buffer.asUint8List();
  }

  static void dispose() {
    // _textRecognizer.close();
  }
}
*/
  }
}
