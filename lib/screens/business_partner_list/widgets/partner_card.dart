import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/business_partner_list/model/business_partner_list_model.dart';
import 'package:flutter/material.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';

class PartnerCard extends StatelessWidget {
  final BusinessPartner partner;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const PartnerCard({
    super.key,
    required this.partner,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                    child: partner.imageUrl != null && partner.imageUrl!.isNotEmpty
                        ? GestureDetector(
                            onTap: () => FullScreenImageViewer.show(
                              context,
                              partner.imageUrl!,
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                              child: Image.network(
                                partner.imageUrl!,
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
                                        Icons.business,
                                        color: AppColor.textHint,
                                        size: 40,
                                      ),
                                    ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.business,
                              color: AppColor.textHint,
                              size: 40,
                            ),
                          ),
                  ),
                  if (onEdit != null)
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
                        width: 36,
                        height: 36,
                        child: Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: onSelectionChanged,
                            activeColor: AppColor.primary,
                               checkColor: AppColor.textWhite,
                            side: const BorderSide(color: AppColor.black, width: 1.5),
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
                                  partner.businessName ?? partner.name ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.textPrimary,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'BP Code: ${partner.bpCode?.split('-').first.trim() ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                // Text(
                                //   'Role: ${partner.role ?? '-'}',
                                //   style: const TextStyle(
                                //     color: AppColor.primary,
                                //     fontSize: 11,
                                //     fontWeight: FontWeight.bold,
                                //   ),
                                // ),
                                Text(
                                  'Customer: ${partner.name ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Mobile: ${partner.mobile ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  'Email: ${partner.businessEmail ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColor.textSecondary,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
