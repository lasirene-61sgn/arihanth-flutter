import 'package:arianth/app_color/app_color.dart';
import 'package:flutter/material.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';

/// A reusable image thumbnail cell for use in [ReusableDataTable] via `cellBuilder`.
/// Shows a branded network image thumbnail; tapping opens a full-screen viewer.
class TableImageCell extends StatelessWidget {
  final String? url;
  final String label;

  const TableImageCell({
    super.key,
    required this.url,
    this.label = 'Image',
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;

    return GestureDetector(
      onTap: hasImage ? () =>
          FullScreenImageViewer.show(context, url!, heroTag: url) : null,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColor.divider),
        ),
        child: hasImage
            ? ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.network(
            url!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColor.primary,
                  ),
                ),
              );
            },
            errorBuilder: (c, e, s) =>
            const Icon(
              Icons.broken_image_outlined,
              size: 20,
              color: AppColor.textHint,
            ),
          ),
        )
            : const Icon(
          Icons.image_not_supported_outlined,
          size: 20,
          color: AppColor.textHint,
        ),
      ),);
  }
}
