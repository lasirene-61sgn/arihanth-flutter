import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import '../../model/repair_model.dart';

class RepairListCard extends StatelessWidget {
  final RepairOrder repair;
  final String? role;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback? onEdit;
  final VoidCallback onShare;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onAllocate;
  final VoidCallback? onComplete;
  final bool isAcceptLoading;
  final bool isApproveLoading;
  final bool isRejectLoading;
  final bool isAllocateLoading;
  final bool isCompleteLoading;

  const RepairListCard({
    super.key,
    required this.repair,
    this.role,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onEdit,
    required this.onShare,
    required this.onTap,
    this.onAccept,
    this.onApprove,
    this.onReject,
    this.onAllocate,
    this.onComplete,
    this.isAcceptLoading = false,
    this.isApproveLoading = false,
    this.isRejectLoading = false,
    this.isAllocateLoading = false,
    this.isCompleteLoading = false,
  });

  Widget _actionBtn({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 28,
      child: FormFeildCommonButton(
        text: text,
        onPressed: isLoading ? null : onPressed,
        backgroundColor: backgroundColor,
        isLoading: isLoading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = repair.imageProofUrl;

    return Card(
      color: AppColor.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColor.primary : AppColor.divider,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Side: Image
              SizedBox(
                width: 90,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? GestureDetector(
                          onTap: () => FullScreenImageViewer.show(context, imageUrl),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                            child: Image.network(
                              imageUrl,
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
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.image_not_supported,
                                color: AppColor.silver.withOpacity(0.2),
                              ),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.handyman, color: AppColor.textHint, size: 30),
                        ),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        const TextSpan(text: 'ID: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary, fontSize: 13)),
                                        TextSpan(text: repair.id.toString(), style: const TextStyle(color: AppColor.textPrimary, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${repair.productName ?? 'Unknown Product'} (${repair.repair ?? 'Repair'})',
                                    style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (role == 'super_admin') ...[
                        const SizedBox(height: 4),
                        Text('${repair.buyer?.bpCode ?? ''}-${repair.buyer?.businessName ?? ''}',
                            style: const TextStyle(color: AppColor.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        if (repair.craftsman != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            repair.craftsman?.craftmanCode ?? '',
                            style: const TextStyle(
                              color: AppColor.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 8),
                      // Specs Block
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColor.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Weight: ${repair.weight ?? ''} | Details: ${repair.repairDetails ?? ''}',
                          style: const TextStyle(color: AppColor.textSecondary, fontSize: 11, fontWeight: FontWeight.w400),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (repair.repairDate != null)
                        Text(
                          'Sample/Repair Date: ${_formatDate(repair.repairDate!)}',
                          style: const TextStyle(
                            color: AppColor.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(repair.status ?? '').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          repair.status ?? 'New',
                          style: TextStyle(
                            color: _getStatusColor(repair.status ?? ''),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (onAccept != null) ...[
                              _actionBtn(
                                text: "Accept",
                                backgroundColor: Colors.green,
                                onPressed: onAccept!,
                                isLoading: isAcceptLoading,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (onApprove != null) ...[
                              _actionBtn(
                                text: "Approve",
                                backgroundColor: Colors.green,
                                onPressed: onApprove!,
                                isLoading: isApproveLoading,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (onComplete != null) ...[
                              _actionBtn(
                                text: "Complete",
                                backgroundColor: Colors.green,
                                onPressed: onComplete!,
                                isLoading: isCompleteLoading,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (onReject != null) ...[
                              _actionBtn(
                                text: "Reject",
                                backgroundColor: AppColor.error,
                                onPressed: onReject!,
                                isLoading: isRejectLoading,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (onAllocate != null) ...[
                              _actionBtn(
                                text: "Allocate",
                                backgroundColor: AppColor.primary,
                                onPressed: onAllocate!,
                                isLoading: isAllocateLoading,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (onEdit != null) ...[
                              _actionBtn(
                                text: "Edit",
                                backgroundColor: AppColor.primary,
                                onPressed: onEdit!,
                              ),
                              const SizedBox(width: 6),
                            ],
                            _actionBtn(
                              text: "Share",
                              backgroundColor: AppColor.primary,
                              onPressed: onShare,
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
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'allocated':
        return AppColor.primary;
      case 'completed':
        return AppColor.success;
      case 'rejected':
      case 'rejected_by_admin':
        return AppColor.error;
      default:
        return AppColor.textSecondary;
    }
  }

  String _formatDate(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }
}
