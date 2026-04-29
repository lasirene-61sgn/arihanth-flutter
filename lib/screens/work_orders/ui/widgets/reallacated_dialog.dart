import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/work_orders/riverpod/work_orders_notifier.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReallocateOrderDialog extends ConsumerStatefulWidget {
  final String id;
  final String orderNo;
  final String? date;

  const ReallocateOrderDialog({
    super.key,
    required this.id,
    required this.orderNo,
    this.date,
  });

  static Future<void> show(
      BuildContext context,
      WidgetRef ref,
      String id,
      String orderNo,
      String? date,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ReallocateOrderDialog(
          id: id,
          orderNo: orderNo,
          date: date,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReallocateOrderDialog> createState() =>
      _ReallocateOrderDialogState();
}

class _ReallocateOrderDialogState extends ConsumerState<ReallocateOrderDialog> {
  final _orderNoCtrl = TextEditingController();
  DateTime? _dueDate;
  String? _selectedBpCode;

  @override
  void initState() {
    super.initState();
    _orderNoCtrl.text = widget.orderNo;

    if (widget.date != null && widget.date!.isNotEmpty) {
      try {
        final parts = widget.date!.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          _dueDate = DateTime(year, month, day);
        }
      } catch (e) {
        debugPrint("Error parsing date '${widget.date}': $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final productState = ref.watch(productListProvider);
    final workOrderState = ref.watch(workOrderListProvider);
    final isBusy = workOrderState.assignLoad;

    final craftsmen = productState.bpCraftsmanList;
    final bpCodes = craftsmen
        .where((c) => c.bpCode != null && c.bpCode!.isNotEmpty)
        .map((c) => c.bpCode!)
        .toSet()
        .toList();

    return Container(
      width: 440,
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
                'Reallocate Work Order',
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

          _labelledField(
            label: 'Order Number',
            child: TextField(
              controller: _orderNoCtrl,
              readOnly: true,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              decoration: _inputDeco(isDark: isDark),
            ),
          ),
          const SizedBox(height: 16),

          _labelledField(
            label: 'Select Craftsman BP Code *',
            child: DropdownButtonFormField<String>(
              value: _selectedBpCode,
              dropdownColor: isDark ? AppColor.darkNavy : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              hint: Text('Select BP Code', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
              isExpanded: true,
              decoration: _inputDeco(isDark: isDark),
              items: craftsmen
                  .where((c) => c.bpCode != null && c.bpCode!.isNotEmpty)
                  .map((c) => DropdownMenuItem(
                        value: c.bpCode,
                        child: Text("${c.businessName} - ${c.bpCode}"),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedBpCode = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
          ),
          const SizedBox(height: 16),

          _dateField(
            label: 'New Due Date',
            onPick: (d) => setState(() => _dueDate = d),
            value: _dueDate,
            isDark: isDark,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.softOrange,
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
      return;
    }

    final payload = {
      "allocated_craftsman_bp_code": _selectedBpCode,
    };

    if (_dueDate != null) {
       payload["craftsman_due_date"] = "${_dueDate!.day.toString().padLeft(2, '0')}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.year}";
    }

    await ref.read(workOrderListProvider.notifier).reallocateWorkOrder(
      context,
      widget.id,
      payload,
    );
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

  InputDecoration _inputDeco({required bool isDark}) {
    return InputDecoration(
      isDense: true,
      fillColor: isDark ? AppColor.deepMutedPurple.withOpacity(0.2) : Colors.grey.shade100,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}