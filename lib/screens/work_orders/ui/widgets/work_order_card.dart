import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/work_orders/model/work_orders_model.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:arianth/services/widget/pdf_thumbnail.dart';
import 'package:arianth/services/widget/pdf_full_viewer_screen.dart';
import 'package:get/get.dart';

class WorkOrderCard extends StatefulWidget {
  final WorkOrder workOrder;
  final String? role;
  final String? activeStatus;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onEdit;
  final Future<void> Function() onShare;

  const WorkOrderCard({
    super.key,
    required this.workOrder,
    this.role,
    this.activeStatus,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onEdit,
    required this.onShare,
  });

  @override
  State<WorkOrderCard> createState() => _WorkOrderCardState();
}

class _WorkOrderCardState extends State<WorkOrderCard> {
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final workOrder = widget.workOrder;
    final role = widget.role;
    final activeStatus = widget.activeStatus;
    final isSelected = widget.isSelected;
    final onSelectionChanged = widget.onSelectionChanged;
    final onEdit = widget.onEdit;
    final onShare = widget.onShare;

    final List<String> allImages = [];
    if (workOrder.galleryImages != null && workOrder.galleryImages!.isNotEmpty) {
      allImages.addAll(workOrder.galleryImages!);
    } else if (workOrder.images != null && workOrder.images!.isNotEmpty) {
      allImages.addAll(workOrder.images!);
    } else if (workOrder.productImageUrl != null && workOrder.productImageUrl != 'null') {
      allImages.add(workOrder.productImageUrl!);
    } else if (workOrder.productImage != null && workOrder.productImage != 'null') {
      allImages.add(workOrder.productImage!);
    }
    final imageUrl = allImages.isNotEmpty ? allImages.first : null;
    final String craftsmanCode =
        (workOrder.craftsman?.craftmanCode ??
                workOrder.craftsman?.businessName ??
                workOrder.allocatedCraftsmanBpCode ??
                '')
            .trim();
    return Card(
      color: AppColor.white,
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
          // Left Side: Image PageView
          Stack(
            children: [
              SizedBox(
                width: 100,
                height: 180,
                child: allImages.isNotEmpty
                    ? PageView.builder(
                        itemCount: allImages.length,
                        itemBuilder: (context, index) {
                          final imageUrl = allImages[index];
                          final bool isPdf = imageUrl.toLowerCase().endsWith('.pdf');

                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                            ),
                            child: isPdf
                                ? GestureDetector(
                                    onTap: () => Get.to(
                                      () => PdfFullViewerScreen(
                                        url: imageUrl,
                                        title: workOrder.workOrderNumber,
                                        enableRedaction: true,
                                        backgroundColor: AppColor.background,
                                        appBarColor: AppColor.background,
                                        textColor: AppColor.textPrimary,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(12),
                                      ),
                                      child: PdfThumbnail(
                                        url: imageUrl,
                                        fit: BoxFit.contain,
                                        enableRedaction: true,
                                      ),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: () => FullScreenImageViewer.show(
                                      context,
                                      imageUrl,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.horizontal(
                                        left: Radius.circular(12),
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
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
                                        errorBuilder:
                                            (context, error, stackTrace) => Icon(
                                              Icons.image_not_supported,
                                              color: AppColor.silver.withOpacity(
                                                0.2,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image,
                        color: AppColor.textHint,
                        size: 30,
                      ),
              ),
              if (allImages.length > 1)
                Positioned(
                  bottom: 5,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Swipe",
                          style: TextStyle(color: Colors.white, fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Right Side: Multi-line details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onSelectionChanged != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
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
                                side: const BorderSide(
                                  color: AppColor.black,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: workOrder.workOrderNumber ?? '-',
                                  ),
                                );
                                Toaster.showSuccess(
                                  "Order Number copied to clipboard",
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'ORDER NO: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    TextSpan(
                                      text: workOrder.workOrderNumber ?? '',
                                      style: const TextStyle(
                                        color: AppColor.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            if (role?.toLowerCase() != "craftsman" &&
                                workOrder.referenceNo != null)
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'REF. NO: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                    TextSpan(
                                      text: workOrder.referenceNo ?? '',
                                      style: const TextStyle(
                                        color: AppColor.textSecondary,
                                        fontSize: 12,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (role?.toLowerCase() != "craftsman" &&
                      ![
                        'buyer',
                        'key_user',
                        'user',
                      ].contains(role?.toLowerCase())) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        final clientInfo =
                            '${workOrder.bpCode ?? ''}-${workOrder.customerName ?? ''}';
                        Clipboard.setData(ClipboardData(text: clientInfo));
                        Toaster.showSuccess(
                          "Client Info copied to clipboard",
                        );
                      },
                      child: Text(
                        '${workOrder.bpCode ?? ''}-${workOrder.customerName ?? ''}',
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if ((role?.toLowerCase() == 'admin' ||
                            role?.toLowerCase() == 'super_admin') &&
                        craftsmanCode.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        craftsmanCode,
                        style: const TextStyle(
                          color: Colors.redAccent,
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
                      buildWorkOrderText(),
                      style: const TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (workOrder.createdAt != null &&
                      workOrder.createdAt.toString() != 'null' &&
                      workOrder.createdAt.toString().isNotEmpty)
                    Text(
                      'Order Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(workOrder.createdAt.toString()))}',
                      style: const TextStyle(
                        color: AppColor.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (activeStatus == "Completed" && workOrder.status != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${workOrder.status}',
                      style: TextStyle(
                          color: workOrder.status?.toLowerCase() == 'completed'
                              ? AppColor.success
                              : AppColor.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  // Check if the date exists and is not 'null' string
                  if (workOrder.craftsmanDueDate != null &&
                      workOrder.craftsmanDueDate.toString() != 'null' &&
                      workOrder.craftsmanDueDate.toString().isNotEmpty &&
                      [
                        "craftsman",
                        'super_admin',
                      ].contains(role?.toLowerCase()))
                    Text(
                      'Due Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(workOrder.craftsmanDueDate.toString()))}',
                      style: const TextStyle(
                        color: AppColor.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (workOrder.dueDate != null &&
                      workOrder.dueDate.toString() != 'null' &&
                      workOrder.dueDate.toString().isNotEmpty &&
                      [
                        'buyer',
                        'key_user',
                        'user',
                      ].contains(role?.toLowerCase()))
                    Text(
                      'Due Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.parse(workOrder.dueDate.toString()))}',
                      style: const TextStyle(
                        color: AppColor.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (role?.toLowerCase() != "craftsman")
                        if ([
                              'buyer',
                              'key_user',
                              'user',
                            ].contains(role?.toLowerCase())
                            ? activeStatus == 'New'
                            : true)
                          SizedBox(
                            height: 28,
                            child: FormFeildCommonButton(
                              text: activeStatus == 'Completed'
                                  ? "Copy"
                                  : "Edit",
                              onPressed: onEdit,
                            ),
                          ),
                      if (role?.toLowerCase() != "craftsman")
                        if ([
                              'buyer',
                              'key_user',
                              'user',
                            ].contains(role?.toLowerCase())
                            ? activeStatus == 'New'
                            : true)
                          const SizedBox(width: 10),
                      if ((role?.toLowerCase() != "craftsman" ||
                              (activeStatus != 'Allocated' &&
                                  activeStatus != 'All')) && (activeStatus != "New" && activeStatus != "All" || role?.toLowerCase() == 'super_admin'))
                            SizedBox(
                              height: 28,
                              child: FormFeildCommonButton(
                                text: "Share",
                                isLoading: _isSharing,
                                onPressed: _isSharing
                                    ? null
                                    : () async {
                                        setState(() => _isSharing = true);
                                        try {
                                          await onShare();
                                        } finally {
                                          if (mounted)
                                            setState(() => _isSharing = false);
                                        }
                                      },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }

  String buildWorkOrderText() {
    final workOrder = widget.workOrder;
    final role = widget.role;
    List<String> parts = [];

    if (workOrder.quantity != null &&
        workOrder.quantity.toString().isNotEmpty) {
      parts.add('Quantity: ${workOrder.quantity}');
    }

    if (workOrder.weightFrom != null &&
        workOrder.weightFrom.toString().isNotEmpty) {
      parts.add('Weight: ${workOrder.weightFrom}');
    }
    if (workOrder.type != null &&
        workOrder.type.toString().isNotEmpty) {
      parts.add('type: ${workOrder.type}');
    }

    if (workOrder.productCategory != null &&
        workOrder.productCategory!.isNotEmpty) {
      parts.add('Category: ${workOrder.productCategory}');
    }
    if (workOrder.size != null &&
        workOrder.size.toString().isNotEmpty) {
      parts.add('size: ${workOrder.size}');
    }
    final userRole = role?.toLowerCase();
    if (!['buyer', 'key_user', 'user'].contains(userRole)) {
      if (workOrder.narrationCraftsman != null &&
          workOrder.narrationCraftsman!.isNotEmpty) {
        parts.add('Item Narration: ${workOrder.narrationCraftsman}');
      }
    }
    if (['buyer', 'key_user', 'user'].contains(userRole)) {
      if (workOrder.narrationAdmin != null &&
          workOrder.narrationAdmin!.isNotEmpty) {
        parts.add('Item Narration: ${workOrder.narrationAdmin}');
      }
    }

    return parts.join(' | ');
  }
}
