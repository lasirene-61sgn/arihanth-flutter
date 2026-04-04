import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseOrderApprovalDialog extends ConsumerStatefulWidget {
  final Set<String> selectedOrderNos;
  const PurchaseOrderApprovalDialog({super.key, required this.selectedOrderNos});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedOrderNos) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: PurchaseOrderApprovalDialog(selectedOrderNos: selectedOrderNos),
      ),
    );
  }

  @override
  ConsumerState<PurchaseOrderApprovalDialog> createState() => _PurchaseOrderApprovalDialogState();
}

class _PurchaseOrderApprovalDialogState extends ConsumerState<PurchaseOrderApprovalDialog> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final purchaseOrderState = ref.watch(purchaseOrderListProvider);
    final isBusy = purchaseOrderState.assignLoad;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkNavy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(
            color: AppColor.coolLavender.withOpacity(0.3)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----- HEADER -----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Approve Purchase Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    color: isDark ? AppColor.coolLavender : Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(height: 24,
              color: isDark ? AppColor.coolLavender.withOpacity(0.3) : Colors
                  .grey.shade200),

          // ----- INFO -----
          const Text(
            'Are you sure you want to approve the selected purchase orders?',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Selected Orders: ${widget.selectedOrderNos.length}',
            style: TextStyle(
              fontSize: 14,
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // ----- SUBMIT -----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: isBusy ? null : _submit,
              child: isBusy
                  ? const SizedBox(width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Approve Orders',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final List<int> orderIdsInt = widget.selectedOrderNos
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    final payload = {
      "order_ids": orderIdsInt,
    };
    
    await ref.read(purchaseOrderListProvider.notifier).approveOrder(
        context, payload);
  }
}
