import 'package:arianth/services/widget/form_field_common_button.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../purchase_order/ui/widgets/po_sub_item_row.dart';
import '../model/stock_order_form_model.dart';
import '../../../../app_color/app_color.dart';

class StockOrderItemRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> itemData;
  final Widget imageWidget;
  final VoidCallback onAddSubItem;
  final Function(int) onRemoveSubItem;
  final VoidCallback onRemoveMainItem;
  final VoidCallback onRecalc;
  final bool isMobile;

  const StockOrderItemRow({
    super.key,
    required this.index,
    required this.itemData,
    required this.imageWidget,
    required this.onAddSubItem,
    required this.onRemoveSubItem,
    required this.onRemoveMainItem,
    required this.onRecalc,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return isMobile ? _buildMobileCard(context) : _buildWebRow(context);
  }

  Widget _smallTextField({required TextEditingController controller, required String hint, bool readOnly = false, TextStyle? style}) {
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
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColor.textHint, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        ),
        style: style ?? TextStyle(
          fontSize: 12,
          color: readOnly ? AppColor.textSecondary : AppColor.textPrimary,
        ),
      ),
    );
  }

  Widget _buildWebRow(BuildContext context) {
    const double colSpacing = 10;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // S.No
          SizedBox(
            width: 30,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 12, color: AppColor.textPrimary),
            ),
          ),
          const SizedBox(width: colSpacing),

          // Code Display (Instead of Dropdowns)
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (itemData['stockData'] as FormProduct?)?.category ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                if (itemData['designCode'] != null && itemData['designCode'].toString().isNotEmpty)
                  Text(
                    'Design: ${itemData['designCode']}',
                    style: const TextStyle(color: AppColor.textSecondary, fontSize: 10),
                  ),
              ],
            ),
          ),
          const SizedBox(width: colSpacing),

          // Grams & Qty Column
          SizedBox(
            width: 220,
            child: Column(
              children: [
                ...(itemData['subItems'] as List).asMap().entries.map((subE) {
                  return POSubItemRow(
                    gramsCtrl: subE.value['gramsCtrl'],
                    qtyCtrl: subE.value['qtyCtrl'],
                    totalWeightCtrl: subE.value['totalWeightCtrl'],
                    onRecalc: onRecalc,
                    onRemove: itemData['subItems'].length > 1 ? () => onRemoveSubItem(subE.key) : null,
                  );
                }),
                const SizedBox(height: 4),
                FormFeildCommonButton(
                  text: "Add Row",
                  textColor: AppColor.black,
                  backgroundColor: AppColor.white,
                  onPressed: onAddSubItem,
                ),
              ],
            ),
          ),
          const SizedBox(width: colSpacing),

          // Total Weight (Read Only)
          SizedBox(width: 80, child: _smallTextField(controller: itemData['totalWeightCtrl'], hint: 'Total', readOnly: true)),
          const SizedBox(width: colSpacing),

          // Size Field
          SizedBox(
            width: 90, 
            child: _smallTextField(
              controller: itemData['sizeCtrl'], 
              hint: 'Size',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
            ),
          ),
          const SizedBox(width: colSpacing),

          // Notes Field
          Expanded(child: _smallTextField(controller: itemData['notesCtrl'], hint: 'Item notes...')),
          const SizedBox(width: colSpacing),

          // Image Picker & Preview
          SizedBox(
            width: 100, 
            child: imageWidget,
          ),
          const SizedBox(width: colSpacing),

          // Remove Button
          IconButton(
            onPressed: onRemoveMainItem,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context) {
    
    return Card(
      elevation: 0,
      color: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColor.divider),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item #${index + 1} - ${(itemData['stockData'] as FormProduct?)?.category ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                ),
                IconButton(
                  onPressed: onRemoveMainItem,
                  icon: const Icon(Icons.delete_outline, color: AppColor.error, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (itemData['designCode'] != null && itemData['designCode'].toString().isNotEmpty)
              Text(
                'Design: ${itemData['designCode']}',
                style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
              ),
            const Divider(height: 24, color: AppColor.divider),

            // Sub items list
            ...(itemData['subItems'] as List).asMap().entries.map((subE) {
              return POSubItemRow(
                gramsCtrl: subE.value['gramsCtrl'],
                qtyCtrl: subE.value['qtyCtrl'],
                totalWeightCtrl: subE.value['totalWeightCtrl'],
                onRecalc: onRecalc,
                onRemove: itemData['subItems'].length > 1 ? () => onRemoveSubItem(subE.key) : null,
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColor.primary,
                ),
                onPressed: onAddSubItem,
                icon: const Icon(Icons.add, size: 16, color: AppColor.white),
                label: const Text('Add Row', style: TextStyle(fontSize: 12, color: AppColor.white)),
              ),
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                const Text("Total Weight: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: _smallTextField(controller: itemData['totalWeightCtrl'], hint: '0.00', readOnly: true)),
              ],
            ),
            const SizedBox(height: 8),

            // Size (Mobile)
            Row(
              children: [
                const Text("Size: ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100, 
                  child: _smallTextField(
                    readOnly: true,
                    controller: itemData['sizeCtrl'], 
                    hint: 'Size',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Notes (Mobile)
            _smallTextField(controller: itemData['notesCtrl'], hint: 'Enter item notes...'),
            const SizedBox(height: 12),

            // Image (Mobile)
            const Text("Image/Document", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.textPrimary)),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity, 
              child: imageWidget,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnails(List<PlatformFile> files) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: files.map((file) {
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColor.divider),
            image: file.bytes != null 
                ? DecorationImage(image: MemoryImage(file.bytes!), fit: BoxFit.cover)
                : null,
          ),
          child: file.bytes == null 
              ? const Icon(Icons.insert_drive_file, size: 20, color: AppColor.textSecondary)
              : null,
        );
      }).toList(),
    );
  }
}
