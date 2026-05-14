// ──────────────────────────────────────────────────────────────
//  ui/widgets/design_aprove_dialog.dart
// ──────────────────────────────────────────────────────────────
import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/designs/riverpod/designs_notifier.dart';
import 'package:arianth/services/widget/custom_input_feild.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesignAproveDialog extends ConsumerStatefulWidget {
  final String designId;

  const DesignAproveDialog({
    super.key,
    required this.designId,
  });

  static Future<void> show(BuildContext context, WidgetRef ref, String designId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColor.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColor.divider),
        ),
        child: DesignAproveDialog(designId: designId),
      ),
    );
  }

  @override
  ConsumerState<DesignAproveDialog> createState() => _DesignAproveDialogState();
}

class _DesignAproveDialogState extends ConsumerState<DesignAproveDialog> {
  // final _designCodeCtrl = TextEditingController();

  /// null = no choice yet, true = Accept, false = Reject
  bool? _selectedStatus;

  @override
  void dispose() {
    // _designCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(designsProvider);
    final isApproving = state.savingDesignId == widget.designId;
    final isRejecting = state.rejectingDesignId == widget.designId;
    final isBusy = isApproving || isRejecting;

    return Container(
      width: 420,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Design Approval',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColor.textSecondary),
                onPressed: isBusy ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: AppColor.divider, height: 24),

          // ── Step 1: Choose Status ──
          const Text(
            'Select Status',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColor.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Accept chip
              Expanded(
                child: GestureDetector(
                  onTap: isBusy ? null : () => setState(() => _selectedStatus = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedStatus == true
                          ? Colors.green.shade600
                          : AppColor.divider,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedStatus == true
                            ? Colors.green.shade700
                            : AppColor.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: _selectedStatus == true ? Colors.white : AppColor.textSecondary,
                            size: 18),
                        const SizedBox(width: 6),
                        Text('Accept',
                            style: TextStyle(
                              color: _selectedStatus == true ? Colors.white : AppColor.textSecondary,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Reject chip
              Expanded(
                child: GestureDetector(
                  onTap: isBusy ? null : () => setState(() => _selectedStatus = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedStatus == false
                          ? Colors.red.shade600
                          : AppColor.divider,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedStatus == false
                            ? Colors.red.shade700
                            : AppColor.border,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_outlined,
                            color: _selectedStatus == false ? Colors.white : AppColor.textSecondary,
                            size: 18),
                        const SizedBox(width: 6),
                        Text('Reject',
                            style: TextStyle(
                              color: _selectedStatus == false ? Colors.white : AppColor.textSecondary,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Step 2: Design Code (only for Accept) ──
          // AnimatedSize(
          //   duration: const Duration(milliseconds: 200),
          //   child: _selectedStatus == true
          //       ? Padding(
          //           padding: const EdgeInsets.only(top: 20),
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               const Text(
          //                 'Design Code',
          //                 style: TextStyle(
          //                     fontSize: 13,
          //                     fontWeight: FontWeight.w500,
          //                     color: AppColor.coolLavender),
          //               ),
          //               const SizedBox(height: 8),
          //               CustomInputField(
          //                 labelText: 'Enter Design Code',
          //                 controller: _designCodeCtrl,
          //                 style: const TextStyle(color: AppColor.white),
          //               ),
          //             ],
          //           ),
          //         )
          //       : const SizedBox.shrink(),
          // ),

          const SizedBox(height: 24),

          // ── Action buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: isBusy ? null : () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColor.textSecondary)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedStatus == true
                      ? Colors.green.shade700
                      : _selectedStatus == false
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: isBusy || _selectedStatus == null
                    ? null
                    : () async {
                        final isAccept = _selectedStatus!;
                        final endpoint = isAccept
                            ? 'api/common/designs/${widget.designId}/accept'
                            : 'api/common/designs/${widget.designId}/reject';

                   await ref.read(designsProvider.notifier).saveDesign(
                     {},
                          id: widget.designId,
                          url: endpoint,
                          reject: !isAccept,
                        );

                      },
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _selectedStatus == true
                            ? 'Accept'
                            : _selectedStatus == false
                                ? 'Reject'
                                : 'Confirm',
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}