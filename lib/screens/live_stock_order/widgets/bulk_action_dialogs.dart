import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/live_stock_order/riverpod/live_stock_order_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- BULK ALLOCATE DIALOG ---
class StockOrderBulkAllocateDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const StockOrderBulkAllocateDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: StockOrderBulkAllocateDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<StockOrderBulkAllocateDialog> createState() => _StockOrderBulkAllocateDialogState();
}

class _StockOrderBulkAllocateDialogState extends ConsumerState<StockOrderBulkAllocateDialog> {
  String? _selectedBpCode;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productListProvider.notifier).fetchCraftBPCodes());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final craftsManState = ref.watch(productListProvider);
    final stockOrderState = ref.watch(liveStockOrderNotifierProvider);
    final isBusy = stockOrderState.isAllocating;

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
              Text(
                'Allocate Stock Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Selected Orders: ${widget.selectedIds.length}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary),
          ),
          const SizedBox(height: 16),
          const Text('Select Craftsman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedBpCode,
            hint: const Text('Select Craftsman Code'),
            isExpanded: true,
            dropdownColor: isDark ? AppColor.darkNavy : Colors.white,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: craftsManState.bpCraftsmanList
                .where((c) => c.bpCode != null && c.bpCode!.trim().isNotEmpty)
                .map((c) => DropdownMenuItem(
                      value: c.bpCode!.trim(),
                      child: Text("${c.businessName} - ${c.bpCode!.trim()}"),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedBpCode = v),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: isBusy ? null : _submit,
              child: isBusy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Allocate Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedBpCode == null) {
      Toaster.showError('Please select a Craftsman');
      return;
    }

    final List<int> ids = widget.selectedIds.map((id) => int.parse(id)).toList();
    final payload = {
      "order_ids": ids,
      "craftman_code": _selectedBpCode,
    };

    await ref.read(liveStockOrderNotifierProvider.notifier).bulkAllocateStockOrders(payload);
    if (mounted) Navigator.pop(context);
  }
}

// --- BULK ACCEPT DIALOG ---
class StockOrderBulkAcceptDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const StockOrderBulkAcceptDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: StockOrderBulkAcceptDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<StockOrderBulkAcceptDialog> createState() => _StockOrderBulkAcceptDialogState();
}

class _StockOrderBulkAcceptDialogState extends ConsumerState<StockOrderBulkAcceptDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockOrderState = ref.watch(liveStockOrderNotifierProvider);
    final isBusy = stockOrderState.isAccepting;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkNavy : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accept Stock Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Are you sure you want to accept the ${widget.selectedIds.length} selected stock orders?',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isBusy ? null : _submit,
                  child: isBusy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Accept'),
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
    await ref.read(liveStockOrderNotifierProvider.notifier).bulkAcceptStockOrders(ids);
    if (mounted) Navigator.pop(context);
  }
}

// --- BULK REJECT DIALOG ---
class StockOrderBulkRejectDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const StockOrderBulkRejectDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: StockOrderBulkRejectDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<StockOrderBulkRejectDialog> createState() => _StockOrderBulkRejectDialogState();
}

class _StockOrderBulkRejectDialogState extends ConsumerState<StockOrderBulkRejectDialog> {
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockOrderState = ref.watch(liveStockOrderNotifierProvider);
    final isBusy = stockOrderState.isRejecting;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkNavy : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reject Stock Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Rejecting ${widget.selectedIds.length} orders. Please provide a reason:',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Rejection reason...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
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
    if (_reasonController.text.trim().isEmpty) {
      Toaster.showError('Please provide a reason for rejection');
      return;
    }
    final ids = widget.selectedIds.map((id) => int.parse(id)).toList();
    await ref.read(liveStockOrderNotifierProvider.notifier).bulkRejectStockOrders(ids, _reasonController.text.trim());
    if (mounted) Navigator.pop(context);
  }
}

// --- BULK COMPLETE DIALOG ---
class StockOrderBulkCompleteDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const StockOrderBulkCompleteDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: StockOrderBulkCompleteDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<StockOrderBulkCompleteDialog> createState() => _StockOrderBulkCompleteDialogState();
}

class _StockOrderBulkCompleteDialogState extends ConsumerState<StockOrderBulkCompleteDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stockOrderState = ref.watch(liveStockOrderNotifierProvider);
    final isBusy = stockOrderState.isCompleting;

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColor.darkNavy : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Complete Stock Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Mark ${widget.selectedIds.length} selected stock orders as completed?',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
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
    await ref.read(liveStockOrderNotifierProvider.notifier).bulkCompleteStockOrders(ids);
    if (mounted) Navigator.pop(context);
  }
}
