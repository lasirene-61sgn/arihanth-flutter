import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PurchaseCraftsmanBulkCompleteDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const PurchaseCraftsmanBulkCompleteDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: PurchaseCraftsmanBulkCompleteDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<PurchaseCraftsmanBulkCompleteDialog> createState() => _PurchaseCraftsmanBulkCompleteDialogState();
}

class _PurchaseCraftsmanBulkCompleteDialogState extends ConsumerState<PurchaseCraftsmanBulkCompleteDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(purchaseOrderListProvider);
    final isBusy = state.isLoading;

    return Container(
      width: 400,
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
              Text('Complete Purchase Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text('Are you sure you want to mark the ${widget.selectedIds.length} selected purchase orders as completed?', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: isBusy ? null : () => Navigator.pop(context), child: const Text('Cancel'))),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.white),
                  onPressed: isBusy ? null : _submit,
                  child: isBusy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Complete'),
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
    await ref.read(purchaseOrderListProvider.notifier).bulkCompletePurchaseOrders(ids);
    if (mounted) Navigator.pop(context);
  }
}
