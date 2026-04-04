import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/craftsman/model/craftsman_model.dart';
import 'package:flutter/material.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';

class CraftsmanCard extends StatelessWidget {
  final Craftsman craftsman;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDetail;

  const CraftsmanCard({
    super.key,
    required this.craftsman,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onEdit,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDetail,
      child: Card(
        color: AppColor.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColor.primary : AppColor.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        elevation: 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Image
            SizedBox(
              width: 110,
              height: 150,
              child: Stack(
                alignment: AlignmentGeometry.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColor.background,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                    child: craftsman.imageUrl != null && craftsman.imageUrl!.isNotEmpty
                        ? GestureDetector(
                            onTap: () => FullScreenImageViewer.show(
                              context,
                              craftsman.imageUrl!,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                              child: Image.network(
                                craftsman.imageUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColor.primary,
                                              ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                      child: Icon(
                                        Icons.person,
                                        color: AppColor.textHint,
                                        size: 40,
                                      ),
                                    ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              color: AppColor.textHint,
                              size: 40,
                            ),
                          ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Align(
                      alignment: AlignmentGeometry.centerRight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.edit_note,
                          color: AppColor.primary,
                          size: 24,
                        ),
                        onPressed: onEdit,
                      ),
                    ),
                  ),
                  if (onSelectionChanged != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: Transform.scale(
                          scale: 0.9,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: onSelectionChanged,
                            activeColor: AppColor.primary,
                               checkColor: AppColor.textWhite,
                            side: const BorderSide(color: AppColor.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Right Side: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColor.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  craftsman.businessName ?? craftsman.name ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textPrimary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'BP Code: ${craftsman.craftmanCode?.split('-').first.trim() ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Customer: ${craftsman.name ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Mobile: ${craftsman.mobile ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Email: ${craftsman.email ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Text(
                                //   'Location: ${craftsman.city ?? '-'}${craftsman.state != null ? ", ${craftsman.state}" : ""}',
                                //   style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
