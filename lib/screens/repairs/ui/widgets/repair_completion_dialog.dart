import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/services/image_picker/image_picker_helper.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum RepairCompletionType {
  buyer,
  craftsman,
}

class RepairCompletionDialog extends StatefulWidget {
  final String repairId;
  final RepairCompletionType type;
  final String? initialItemCollectedBy;
  final String? initialItemReturnedBy;
  final Future<bool> Function({
    required String itemCollectedBy,
    required String itemReturnedBy,
    PlatformFile? voucherImage,
    PlatformFile? completionProofImage,
  }) onComplete;

  const RepairCompletionDialog({
    super.key,
    required this.repairId,
    required this.type,
    this.initialItemCollectedBy,
    this.initialItemReturnedBy,
    required this.onComplete,
  });

  static Future<void> show({
    required BuildContext context,
    required String repairId,
    required RepairCompletionType type,
    String? initialItemCollectedBy,
    String? initialItemReturnedBy,
    required Future<bool> Function({
      required String itemCollectedBy,
      required String itemReturnedBy,
      PlatformFile? voucherImage,
      PlatformFile? completionProofImage,
    }) onComplete,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RepairCompletionDialog(
        repairId: repairId,
        type: type,
        initialItemCollectedBy: initialItemCollectedBy,
        initialItemReturnedBy: initialItemReturnedBy,
        onComplete: onComplete,
      ),
    );
  }

  @override
  State<RepairCompletionDialog> createState() => _RepairCompletionDialogState();
}

class _RepairCompletionDialogState extends State<RepairCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _collectedByCtrl;
  late final TextEditingController _returnedByCtrl;
  PlatformFile? _voucherImage;
  PlatformFile? _completionProofImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _collectedByCtrl = TextEditingController(text: widget.initialItemCollectedBy ?? '');
    _returnedByCtrl = TextEditingController(text: widget.initialItemReturnedBy ?? '');
  }

  @override
  void dispose() {
    _collectedByCtrl.dispose();
    _returnedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVoucher() async {
    final images = await ImagePickerHelper.pickImages(context, allowMultiple: false);
    if (images.isNotEmpty) {
      setState(() => _voucherImage = images.first);
    }
  }

  Future<void> _pickProof() async {
    final images = await ImagePickerHelper.pickImages(context, allowMultiple: false);
    if (images.isNotEmpty) {
      setState(() => _completionProofImage = images.first);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.onComplete(
        itemCollectedBy: _collectedByCtrl.text.trim(),
        itemReturnedBy: _returnedByCtrl.text.trim(),
        voucherImage: _voucherImage,
        completionProofImage: _completionProofImage,
      );
      if (success && mounted) {
        Get.back();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = widget.type == RepairCompletionType.buyer;
    final title = isBuyer ? "Complete Buyer Approval" : "Complete Repair";
    final voucherLabel = isBuyer ? "Buyer Voucher Image" : "Craftsman Voucher Image";
    final proofLabel = isBuyer ? "Buyer Completion Proof" : "Craftsman Completion Proof";

    return AlertDialog(
      title: Text(
        "$title #${widget.repairId}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Collected By
                const Text(
                  "Item Collected By *",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _collectedByCtrl,
                  decoration: const InputDecoration(
                    hintText: "Enter person collecting item",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Item Collected By is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Item Returned By
                const Text(
                  "Item Returned By *",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _returnedByCtrl,
                  decoration: const InputDecoration(
                    hintText: "Enter person returning item",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Item Returned By is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Voucher Image
                _buildImagePickerRow(
                  label: voucherLabel,
                  file: _voucherImage,
                  onPick: _pickVoucher,
                  onClear: () => setState(() => _voucherImage = null),
                ),
                const SizedBox(height: 12),

                // Completion Proof Image
                _buildImagePickerRow(
                  label: proofLabel,
                  file: _completionProofImage,
                  onPick: _pickProof,
                  onClear: () => setState(() => _completionProofImage = null),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Get.back(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Submit"),
        ),
      ],
    );
  }

  Widget _buildImagePickerRow({
    required String label,
    required PlatformFile? file,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.divider),
              borderRadius: BorderRadius.circular(8),
              color: AppColor.surface,
            ),
            child: Row(
              children: [
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  size: 20,
                  color: file != null ? Colors.green : AppColor.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    file != null ? file.name : "Tap to choose image",
                    style: TextStyle(
                      fontSize: 12,
                      color: file != null ? AppColor.textPrimary : AppColor.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (file != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColor.error),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

