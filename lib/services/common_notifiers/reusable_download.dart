import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';


import 'dart:html' if (dart.library.io) 'package:flutter/foundation.dart' as html;


/// ===============================
/// DOWNLOAD IMAGE (ANDROID / WEB)
/// ===============================
Future<void> downloadImage(
    BuildContext context,
    String imageUrl,
    String label,
    ) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch image');
    }

    final Uint8List bytes = response.bodyBytes;

    // ✅ Safe filename
    final safeLabel = label.trim().isEmpty
        ? 'image_${DateTime.now().millisecondsSinceEpoch}'
        : label;

    String extension =
    imageUrl.split('.').last.split('?').first.toLowerCase();
    if (!['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension)) {
      extension = 'jpg';
    }

    final fileName = '${safeLabel.replaceAll(' ', '_')}.$extension';

    // ================= WEB =================
    if (kIsWeb) {
      // final blob = html.Blob([bytes], 'image/$extension');
      // final url = html.Url.createObjectUrlFromBlob(blob);
      //
      // html.AnchorElement(href: url)
      //   ..setAttribute('download', fileName)
      //   ..click();
      //
      // html.Url.revokeObjectUrl(url);
      return;
    }

    // ================= ANDROID =================
    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Shared Image',
    );

  } catch (e) {
    debugPrint('❌ Download error: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to download image')),
    );
  }
}

/// ===============================
/// SHARE IMAGE (ANDROID)
/// ===============================
