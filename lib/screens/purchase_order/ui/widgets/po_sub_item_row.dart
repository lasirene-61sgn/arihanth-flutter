import 'package:flutter/material.dart';

import '../../../../app_color/app_color.dart';

class POSubItemRow extends StatelessWidget {
  final TextEditingController gramsCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController totalWeightCtrl;
  final VoidCallback onRecalc;
  final VoidCallback? onRemove;
  final bool isMobile;

  const POSubItemRow({
    super.key,
    required this.gramsCtrl,
    required this.qtyCtrl,
    required this.totalWeightCtrl,
    required this.onRecalc,
    this.onRemove,
    this.isMobile = false,
  });

  Widget _smallInput({required TextEditingController controller, required String hint, bool readOnly = false}) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.divider),
        borderRadius: BorderRadius.circular(6),
        color: AppColor.surface,
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onChanged: (_) => onRecalc(),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        ),
        style: TextStyle(
          fontSize: 12,
          color: readOnly ? AppColor.textSecondary : AppColor.textPrimary,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Expanded(child: _smallInput(controller: gramsCtrl, hint: 'Gr')),
          const SizedBox(width: 4),
          Expanded(child: _smallInput(controller: qtyCtrl, hint: 'Qu')),
          const SizedBox(width: 4),
          Expanded(child: _smallInput(controller: totalWeightCtrl, hint: 'Sub', readOnly: true)),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}