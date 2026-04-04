import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/services.dart';

class PurchaseOrderDetailScreen extends ConsumerStatefulWidget {
  final String purchaseId;

  const PurchaseOrderDetailScreen({super.key, required this.purchaseId});

  @override
  ConsumerState<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends ConsumerState<PurchaseOrderDetailScreen> {
  String? role;
  final Set<int> _acceptIndices = {};
  final Set<int> _rejectIndices = {};
  final Set<int> _sharingIndices = {};

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
      Future.microtask(
        () => ref
            .read(purchaseOrderListProvider.notifier)
            .purchaseOrderDetail(widget.purchaseId),
      );
    }

  String? _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty || date.toString() == 'null')
      return null;
    try {
      final parsed = DateTime.parse(date.toString());
      return DateFormat('dd-MMM-yyyy').format(parsed);
    } catch (e) {
      return null;
    }
  }

  Widget _buildInfoRow(String label, String? value, {bool isHeader = false}) {
    if (value == null ||
        value.trim().isEmpty ||
        value == 'null' ||
        value == '0') {
      return const SizedBox.shrink();
    }

    Widget valueWidget = Text(
      value,
      style: TextStyle(
        color: Colors.black,
        fontSize: 13,
        fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
      ),
    );

    if (label == "Order Number") {
      valueWidget = GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          Toaster.showSuccess('Copied: $value');
        },
        child: valueWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const Text(" : ", style: TextStyle(color: Colors.black54)),
          Expanded(flex: 3, child: valueWidget),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrderListProvider);
    final order = state.purchaseOrderDetail;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text(
          "Purchase Order Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: (state.isLoading && order == null)
          ? const Center(
              child: CircularProgressIndicator(color: AppColor.primary),
            )
          : order == null
              ? const Center(child: Text("Data not found"))
              : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    "Order Number",
                    order.orderNumber,
                    isHeader: true,
                  ),
                  // _buildInfoRow("Status", order.status),
                  if (role != "craftsman")
                    _buildInfoRow("Customer BP", order.bpCode),
                  _buildInfoRow("Order Date", _formatDate(order.orderDate)),
                  _buildInfoRow("Total Weight", order.totalWeight),
                  _buildInfoRow("Due Date", _formatDate(order.dueDate)),
                  _buildInfoRow("Notes", order.note),


                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "ORDER ITEMS",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  if (order.items != null)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items!.length,
                      itemBuilder: (context, index) {
                        final item = order.items![index];

                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: item.status == "rejected"?
                                     Colors.redAccent
                                    :Colors.grey.shade200
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: Image
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: item.image != null
                                          ? GestureDetector(
                                              onTap: () =>
                                                  FullScreenImageViewer.show(
                                                    context,
                                                    item.image!,
                                                  ),
                                              child: Image.network(
                                                item.image!,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Right: Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.productCategory ??
                                                    "Unknown Category",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),

                                             _sharingIndices.contains(index)
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColor.primary,
                                                    ),
                                                  )
                                                : IconButton(
                                                    icon: Image.asset(
                                                      'assets/image/whatsapp.png',
                                                      width: 20,
                                                      height: 20,
                                                    ),
                                                    onPressed: () async {
                                                      setState(() {
                                                        _sharingIndices.add(index);
                                                      });
                                                      try {
                                                        final bool restricted = [
                                                          'super_admin',
                                                          'buyer',
                                                          'key_user',
                                                          'user',
                                                          'craftsman',
                                                        ].contains(role?.toLowerCase());

                                                        // Format dates without timezone
                                                        String? sharedDueDate =
                                                            _formatDate(order.dueDate);
                                                        String? sharedOrderDate =
                                                            _formatDate(
                                                              order.orderDate,
                                                            );

                                                        await ShareCardService.share(
                                                          context,
                                                          ShareCardItem(
                                                            imageUrl: item.image,
                                                            title:
                                                                item.productCategory ??
                                                                "Purchase Order",
                                                            bpCode: restricted
                                                                ? null
                                                                : order.bpCode,
                                                            productCode: restricted
                                                                ? null
                                                                : order.orderNumber,
                                                            category: item.subCategory,
                                                            weight: item.totalWeight
                                                                ?.toString(),
                                                            narration: restricted
                                                                ? null
                                                                : item.notes,
                                                            dueDate: sharedDueDate,
                                                            orderDate: sharedOrderDate,
                                                            gramsDetail:
                                                                (item.grams != null &&
                                                                    item
                                                                        .grams!
                                                                        .isNotEmpty)
                                                                ? List.generate(item.grams!.length, (
                                                                    i,
                                                                  ) {
                                                                    final g =
                                                                        item.grams![i];
                                                                    final q =
                                                                        (item.quantity !=
                                                                                null &&
                                                                            item.quantity!.length >
                                                                                i)
                                                                        ? item.quantity![i]
                                                                        : "1";
                                                                    final iT =
                                                                        (item.individualTotals !=
                                                                                null &&
                                                                            item.individualTotals!.length >
                                                                                i)
                                                                        ? item.individualTotals![i]
                                                                        : "1";
                                                                    return "$g Grams(x$q) = $iT Grams";
                                                                  }).join('\n')
                                                                : null,
                                                            subtitle:
                                                                'PO# ${order.orderNumber}',
                                                          ),
                                                        );
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() {
                                                            _sharingIndices.remove(index);
                                                          });
                                                        }
                                                      }
                                                    },
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        _buildItemDetail(
                                          "Design",
                                          item.design.join(", "),
                                        ),

                                        // Vertical list for Grams/Qty
                                        if (item.grams != null &&
                                            item.quantity != null) ...[
                                          const SizedBox(height: 6),
                                          const Text(
                                            "Grams & Qty:",
                                            style: TextStyle(
                                              color: Colors.black54,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: item.grams!.length,
                                            itemBuilder: (ctx, i) {
                                              final g = item.grams![i];
                                              final q =
                                                  (item.quantity!.length > i)
                                                  ? item.quantity![i]
                                                  : "1";
                                              final iT =
                                                  (item
                                                          .individualTotals!
                                                          .length >
                                                      i)
                                                  ? item.individualTotals![i]
                                                  : "1";
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 1,
                                                    ),
                                                child: Text(
                                                  "$g Grams($q) = $iT Grams",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const Divider(
                                            height: 12,
                                            thickness: 0.5,
                                          ),
                                            Text(
                                              "Total: ${item.totalWeight ?? ''} gm",
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColor.primary,
                                              ),
                                            ),

                                            if (role == "craftsman" && order.status == "created" && order.items!.length > 1) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  // Accept Checkbox
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        height: 24,
                                                        width: 24,
                                                        child: Checkbox(
                                                          value: _acceptIndices.contains(index),
                                                          activeColor: AppColor.primary,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          onChanged: (bool? value) {
                                                            setState(() {
                                                              if (value == true) {
                                                                _acceptIndices.add(index);
                                                                _rejectIndices.remove(index);
                                                              } else {
                                                                _acceptIndices.remove(index);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        "Accept",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 24),
                                                  // Reject Checkbox
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      SizedBox(
                                                        height: 24,
                                                        width: 24,
                                                        child: Checkbox(
                                                          value: _rejectIndices.contains(index),
                                                          activeColor: Colors.red.shade400,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          onChanged: (bool? value) {
                                                            setState(() {
                                                              if (value == true) {
                                                                _rejectIndices.add(index);
                                                                _acceptIndices.remove(index);
                                                              } else {
                                                                _rejectIndices.remove(index);
                                                              }
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Text(
                                                        "Reject",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],

                                        _buildItemDetail("Notes", item.notes),
                                        if (item.status == "rejected")
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                                              ),
                                              child: const Text(
                                                "REJECTED",
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: (role == "craftsman" &&
              order?.status == "created" &&
              (order?.items != null && (_acceptIndices.length + _rejectIndices.length == order!.items!.length)))
          ? FloatingActionButton.extended(
              onPressed: state.isProcessingItems
                  ? null
                  : () {
                      ref
                          .read(purchaseOrderListProvider.notifier)
                          .processPurchaseOrderItems(
                            orderId: widget.purchaseId,
                            acceptIndices: _acceptIndices.toList(),
                            rejectIndices: _rejectIndices.toList(),
                          );
                      setState(() {
                        _acceptIndices.clear();
                        _rejectIndices.clear();
                      });
                    },
              label: state.isProcessingItems
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColor.textWhite,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Process All Item",
                      style: TextStyle(
                        color: AppColor.textWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              icon: state.isProcessingItems
                  ? null
                  : const Icon(
                      Icons.task_alt,
                      color: AppColor.textWhite,
                    ),
              backgroundColor: AppColor.primary,
              heroTag: "process_fab",
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildItemDetail(String label, String? value) {
    if (value == null || value.isEmpty || value == "null")
      return const SizedBox.shrink();

    Widget content = RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 12),
        children: [
          TextSpan(
            text: "$label: ",
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );

    if (label == "Design") {
      content = GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          Toaster.showSuccess('Copied: $value');
        },
        child: content,
      );
    }

    return Padding(padding: const EdgeInsets.only(top: 2), child: content);
  }
}
