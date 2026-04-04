import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseCraftsmanBulkRejectDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const PurchaseCraftsmanBulkRejectDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: PurchaseCraftsmanBulkRejectDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<PurchaseCraftsmanBulkRejectDialog> createState() => _PurchaseCraftsmanBulkRejectDialogState();
}

class _PurchaseCraftsmanBulkRejectDialogState extends ConsumerState<PurchaseCraftsmanBulkRejectDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(purchaseOrderListProvider);
    final isBusy = state.isLoading;

    return Container(
      width: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkNavy : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppColor.coolLavender.withOpacity(0.3)) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reject Purchase Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text('Selected: ${widget.selectedIds.length} orders', style: TextStyle(color: AppColor.softOrange, fontWeight: FontWeight.bold, fontSize: 14)),
          // const SizedBox(height: 16),
          // Text('Rejection Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColor.coolLavender : Colors.grey.shade700)),
          // const SizedBox(height: 6),
          // TextField(
          //   controller: _reasonCtrl,
          //   maxLines: 3,
          //   style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          //   decoration: InputDecoration(
          //     hintText: 'Enter reason for rejection...',
          //     hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
          //     filled: true,
          //     fillColor: isDark ? AppColor.deepMutedPurple.withOpacity(0.3) : Colors.grey.shade100,
          //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          //     contentPadding: const EdgeInsets.all(12),
          //   ),
          // ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: isBusy ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                  onPressed: isBusy ? null : _submit,
                  child: isBusy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final ids = widget.selectedIds.map((id) => int.parse(id)).toList();
    await ref.read(purchaseOrderListProvider.notifier).bulkRejectPurchaseOrders(ids, _reasonCtrl.text.trim());
    if (mounted) Navigator.pop(context);
  }
}
