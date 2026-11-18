import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllocateRepairDialog extends ConsumerStatefulWidget {
  final String repairId;
  final String? initialCraftsmanCode;
  final String? initialItemSentBy;
  final String? initialNotes;
  final Future<bool> Function({
    required String craftsmanCode,
    String? itemSentBy,
    String? notes,
  }) onAllocate;

  const AllocateRepairDialog({
    super.key,
    required this.repairId,
    this.initialCraftsmanCode,
    this.initialItemSentBy,
    this.initialNotes,
    required this.onAllocate,
  });

  static Future<void> show({
    required BuildContext context,
    required String repairId,
    String? initialCraftsmanCode,
    String? initialItemSentBy,
    String? initialNotes,
    required Future<bool> Function({
      required String craftsmanCode,
      String? itemSentBy,
      String? notes,
    }) onAllocate,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: AllocateRepairDialog(
          repairId: repairId,
          initialCraftsmanCode: initialCraftsmanCode,
          initialItemSentBy: initialItemSentBy,
          initialNotes: initialNotes,
          onAllocate: onAllocate,
        ),
      ),
    );
  }

  @override
  ConsumerState<AllocateRepairDialog> createState() => _AllocateRepairDialogState();
}

class _AllocateRepairDialogState extends ConsumerState<AllocateRepairDialog> {
  String? _selectedBpCode;
  late final TextEditingController _itemSentByController;
  late final TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedBpCode = widget.initialCraftsmanCode;
    _itemSentByController = TextEditingController(text: widget.initialItemSentBy ?? '');
    _notesController = TextEditingController(text: widget.initialNotes ?? '');

    Future.microtask(() {
      ref.read(productListProvider.notifier).fetchCraftBPCodes();
    });
  }

  @override
  void dispose() {
    _itemSentByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final craftsmanCode = _selectedBpCode?.trim();
    if (craftsmanCode == null || craftsmanCode.isEmpty) {
      Toaster.showError("Please select a craftsman");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.onAllocate(
        craftsmanCode: craftsmanCode,
        itemSentBy: _itemSentByController.text.trim(),
        notes: _notesController.text.trim(),
      );
      if (success && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final craftsManState = ref.watch(productListProvider);

    // List of craftsmen
    final list = craftsManState.bpCraftsmanList
        .where((c) => c.bpCode != null && c.bpCode!.trim().isNotEmpty)
        .toList();

    // Reset invalid selection if not in list
    if (_selectedBpCode != null &&
        !list.any((c) => c.bpCode?.trim().toLowerCase() == _selectedBpCode?.trim().toLowerCase())) {
      // keep it if list is still loading
      if (list.isNotEmpty) {
        final match = list.firstWhere(
          (c) => c.bpCode?.trim().toLowerCase() == _selectedBpCode?.trim().toLowerCase(),
          orElse: () => list.first,
        );
        _selectedBpCode = match.bpCode?.trim();
      }
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
                'Allocate Repair #${widget.repairId}',
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
          Divider(
            height: 24,
            color: isDark ? AppColor.coolLavender.withOpacity(0.3) : Colors.grey.shade200,
          ),

          // ----- FORM FIELDS -----
          Text(
            'Select Craftsman *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColor.coolLavender : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),

          craftsManState.isLoadingBp && list.isEmpty
              ? Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text("Loading craftsmen...", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedBpCode,
                  hint: Text(
                    'Select Craftsman Code',
                    style: TextStyle(
                      color: isDark
                          ? AppColor.coolLavender.withOpacity(0.5)
                          : Colors.grey.shade400,
                    ),
                  ),
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
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColor.coolLavender.withOpacity(0.5)
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
                    ),
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: isDark ? AppColor.coolLavender : Colors.grey,
                  ),
                  items: list
                      .map((c) => DropdownMenuItem(
                            value: c.bpCode!.trim(),
                            child: Text("${c.businessName ?? ''} - ${c.bpCode!.trim()}"),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBpCode = v),
                ),

          const SizedBox(height: 16),

          // Item Sent By
          Text(
            'Item Sent By',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColor.coolLavender : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _itemSentByController,
            decoration: InputDecoration(
              hintText: "Enter person name sending item",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColor.coolLavender.withOpacity(0.5) : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes
          Text(
            'Notes',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColor.coolLavender : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Enter allocation notes",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColor.coolLavender.withOpacity(0.5) : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColor.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 24),

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
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Allocate Repair',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
