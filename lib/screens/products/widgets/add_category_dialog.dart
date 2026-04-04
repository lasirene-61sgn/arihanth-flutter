import 'package:flutter/material.dart';
import 'package:arianth/app_color/app_color.dart';

class AddCategoryDialog extends StatefulWidget {
  final String initialName;

  const AddCategoryDialog({super.key, required this.initialName});

  static Future<Map<String, dynamic>?> show(BuildContext context, String initialName) {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AddCategoryDialog(initialName: initialName),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late TextEditingController _nameController;
  bool _hasHook = false;
  bool _hasEnamel = false;
  bool _hasRodium = false;
  bool _hasOpenClose = false;
  bool _hasStone = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: AppColor.coolLavender,
      ),
      child: CheckboxListTile(
        title: Text(label, style: const TextStyle(color: AppColor.white, fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColor.primary,
           checkColor: AppColor.textWhite,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.darkNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColor.coolLavender, width: 0.5),
      ),
      title: const Text('Add New Category', style: TextStyle(color: AppColor.white, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category Name', style: TextStyle(color: AppColor.coolLavender, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColor.white, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColor.primary.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColor.coolLavender)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColor.coolLavender)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColor.primary)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Require Fields', style: TextStyle(color: AppColor.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildCheckbox('Has Hook', _hasHook, (v) => setState(() => _hasHook = v ?? false)),
            _buildCheckbox('Has Enamel', _hasEnamel, (v) => setState(() => _hasEnamel = v ?? false)),
            _buildCheckbox('Has Rodium', _hasRodium, (v) => setState(() => _hasRodium = v ?? false)),
            _buildCheckbox('Has Open/Close', _hasOpenClose, (v) => setState(() => _hasOpenClose = v ?? false)),
            _buildCheckbox('Has Stone', _hasStone, (v) => setState(() => _hasStone = v ?? false)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColor.coolLavender)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.darkNavy,
          ),
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'hasHook': _hasHook,
              'hasEnamel': _hasEnamel,
              'hasRodium': _hasRodium,
              'hasOpenClose': _hasOpenClose,
              'hasStone': _hasStone,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
