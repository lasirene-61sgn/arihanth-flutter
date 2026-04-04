import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/repairs/model/repair_model.dart';
import 'package:arianth/screens/repairs/riverpod/repairs_notifier.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:arianth/services/api/api_client/api_client.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/routes/route_name/route_name.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';

class RepairDetailsScreen extends ConsumerStatefulWidget {
  final String repairId;
  const RepairDetailsScreen({Key? key, required this.repairId}) : super(key: key);

  @override
  ConsumerState<RepairDetailsScreen> createState() => _RepairDetailsScreenState();
}

class _RepairDetailsScreenState extends ConsumerState<RepairDetailsScreen> {
  String? role;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role")?.toLowerCase() ?? '';
    Future.microtask(() {
      if ( widget.repairId != null && widget.repairId.isNotEmpty) {
        ref.read(repairListProvider.notifier).fetchRepairDetail(widget.repairId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repairListProvider);
    final repair = state.repairDetail;

    if (state.isLoading && (repair == null || repair.id.toString() != widget.repairId)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColor.primary)));
    }

    if (repair == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sample/Repair Details')),
        body: Center(child: Text(state.error ?? "Sample/Repair not found")),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text('Sample/Repair #${repair.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.white)),
        centerTitle: true,
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColor.white, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (role == 'super_admin')
            IconButton(
              icon: const Icon(Icons.edit, color: AppColor.white),
              onPressed: state.isLoading
                  ? null
                    : () {
                        Get.toNamed(AppRoutes.repairsAdd, arguments: repair.id.toString());
                      },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Status Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(repair.status ?? '').withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor(repair.status ?? ''), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    "Status: ${repair.status ?? 'N/A'}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _getStatusColor(repair.status ?? '')),
                  ),
                  if (repair.rejectReason != null && repair.rejectReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text("Reason: ${repair.rejectReason}", style: const TextStyle(color: AppColor.primary)),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image Proof
            if (repair.imageProofUrl != null && repair.imageProofUrl!.isNotEmpty) ...[
              const Text("Image Proof", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.textPrimary)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => FullScreenImageViewer.show(context, repair.imageProofUrl!),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColor.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      repair.imageProofUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.image_not_supported, color: AppColor.textHint, size: 50),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Info Rows
            _buildInfoRow("Order No", repair.orderNo, isHeader: true),
            _buildInfoRow("Product Name", repair.productName),
            _buildInfoRow("Weight", repair.weight != null ? "${repair.weight} gm" : null),
            _buildInfoRow("Repair Date", _formatDate(repair.repairDate)),
            _buildInfoRow("Repair Type", repair.repair),
            if (role == 'super_admin')
              _buildInfoRow("Reference", repair.ref),
            if (role == 'super_admin')
               _buildInfoRow("BP Code", repair.buyer?.bpCode),
            if (role == 'super_admin')
               _buildInfoRow("Customer", repair.buyer?.businessName),
            if (role == 'super_admin' && repair.craftsman != null)
               _buildInfoRow("Craftsman Code", repair.craftsman?.craftmanCode),
            if (role == 'super_admin')
                 _buildInfoRow("Item Given To", repair.itemGivenTo),
            _buildInfoRow("Repair Details", repair.repairDetails),
            _buildInfoRow("Sample Details", repair.sampleDetails),
            if (role?.toLowerCase() == 'super_admin')
               _buildInfoRow("Notes", repair.notes),
            _buildInfoRow("Completion Notes", repair.allocationNotes),

            const SizedBox(height: 40),
            // Action Buttons
            // Action Buttons
            _buildActionButtons(repair, state),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: (repair != null && !state.isLoading)
          ? FloatingActionButton(
              onPressed: () {
                final bool isSample = repair.repair?.toLowerCase() == 'sample';
                ShareCardService.share(
                  context,
                  ShareCardItem(
                    workOrderNumber: repair.orderNo?.toString() ?? repair.id.toString(),
                    imageUrl: repair.imageProofUrl,
                    title: repair.productName,
                    bpCode: (role?.toLowerCase() == 'craftsman' || ["super_admin", "buyer", "key_user", "user"].contains(role?.toLowerCase())) ? null : repair.buyer?.bpCode,
                    category: repair.productName,
                    weight: repair.weight,
                    narration: isSample ? repair.sampleDetails : repair.repairDetails,
                    subtitle: 'Order No: ${repair.orderNo ?? repair.id}',
                  ),
                );
              },
              backgroundColor: AppColor.primary,
              shape: const CircleBorder(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.primary, width: 0),
                  image: DecorationImage(image: AssetImage('assets/image/whatsapp.png',) ,fit: BoxFit.cover)
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isHeader = false}) {
    if (value == null || value.trim().isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColor.textSecondary,
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const Text(" :  ", style: TextStyle(color: AppColor.textSecondary)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 14,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'accepted':
      case 'allocated': return AppColor.primary;
      case 'completed': return AppColor.primary;
      case 'rejected':
      case 'rejected_by_admin': return AppColor.primary;
      default: return AppColor.textSecondary;
    }
  }

  Widget _buildActionButtons(RepairOrder repair, RepairListState state) {
    final status = repair.status?.toLowerCase() ?? '';
    final notifier = ref.read(repairListProvider.notifier);
    final bool isLoading = state.isLoading;

    Widget _btn(String text, Color color, VoidCallback onPressed, {bool loading = false}) {
      return Expanded(
        child: ElevatedButton(
          onPressed: (isLoading || loading) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(text),
        ),
      );
    }

    List<Widget> buttons = [];

    if (role == 'admin' || role == 'super_admin') {
      if (status == 'pending') {
        buttons.add(_btn("Accept", AppColor.primary, () => _handleAccept(notifier), loading: state.isAccepting));
        buttons.add(const SizedBox(width: 16));
        buttons.add(_btn("Reject", AppColor.primary, () => _handleReject(notifier), loading: state.isRejecting));
      } else if (status == 'accepted' || status == 'buyer_accepted') {
        buttons.add(_btn("Allocate to Craftsman", AppColor.primary, () => _handleAllocate(notifier), loading: state.isAllocating));
      } else if (status == 'craftsman_completed' && role == 'super_admin') {
        buttons.add(_btn("Complete", AppColor.primary, () => _handleComplete(notifier), loading: state.isCompleting));
      }
    } else if (role == 'craftsman') {
      if (status == 'allocated') {
        buttons.add(_btn("Accept", AppColor.primary, () => _handleAccept(notifier), loading: state.isAccepting));
        buttons.add(const SizedBox(width: 16));
        buttons.add(_btn("Reject", AppColor.primary, () => _handleReject(notifier), loading: state.isRejecting));
      } else if (status == 'accepted' || status == 'craftsman_accepted') {
        buttons.add(_btn("Mark as Completed", AppColor.primary, () => _handleComplete(notifier), loading: state.isCompleting));
      }
    } else if (role == 'buyer') {
      if (status == 'completed' || status == 'craftsman_completed') {
        buttons.add(_btn("Accept", AppColor.primary, () => _handleBuyerAccept(notifier), loading: state.isAccepting));
        buttons.add(const SizedBox(width: 16));
        buttons.add(_btn("Reject", AppColor.primary, () => _handleBuyerReject(notifier), loading: state.isRejecting));
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      children: buttons,
    );
  }

  void _handleAccept(RepairListNotifier notifier) async {
    bool success = await notifier.acceptRepair(widget.repairId);
    if (success) notifier.fetchRepairDetail(widget.repairId); // Refresh via notifier
  }

  void _handleReject(RepairListNotifier notifier) {
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Reject Repair"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Enter rejection reason"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              bool success = await notifier.rejectRepair(widget.repairId, reasonController.text);
              if (success) notifier.fetchRepairDetail(widget.repairId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
            child: const Text("Confirm Reject"),
          )
        ],
      )
    );
  }

  void _handleAllocate(RepairListNotifier notifier) {
    String? selectedCraftsmanCode;
    final TextEditingController notesController = TextEditingController();

    // Ensure craftsman list is loaded
    if (ref.read(productListProvider).bpCraftsmanList.isEmpty) {
      ref.read(productListProvider.notifier).fetchCraftBPCodes();
    }

    Get.dialog(
      Consumer(
        builder: (context, ref, child) {
          final productState = ref.watch(productListProvider);
          final craftsmen = productState.bpCraftsmanList;

          return AlertDialog(
            title: const Text("Allocate Repair"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WorkOrderDropdownWidget<BpBuyerModel>(
                  label: 'craftsman Code',
                  fieldKeyName: 'craftsman_code',
                  items: craftsmen,
                  itemLabel: (bp) => "${bp.bpCode} - ${bp.businessName}",
                  selectedItemLabel: (bp) => bp.bpCode ?? '',
                  isSearchable: true,
                  hintText: 'Select craftsman',
                  onChanged: (BpBuyerModel? selected) {
                    selectedCraftsmanCode = selected?.bpCode;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: "Worker",
                    hintText: "Enter Worker Name",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCraftsmanCode == null) {
                    Toaster.showError("Please select a worker");
                    return;
                  }
                  Get.back();
                  bool success = await notifier.allocateRepair(widget.repairId, selectedCraftsmanCode!, notesController.text);
                  if (success) notifier.fetchRepairDetail(widget.repairId);
                },
                child: const Text("Allocate"),
              )
            ],
          );
        },
      ),
    );
  }

  void _handleComplete(RepairListNotifier notifier) {
    Get.dialog(
      AlertDialog(
        title: const Text("Complete Repair"),
        content: const Text("Are you sure you want to mark this repair as completed?"),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              bool success = await notifier.completeRepair(widget.repairId);
              if (success) notifier.fetchRepairDetail(widget.repairId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
            child: const Text("Complete"),
          )
        ],
      )
    );
  }

  void _handleBuyerAccept(RepairListNotifier notifier) async {
    bool success = await notifier.buyerAcceptRepair(widget.repairId);
    if (success) notifier.fetchRepairDetail(widget.repairId);
  }

  void _handleBuyerReject(RepairListNotifier notifier) {
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Reject Repair"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: "Enter rejection reason"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              bool success = await notifier.buyerRejectRepair(widget.repairId, reasonController.text);
              if (success) notifier.fetchRepairDetail(widget.repairId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
            child: const Text("Confirm Reject"),
          )
        ],
      )
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'null') return '';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }
}
