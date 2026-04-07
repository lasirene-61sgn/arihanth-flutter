import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/purchase_order/model/purchase_orders_model.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../services/widget/full_screen_image_viewer.dart';

class PurchaseOrderCard extends StatefulWidget {
  final PurchaseOrder purchaseOrder;
  final String? role;
  final String? activeStatus;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onEdit;
  final Future<void> Function() onShare;

  const PurchaseOrderCard({
    super.key,
    required this.purchaseOrder,
    this.role,
    this.activeStatus,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onEdit,
    required this.onShare,
  });

  @override
  State<PurchaseOrderCard> createState() => _PurchaseOrderCardState();
}

class _PurchaseOrderCardState extends State<PurchaseOrderCard> {
  late PageController _imageController;
  late PageController _detailsController;
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isIndividualSharing = false;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _detailsController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  bool _isSyncing = false;
  void _syncPage(int index, PageController targetController) {
    if (_currentPage != index) {
      if (mounted) setState(() => _currentPage = index);
    }
    if (!_isSyncing) {
      _isSyncing = true;
      targetController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) _isSyncing = false;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < (widget.purchaseOrder.items?.length ?? 0) - 1) {
      _isSyncing = true;
      final target = _currentPage + 1;
      _imageController.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _detailsController.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut).then((_) {
        if (mounted) _isSyncing = false;
      });
      if (mounted) setState(() => _currentPage = target);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _isSyncing = true;
      final target = _currentPage - 1;
      _imageController.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      _detailsController.animateToPage(target, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut).then((_) {
        if (mounted) _isSyncing = false;
      });
      if (mounted) setState(() => _currentPage = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.purchaseOrder.items ?? [];
    final itemCount = items.length;

    return Card(
      color: AppColor.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: widget.isSelected ? AppColor.primary : AppColor.divider,
            width: widget.isSelected ? 2 : 1,
          ),
      ),
      elevation: 2,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Side: Image PageView with Navigation Arrows
              SizedBox(
                width: 110,
                height: 220,
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                      ),
                      child: itemCount > 0
                          ? PageView.builder(
                              controller: _imageController,
                              onPageChanged: (index) => _syncPage(index, _detailsController),
                              itemCount: itemCount,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final imageUrl = item.imageUrl;
                                return imageUrl != null && imageUrl.isNotEmpty
                                    ? GestureDetector(
                                          onTap: () => FullScreenImageViewer.show(context, imageUrl),
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                              child: Image.network(
                                                imageUrl,
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
                                                errorBuilder: (context, error, stackTrace) => const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported_outlined,
                                                    color: AppColor.textHint,
                                                    size: 30,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      )
                                    : const Icon(Icons.image, color: AppColor.textHint, size: 30);
                              },
                            )
                          : const Icon(Icons.image, color: AppColor.textHint, size: 30),
                    ),

                    // Navigation Arrows Overlay
                    if (itemCount > 1) ...[
                      if (_currentPage > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: AppColor.primary, size: 18),
                            onPressed: _previousPage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      if (_currentPage < itemCount - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: AppColor.primary, size: 18),
                            onPressed: _nextPage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                    ],
                    // Individual Share Button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: _isIndividualSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColor.primary),
                              )
                            : (widget.activeStatus != "New" && widget.activeStatus != "All" || widget.role?.toLowerCase() == 'super_admin') ? IconButton(
                                icon: Image.asset('assets/image/whatsapp.png', width: 18, height: 18),
                                onPressed: _isSharing || _isIndividualSharing
                                    ? null
                                    : () async {
                                        if (itemCount > 0) {
                                          setState(() => _isIndividualSharing = true);
                                          try {
                                            final item = items[_currentPage];
                                            final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman'].contains(widget.role?.toLowerCase());

                                            String? sharedDueDate;
                                            if (widget.purchaseOrder.dueDate != null && widget.purchaseOrder.dueDate!.isNotEmpty && widget.purchaseOrder.dueDate != 'null') {
                                              try {
                                                final parsed = DateTime.parse(widget.purchaseOrder.dueDate!);
                                                sharedDueDate = DateFormat('dd-MMM-yyyy').format(parsed);
                                              } catch (e) {
                                                sharedDueDate = widget.purchaseOrder.dueDate;
                                              }
                                            }

                                            String? sharedOrderDate;
                                            if (widget.purchaseOrder.orderDate != null && widget.purchaseOrder.orderDate!.isNotEmpty && widget.purchaseOrder.orderDate != 'null') {
                                              try {
                                                final parsed = DateTime.parse(widget.purchaseOrder.orderDate!);
                                                sharedOrderDate = DateFormat('dd-MMM-yyyy').format(parsed);
                                              } catch (e) {
                                                sharedOrderDate = widget.purchaseOrder.orderDate;
                                              }
                                            }

                                            await ShareCardService.share(
                                              context,
                                              ShareCardItem(
                                                imageUrl: item.imageUrl,
                                                title: item.productCategory ?? "Purchase Order",
                                                bpCode: restricted ? null : widget.purchaseOrder.bpCode,
                                                productCode: restricted ? null : widget.purchaseOrder.orderNumber,
                                                category: item.subCategory,
                                                weight: item.totalWeight?.toString(),
                                                narration: restricted ? null : item.notes,
                                                dueDate: sharedDueDate,
                                                orderDate: sharedOrderDate,
                                                gramsDetail: (item.grams != null && item.grams!.isNotEmpty)
                                                    ? List.generate(item.grams!.length, (i) {
                                                        final g = item.grams![i];
                                                        final q = (item.quantity != null && item.quantity!.length > i) ? item.quantity![i] : "1";
                                                        final iT = (item.individualTotals != null && item.individualTotals!.length > i) ? item.individualTotals![i] : "1";
                                                        return "$g Grams(x$q) = $iT Grams";
                                                      }).join('\n')
                                                    : null,
                                                subtitle: 'PO# ${widget.purchaseOrder.orderNumber}',
                                              ),
                                            );
                                          } finally {
                                            if (mounted) setState(() => _isIndividualSharing = false);
                                          }
                                        }
                                      },
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(4),
                              ) : const SizedBox.shrink(),
                      ),
                    ),
                    if (widget.purchaseOrder.totalWeight != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColor.primary.withOpacity(0.8),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Total: ${widget.purchaseOrder.totalWeight.toString()}g',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColor.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Right Side: Details PageView (Synchronized)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.onSelectionChanged != null)
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Transform.scale(
                                      scale: 0.9,
                                      child: Checkbox(
                                        value: widget.isSelected,
                                        onChanged: widget.onSelectionChanged,
                                        activeColor: AppColor.primary,
                                        checkColor: AppColor.textWhite,
                                        side: const BorderSide(color: AppColor.black),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                                          Clipboard.setData(ClipboardData(text: widget.purchaseOrder.orderNumber ?? ''));
                                          Toaster.showSuccess('Copied: ${widget.purchaseOrder.orderNumber}');
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(text: widget.purchaseOrder.orderNumber ?? '', style: const TextStyle(color: AppColor.textPrimary, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                     if(widget.role != "craftsman") ...[
                                     //   Text(
                                     //     'Client: ${widget.purchaseOrder.bpCode ?? '-'}',
                                     //     style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
                                     //   ),
                                       if (widget.role?.toLowerCase() == 'super_admin') ...[
                                         const SizedBox(height: 2),
                                         Text(
                                                                                      widget.purchaseOrder.allocatedCraftsmanCode ?? '-',
                                           style: const TextStyle(
                                             color: AppColor.primary,
                                             fontSize: 11,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                       ],
                                     ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (itemCount > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColor.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColor.divider),
                              ),
                              child: Text(
                                '${_currentPage + 1} / $itemCount',
                                style: const TextStyle(color: AppColor.softOrange, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Synchronized Details Section
                      const Text(
                        'Item Details:',
                        style: TextStyle(color: AppColor.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 110,
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColor.surface,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColor.divider),
                        ),
                        child: itemCount > 0
                            ? PageView.builder(
                                controller: _detailsController,
                                onPageChanged: (index) => _syncPage(index, _imageController),
                                itemCount: itemCount,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${index + 1}. ${item.productCategory ?? '-'} | ${item.subCategory ?? ''}',
                                          style: const TextStyle(color: AppColor.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        if (item.designText.isNotEmpty)
                                          GestureDetector(
                                            onTap: () {
                                              Clipboard.setData(ClipboardData(text: item.designText));
                                              Toaster.showSuccess('Copied: ${item.designText}');
                                            },
                                            child: Text(
                                              'Design: ${item.designText}',
                                              style: const TextStyle(color: AppColor.textSecondary, fontSize: 10),
                                            ),
                                          ),
                                        if (item.grams != null && item.quantity != null) ...[
                                          const SizedBox(height: 4),
                                          ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: item.grams!.length,
                                            itemBuilder: (ctx, i) {
                                              final g = item.grams![i];
                                              final q = (item.quantity!.length > i) ? item.quantity![i] : "1";
                                              final iT = (item.individualTotals != null && item.individualTotals!.length > i) ? item.individualTotals![i] : "1";
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 0.5),
                                                child: Text(
                                                  "$g Grams(x$q) = $iT Grams",
                                                  style: const TextStyle(color: AppColor.textSecondary, fontSize: 10),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Total: ${item.totalWeight ?? ''} Grams",
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColor.primary),
                                          ),
                                        ],
                                        if (item.notes != null && item.notes!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              'Note: ${item.notes}',
                                              style: TextStyle(color: AppColor.textHint, fontSize: 10, fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : const Center(child: Text('-', style: TextStyle(color: AppColor.textHint))),
                      ),
                      const SizedBox(height: 12),

                      // Dates
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.purchaseOrder.orderDate != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Order Date:', style: TextStyle(color: AppColor.textSecondary, fontSize: 9)),
                                Text(
                                  DateFormat('dd-MMM-yyyy').format(DateTime.parse(widget.purchaseOrder.orderDate!)),
                                  style: const TextStyle(color: AppColor.success, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          if (widget.purchaseOrder.dueDate != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Due Date:', style: TextStyle(color: AppColor.textSecondary, fontSize: 9)),
                                Text(
                                  DateFormat('dd-MMM-yyyy').format(DateTime.parse(widget.purchaseOrder.dueDate!)),
                                  style: const TextStyle(color: AppColor.error, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Text('Total Weight:${widget.purchaseOrder.totalWeight ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 9)),
                          if (widget.role?.toLowerCase() != "craftsman")
                            SizedBox(
                              height: 28,
                              child: FormFeildCommonButton(
                                text: "Edit",
                                onPressed: widget.onEdit,
                              ),
                            ),
                          if (widget.role?.toLowerCase() != "craftsman")
                            const SizedBox(width: 10),
                          if (widget.activeStatus != "New" && widget.activeStatus != "All" || widget.role?.toLowerCase() == 'super_admin')
                          SizedBox(
                            height: 28,
                            child: FormFeildCommonButton(
                              text: "Share",
                              isLoading: _isSharing,
                              onPressed: _isSharing || _isIndividualSharing
                                  ? null
                                  : () async {
                                      setState(() => _isSharing = true);
                                      try {
                                        await widget.onShare();
                                      } finally {
                                        if (mounted) setState(() => _isSharing = false);
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
        ],
      ),
    );
  }
}
