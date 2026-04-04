import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkOrderAllocatedDialog extends ConsumerStatefulWidget {
  final Set<String> selectedOrderIds; 
  const WorkOrderAllocatedDialog({super.key, required this.selectedOrderIds});

  static Future<void> show(BuildContext context, WidgetRef ref, Set<String> selectedOrderIds) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, // We handle background in Container
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: WorkOrderAllocatedDialog(selectedOrderIds: selectedOrderIds),
      ),
    );
  }

  @override
  ConsumerState<WorkOrderAllocatedDialog> createState() => _WorkOrderAllocatedDialogState();
}

class _WorkOrderAllocatedDialogState extends ConsumerState<WorkOrderAllocatedDialog> {
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
    final workOrderState = ref.watch(workOrderListProvider);
    final isBusy = workOrderState.assignLoad;

    // Filter to get only BP codes
    final bpCodes = craftsManState.bpCraftsmanList
        .where((c) => c.bpCode != null && c.bpCode!.trim().isNotEmpty)
        .map((c) => c.bpCode!.trim())
        .toSet()
        .toList();

    // Reset invalid selection
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
          // ----- HEADER -----
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocate Work Order',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? AppColor.coolLavender : Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(height: 24, color: isDark ? AppColor.coolLavender.withOpacity(0.3) : Colors.grey.shade200),

          // ----- INFO -----
          Text(
            'Selected Orders: ${widget.selectedOrderIds.length}',
            style: TextStyle(
              fontSize: 14,
              color: AppColor.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // ----- FORM FIELDS -----
          Text('Select Business Partner', style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w500,
            color: isDark ? AppColor.coolLavender : Colors.grey.shade700,
          )),
          const SizedBox(height: 6),
          
          DropdownButtonFormField<String>(
            value: _selectedBpCode,
            hint: Text('Select Craftsman Code', style: TextStyle(color: isDark ? AppColor.coolLavender.withOpacity(0.5) : Colors.grey.shade400)),
            isExpanded: true,
            dropdownColor: isDark ? AppColor.primary : Colors.white,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppColor.coolLavender.withOpacity(0.5) : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
              ),
            ),
            icon: Icon(Icons.arrow_drop_down, color: isDark ? AppColor.coolLavender : Colors.grey),
            items: bpCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
            onChanged: (v) => setState(() => _selectedBpCode = v),
          ),

          const SizedBox(height: 32),

          // ----- SUBMIT -----
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: isBusy ? null : _submit,
              child: isBusy 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Allocate Orders', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedBpCode == null) {
      Toaster.showError('Please select a Business Partner');
      return;
    }

    final List<int> orderIdsInt = widget.selectedOrderIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();

    final payload = {
      "work_order_ids": orderIdsInt,
      "allocated_craftsman_bp_code": _selectedBpCode,
    };

    await ref.read(workOrderListProvider.notifier).assignOrder(
        context, payload);
  }

  Widget _labelledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _dateField({
    required String label,
    required ValueChanged<DateTime> onPick,
    DateTime? value,
    required bool isDark,
  }) {
    final TextEditingController dateCtrl = TextEditingController(
      text: value != null ? '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}' : '',
    );

    return _labelledField(
      label: label,
      child: CustomInputField(
        labelText: null,
        controller: dateCtrl,
        readOnly: true,
        onTap: () async {
          final DateTime now = DateTime.now();
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365 * 2)),
          );
          if (picked != null) onPick(picked);
        },
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
        hintText: 'dd-mm-yyyy',
      ),
    );
  }
}
