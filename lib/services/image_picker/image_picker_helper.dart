import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:arianth/app_color/app_color.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Shows a dialog/bottom sheet to pick from Gallery or Camera.
  /// Returns a list of PlatformFile for compatibility with existing code.
  static Future<List<PlatformFile>> pickImages(BuildContext context, {bool allowMultiple = true}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                   'Select Image Source',
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _item(
                      context,
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      source: ImageSource.gallery,
                    ),
                    _item(
                      context,
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      source: ImageSource.camera,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return [];

    try {
      if (source == ImageSource.camera) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (photo != null) {
          final bytes = await photo.readAsBytes();
          return [
            PlatformFile(
              name: photo.name,
              size: bytes.length,
              bytes: bytes,
              path: kIsWeb ? null : photo.path,
            )
          ];
        }
      } else {
        // Source is Gallery
        if (allowMultiple && !kIsWeb) {
          final List<XFile> images = await _picker.pickMultiImage(
            imageQuality: 85,
          );
          List<PlatformFile> platformFiles = [];
          for (var image in images) {
            final bytes = await image.readAsBytes();
            platformFiles.add(PlatformFile(
              name: image.name,
              size: bytes.length,
              bytes: bytes,
              path: image.path,
            ));
          }
          return platformFiles;
        } else {
          final XFile? image = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
          );
          if (image != null) {
            final bytes = await image.readAsBytes();
            return [
              PlatformFile(
                name: image.name,
                size: bytes.length,
                bytes: bytes,
                path: kIsWeb ? null : image.path,
              )
            ];
          }
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
    return [];
  }

  static Widget _item(BuildContext context, {required IconData icon, required String label, required ImageSource source}) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColor.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColor.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
