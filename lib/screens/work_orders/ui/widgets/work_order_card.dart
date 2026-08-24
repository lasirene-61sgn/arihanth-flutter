import 'dart:async';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arianth/services/common_notifiers/pdf_viewer_notifier.dart';

class WorkOrderCard extends ConsumerStatefulWidget {
  final WorkOrder workOrder;
  final String? role;
  final String? activeStatus;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final Future<void> Function() onShare;

  const WorkOrderCard({
    super.key,
    required this.workOrder,
    this.role,
    this.activeStatus,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onView,
    required this.onEdit,
    required this.onShare,
  });

  @override
  ConsumerState<WorkOrderCard> createState() => _WorkOrderCardState();
}

class _WorkOrderCardState extends ConsumerState<WorkOrderCard> {
  bool _isSharing = false;
  bool _isImageSharing = false;
  late PageController _imageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  int _latestItemCount = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      if (_latestItemCount > 1) {
        if (_currentPage < _latestItemCount - 1) {
          _imageController.animateToPage(
            _currentPage + 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _imageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  void _nextPage(int imageCount) {
    if (_currentPage < imageCount - 1) {
      _imageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _imageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workOrder = widget.workOrder;
    final role = widget.role;
    final activeStatus = widget.activeStatus;
    final isSelected = widget.isSelected;
    final onSelectionChanged = widget.onSelectionChanged;
    final onEdit = widget.onEdit;
    final onView = widget.onView;
    final onShare = widget.onShare;

    final List<String> allImages = [];
    if (workOrder.galleryImages != null && workOrder.galleryImages!.isNotEmpty) {
      allImages.addAll(workOrder.galleryImages!);
    }
    final imageUrl = allImages.isNotEmpty ? allImages.first : null;
    final String craftsmanCode =
        (workOrder.craftsman?.craftmanCode ??
                workOrder.craftsman?.businessName ??
                workOrder.allocatedCraftsmanBpCode ??
                '')
            .trim();

    Color cardColor = AppColor.white;
    if (workOrder.colorHex != null && workOrder.colorHex!.trim().isNotEmpty) {
      String hexColor = workOrder.colorHex!.toUpperCase().replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "FF$hexColor";
      }
      try {
        cardColor = Color(int.parse(hexColor, radix: 16));
      } catch (e) {
        cardColor = AppColor.white;
      }
    }

    final List<Widget> sliderItems = [];
    final List<String> sliderItemUrls = [];
    for (var url in allImages) {
      final bool isPdf = url.toLowerCase().endsWith('.pdf');
      if (isPdf) {
        final params = PdfViewerParams(
          url: url,
          enableRedaction: true,
          showAllPages: true,
          isThumbnail: false,
        );
        final state = ref.watch(pdfViewerProvider(params));

        if (state.isLoading) {
          sliderItemUrls.add(url);
          sliderItems.add(
            const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
              ),
            ),
          );
        } else if (state.errorMessage != null) {
          sliderItemUrls.add(url);
          sliderItems.add(
            const Center(
              child: Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
            ),
          );
        } else if (state.redactedPages.isNotEmpty) {
          for (var pageBytes in state.redactedPages) {
            sliderItemUrls.add(url);
            sliderItems.add(
              GestureDetector(
                onTap: () => Get.to(
                  () => PdfFullViewerScreen(
                    url: url,
                    title: workOrder.workOrderNumber,
                    enableRedaction: true,
                    backgroundColor: AppColor.background,
                    appBarColor: AppColor.background,
                    textColor: AppColor.textPrimary,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: Image.memory(pageBytes, fit: BoxFit.contain),
                ),
              ),
            );
          }
        } else {
          sliderItemUrls.add(url);
          sliderItems.add(
            GestureDetector(
              onTap: () => Get.to(
                () => PdfFullViewerScreen(
                  url: url,
                  title: workOrder.workOrderNumber,
                  enableRedaction: true,
                  backgroundColor: AppColor.background,
                  appBarColor: AppColor.background,
                  textColor: AppColor.textPrimary,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: PdfThumbnail(
                  url: url,
                  fit: BoxFit.contain,
                  enableRedaction: true,
                ),
              ),
            ),
          );
        }
      } else {
        sliderItemUrls.add(url);
        sliderItems.add(
          GestureDetector(
            onTap: () => FullScreenImageViewer.show(context, url),
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Image.network(
                url,
                fit: BoxFit.contain,
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
          ),
        );
      }
    }

    _latestItemCount = sliderItems.length;

    return Card(
      color: cardColor,
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
          SizedBox(
            width: 100,
            height: 180,
            child: Stack(
              children: [
                sliderItems.isNotEmpty
                    ? PageView.builder(
                        controller: _imageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemCount: sliderItems.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.horizontal(
                                left: Radius.circular(12),
                              ),
                            ),
                            child: sliderItems[index],
                          );
                        },
                      )
                    : const Icon(
                        Icons.image,
                        color: AppColor.textHint,
                        size: 30,
                      ),
              if (sliderItems.length > 1) ...[
                if (_currentPage > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColor.primary, size: 18),
                      onPressed: _previousPage,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (_currentPage < sliderItems.length - 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: AppColor.primary, size: 18),
                      onPressed: () => _nextPage(sliderItems.length),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${sliderItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
              if (sliderItems.isNotEmpty)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: _isImageSharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.primary),
                          )
                        : IconButton(
                            icon: Image.asset('assets/image/whatsapp.png', width: 18, height: 18),
                            onPressed: _isSharing || _isImageSharing
                                ? null
                                : () async {
                                    setState(() => _isImageSharing = true);
                                    try {
                                      final currentUrl = sliderItemUrls[_currentPage];
                                      final isPdf = currentUrl.toLowerCase().endsWith('.pdf');
                                      final partner = widget.workOrder;
                                      final isRestricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(widget.role?.toLowerCase());
                                      
                                      await ShareCardService.share(
                                        context,
                                        ShareCardItem(
                                          workOrderNumber: partner.workOrderNumber,
                                          imageUrl: currentUrl,
                                          title: partner.productName,
                                          category: partner.productCategory,
                                          quantity: partner.quantity,
                                          weight: partner.weightFrom != null ? '${partner.weightFrom}-${partner.weightTo}g' : null,
                                          size: partner.size,
                                          stone: partner.stone,
                                          enamel: partner.enamel,
                                          hallmark: partner.hallmark,
                                          rodium: partner.rodium,
                                          hook: partner.hook,
                                          screwName: partner.screwName,
                                          type: partner.type,
                                          openClose: partner.openClose,
                                          isPdf: isPdf,
                                          narration: partner.narrationCraftsman,
                                          subtitle: 'WO# ${partner.workOrderNumber ?? ""}',
                                          bpCode: isRestricted ? null : partner.bpCode,
                                        )
                                      );
                                    } finally {
                                      if (mounted) setState(() => _isImageSharing = false);
                                    }
                                  },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                  ),
                ),
            ],
          ),
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
                      SizedBox(
                        height: 28,
                        child: FormFeildCommonButton(
                          text: "View",
                          onPressed: onView,
                        ),
                      ),
                      if (role?.toLowerCase() != "craftsman" &&
                          ([
                            'buyer',
                            'key_user',
                            'user',
                          ].contains(role?.toLowerCase())
                              ? activeStatus == 'New'
                              : true)) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 28,
                          child: FormFeildCommonButton(
                            text: activeStatus == 'Completed' ? "Copy" : "Edit",
                            onPressed: onEdit,
                          ),
                        ),
                      ],
                      if ((role?.toLowerCase() != "craftsman" ||
                              (activeStatus != 'Allocated' &&
                                  activeStatus != 'All')) &&
                          (activeStatus != "New" && activeStatus != "All" ||
                              role?.toLowerCase() == 'super_admin')) ...[
                        const SizedBox(width: 10),
                      ],
                      const SizedBox(width: 10),
                      _isSharing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColor.primary,
                              ),
                            )
                          : IconButton(
                              icon: Image.asset('assets/image/whatsapp.png', width: 24, height: 24),
                              onPressed: () async {
                                setState(() => _isSharing = true);
                                try {
                                  await onShare();
                                } finally {
                                  if (mounted) setState(() => _isSharing = false);
                                }
                              },
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
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
