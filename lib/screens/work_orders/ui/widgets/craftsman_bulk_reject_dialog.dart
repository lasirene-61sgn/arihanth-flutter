import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CraftsmanBulkRejectDialog extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  const CraftsmanBulkRejectDialog({super.key, required this.selectedIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: CraftsmanBulkRejectDialog(selectedIds: selectedIds),
      ),
    );
  }

  @override
  ConsumerState<CraftsmanBulkRejectDialog> createState() => _CraftsmanBulkRejectDialogState();
}

class _CraftsmanBulkRejectDialogState extends ConsumerState<CraftsmanBulkRejectDialog> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workOrderState = ref.watch(workOrderListProvider);
    final isBusy = workOrderState.isLoading;

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
              Text(
                'Reject Work Orders',
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
            'Reject ${widget.selectedIds.length} selected work orders?',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          CustomInputField(
            labelText: 'Reason for Rejection *',
            hintText: 'Enter reason...',
            controller: _reasonController,
            maxLines: 3,
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
                    backgroundColor: Colors.redAccent,
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
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      Toaster.showError('Please provide a reason');
      return;
    }
    final ids = widget.selectedIds.map((id) => int.parse(id)).toList();
    await ref.read(workOrderListProvider.notifier).bulkRejectWorkOrders(ids, reason);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
