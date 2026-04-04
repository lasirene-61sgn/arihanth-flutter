import 'package:flutter/material.dart';
import 'package:arianth/app_color/app_color.dart';

class AddSubCategoryDialog extends StatefulWidget {
  final String initialName;

  const AddSubCategoryDialog({super.key, required this.initialName});

  static Future<String?> show(BuildContext context, String initialName) {
    return showDialog<String?>(
      context: context,
      builder: (context) => AddSubCategoryDialog(initialName: initialName),
    );
  }

  @override
  State<AddSubCategoryDialog> createState() => _AddSubCategoryDialogState();
}

class _AddSubCategoryDialogState extends State<AddSubCategoryDialog> {
  late TextEditingController _nameController;

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColor.divider, width: 0.5),
      ),
      title: const Text('Add New Sub Category', style: TextStyle(color: AppColor.textPrimary, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sub Category Name', style: TextStyle(color: AppColor.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: AppColor.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppColor.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColor.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColor.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: AppColor.primary)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: AppColor.textWhite,
          ),
          onPressed: () {
            if (_nameController.text.trim().isEmpty) return;
            Navigator.of(context).pop(_nameController.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
