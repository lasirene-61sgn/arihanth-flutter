import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/live_stock_order/model/stock_order_detail_model.dart';
import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../services/widget/full_screen_image_viewer.dart';

class StockOrderCard extends StatefulWidget {
  final StockOrderDetailModel stockOrder;
  final String? role;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final Future<void> Function() onShare;

  const StockOrderCard({
    super.key,
    required this.stockOrder,
    this.role,
    this.isSelected = false,
    this.onSelectionChanged,
    required this.onShare,
  });

  @override
  State<StockOrderCard> createState() => _StockOrderCardState();
}

class _StockOrderCardState extends State<StockOrderCard> {
  bool _isSharing = false;

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'null') return null;
    try {
      return DateFormat('dd-MMM-yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.stockOrder;
    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman']
        .contains(widget.role?.toLowerCase());

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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Image
            Container(
              width: 110,
              decoration: const BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: order.imageUrl != null && order.imageUrl!.isNotEmpty
                        ? GestureDetector(
                            onTap: () => FullScreenImageViewer.show(context, order.imageUrl!),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                              child: Image.network(
                                order.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColor.textHint,
                                  size: 30,
                                ),
                              ),
                            ),
                          )
                        : const Icon(Icons.image, color: AppColor.textHint, size: 30),
                  ),
                  if (order.totalWeightDisplay.isNotEmpty)
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
                          'Total: ${order.totalWeightDisplay}',
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

            // Right: Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.onSelectionChanged != null)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: widget.isSelected,
                              onChanged: widget.onSelectionChanged,
                              activeColor: AppColor.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: order.orderNumber ?? ''));
                              Toaster.showSuccess('Copied: ${order.orderNumber}');
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order: ${order.orderNumber ?? "-"}',
                                  style: const TextStyle(
                                    color: AppColor.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (order.designCode != null)
                                  Text(
                                    'Design: ${order.designCode}',
                                    style: const TextStyle(
                                      color: AppColor.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (order.status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.status!,
                              style: const TextStyle(
                                color: AppColor.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (order.grams != null)
                      Text(
                        '${order.grams} gm × ${order.quantity ?? 1} = ${order.totalWeightDisplay}',
                        style: const TextStyle(color: AppColor.textSecondary, fontSize: 11),
                      ),

                    if (order.hasSize)
                      Text(
                        'Size: ${order.size}',
                        style: const TextStyle(
                          color: AppColor.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const Spacer(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (order.createdAt != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date:', style: TextStyle(color: AppColor.textSecondary, fontSize: 9)),
                              Text(
                                _formatDate(order.createdAt) ?? '',
                                style: const TextStyle(color: AppColor.success, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
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
      ),
    );
  }
}
