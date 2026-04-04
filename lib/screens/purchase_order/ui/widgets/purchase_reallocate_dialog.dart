import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/purchase_order/riverpod/purchase_orders_notifier.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Used by Admin/super_admin in the Rejected tab to reallocate selected POs to a new craftsman.
class PurchaseReallocateDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const PurchaseReallocateDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: PurchaseReallocateDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<PurchaseReallocateDialog> createState() => _PurchaseReallocateDialogState();
}

class _PurchaseReallocateDialogState extends ConsumerState<PurchaseReallocateDialog> {
  String? _selectedBpCode;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productListProvider.notifier).fetchCraftBPCodes());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final craftsmanState = ref.watch(productListProvider);
    final poState = ref.watch(purchaseOrderListProvider);
    final isBusy = poState.assignLoad;

    final bpCodes = craftsmanState.bpCraftsmanList
        .where((c) => c.bpCode != null && c.bpCode!.trim().isNotEmpty)
        .map((c) => c.bpCode!.trim())
        .toSet()
        .toList();

    if (_selectedBpCode != null && !bpCodes.contains(_selectedBpCode)) {
      _selectedBpCode = null;
    }

    return Container(
      width: 460,
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
              Text('Reallocate Purchase Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          Divider(color: isDark ? AppColor.coolLavender.withOpacity(0.3) : Colors.grey.shade200),
          const SizedBox(height: 8),
          Text('Selected: ${widget.selectedIds.length} orders',
              style: const TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Text('Select Craftsman BP Code *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? AppColor.coolLavender : Colors.grey.shade700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedBpCode,
            dropdownColor: isDark ? AppColor.primary : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            hint: Text('Select BP Code', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              fillColor: isDark ? AppColor.primary.withOpacity(0.2) : Colors.grey.shade100,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            items: bpCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
            onChanged: (v) => setState(() => _selectedBpCode = v),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isBusy ? null : _submit,
              child: isBusy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Reallocate Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedBpCode == null) {
      Toaster.showError('Please select a craftsman BP code');
      return;
    }
    final ids = widget.selectedIds.map((id) => int.tryParse(id)).whereType<int>().toList();

    final success = await ref.read(purchaseOrderListProvider.notifier).reallocatePurchaseOrders(widget.selectedIds.first.toString());
    if (success && mounted) Navigator.pop(context);
  }
}
