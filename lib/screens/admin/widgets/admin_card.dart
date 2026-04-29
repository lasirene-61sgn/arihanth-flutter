import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/admin/model/admin_model.dart';
import 'package:flutter/material.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';

class AdminCard extends StatelessWidget {
  final Admin admin;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const AdminCard({
    super.key,
    required this.admin,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onTap,
    required this.onEdit,
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
              height: 180,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColor.background,
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                ),
                child: admin.profilePicture != null && admin.profilePicture!.isNotEmpty
                    ? GestureDetector(
                        onTap: () => FullScreenImageViewer.show(context, admin.profilePicture!),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                          child: Image.network(
                            admin.profilePicture!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: AppColor.textHint,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const Center(child: Icon(Icons.admin_panel_settings, color: AppColor.textHint, size: 40)),
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
                        if (onSelectionChanged != null)
                          SizedBox(
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                admin.fullName ?? '-',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'User Code: ${admin.userCode ?? '-'}',
                                style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                              ),
                              Text(
                                'Role: ${admin.role ?? 'Admin'}',
                                style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_note, color: AppColor.primary, size: 24),
                          onPressed: onEdit,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Specs Block
                    Container(
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
                            'Mobile: ${admin.mobileNo ?? '-'}',
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                          ),
                          Text(
                            'Email: ${admin.emailId ?? '-'}',
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Location: ${admin.city ?? '-'}${admin.state != null ? ", ${admin.state}" : ""}',
                            style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
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
