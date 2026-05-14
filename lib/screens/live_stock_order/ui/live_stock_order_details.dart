import 'package:arianth/app_color/app_color.dart';
import 'package:arianth/screens/live_stock_order/model/stock_order_detail_model.dart';
import 'package:arianth/screens/live_stock_order/riverpod/live_stock_order_notifier.dart';
import 'package:arianth/services/local_storage/shared_preference.dart';
import 'package:arianth/services/widget/full_screen_image_viewer.dart';
import 'package:arianth/services/widget/custom_msg.dart';
import 'package:arianth/services/widget/reusable_share_card.dart';
import 'package:arianth/screens/products/model/bp_buyer_model.dart';
import 'package:arianth/screens/products/riverpod/products_notifier.dart';
import 'package:arianth/screens/work_orders/ui/widgets/work_order_dropdown_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LiveStockOrderDetailScreen extends ConsumerStatefulWidget {
  final String stockOrderId;

  const LiveStockOrderDetailScreen({super.key, required this.stockOrderId});

  @override
  ConsumerState<LiveStockOrderDetailScreen> createState() =>
      _LiveStockOrderDetailScreenState();
}

class _LiveStockOrderDetailScreenState
    extends ConsumerState<LiveStockOrderDetailScreen> {
  String? role;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    role = SharedPreferencesHelper().getString("role") ?? '';
    Future.microtask(() {
      ref
          .read(liveStockOrderNotifierProvider.notifier)
          .fetchLiveStockOrderDetail(widget.stockOrderId);
    });
  }

  String? _formatDate(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'null') return null;
    try {
      return DateFormat('dd-MMM-yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return null;
    }
  }

  Widget _infoRow(String label, String? value, {Color? valueColor}) {
    if (value == null || value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(color: Colors.black38)),
          Expanded(
            child: GestureDetector(
              onTap: label == 'Order No' || label == 'Design Code'
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      Toaster.showSuccess('Copied: $value');
                    }
                  : null,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'allocated':
        return Colors.blue;
      case 'accepted':
      case 'in process':
      case 'in-process':
        return AppColor.primary;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveStockOrderNotifierProvider);
    final StockOrderDetailModel? order = state.stockOrderDetail;
    final bool restricted = ['super_admin', 'buyer', 'key_user', 'user', 'craftsman']
        .contains(role?.toLowerCase());

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          order?.orderNumber ?? 'Stock Order Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColor.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (order != null)
            _isSharing
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: Image.asset(
                      'assets/image/whatsapp.png',
                      width: 24,
                      height: 24,
                    ),
                    onPressed: () => _shareOrder(order, restricted),
                  ),
        ],
      ),
      body: (state.isLoading && order == null)
          ? const Center(
              child: CircularProgressIndicator(color: AppColor.primary))
          : order == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        state.error ?? 'Order not found',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : _buildBody(order, restricted, state),
    );
  }

  Widget _buildBody(StockOrderDetailModel order, bool restricted, LiveStockOrderState state) {
    final gramsVal = double.tryParse(order.grams ?? '') ?? 0;
    final qtyVal = order.quantity ?? 1;
    final computed = gramsVal * qtyVal;
    final totalStr = computed == computed.truncateToDouble()
        ? '${computed.toInt()} gm'
        : '${computed.toStringAsFixed(3)} gm';

    return SingleChildScrollView(
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
              color: _statusColor(order.itemStatus).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _statusColor(order.itemStatus), width: 1.5),
            ),
            child: Column(
              children: [
                Text(
                  "Status: ${order.itemStatus ?? 'N/A'}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _statusColor(order.itemStatus)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Image Section
          if (order.imageUrl != null && order.imageUrl!.isNotEmpty) ...[
            const Text("Image", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.textPrimary)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => FullScreenImageViewer.show(context, order.imageUrl!),
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
                    order.imageUrl!,
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

          // ── Order info ───────────────────────────────────
          _sectionTitle('ORDER INFO'),
          _infoRow('Order No', order.orderNumber),
          _infoRow('Order Date', _formatDate(order.createdAt)),
          _infoRow('Total Items', order.totalItems?.toString()),
          _infoRow('Notes', order.notes),

          const SizedBox(height: 12),

          // ── Buyer info ───────────────────────────────────
          if (!restricted && order.buyer != null) ...[
            _sectionTitle('BUYER'),
            _infoRow('Name', order.buyer!.displayName),
            _infoRow('BP Code', order.buyer!.bpCode),
            _infoRow('Mobile', order.buyer!.mobile),
            _infoRow('City', [order.buyer!.city, order.buyer!.state]
                .where((e) => e != null && e.isNotEmpty)
                .join(', ')),
            const SizedBox(height: 12),
          ],

          // ── Craftsman info ─────────────────────────────────
          if (order.craftsman != null) ...[
            _sectionTitle('CRAFTSMAN'),
            _infoRow('Name', order.craftsman!.displayName),
            _infoRow('Code', order.craftsman!.craftmanCode),
            _infoRow('Mobile', order.craftsman!.mobile),
            const SizedBox(height: 12),
          ],

          // ── Item card ────────────────────────────────────
          _sectionTitle('ITEM DETAILS'),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                GestureDetector(
                  onTap: order.imageUrl != null
                      ? () => FullScreenImageViewer.show(context, order.imageUrl!)
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: order.imageUrl != null
                        ? Image.network(
                            order.imageUrl!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Design code + status badge
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: order.designCode ?? ''));
                                Toaster.showSuccess('Copied: ${order.designCode}');
                              },
                              child: Text(
                                order.designCode ?? '-',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          if (order.itemStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(order.itemStatus).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: _statusColor(order.itemStatus).withOpacity(0.4)),
                              ),
                              child: Text(
                                order.itemStatus!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(order.itemStatus),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Weight range
                      if (order.weightFrom != null || order.weightTo != null)
                        _detailChip(Icons.scale_outlined,
                            'Wt: ${order.weightFrom ?? ''} – ${order.weightTo ?? ''} gm'),

                      // Grams × Qty
                      if (order.grams != null)
                        _detailChip(
                            Icons.straighten,
                            '${order.grams} gm × ${order.quantity ?? 1} = $totalStr'),

                      // Size
                      if (order.hasSize)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColor.softOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColor.softOrange.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.category_outlined, size: 16, color: AppColor.softOrange),
                              const SizedBox(width: 6),
                              Text(
                                'Size: ${order.size}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColor.softOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Action Buttons ───────────────────────────────
          _buildActionButtons(order, state),
        ],
      ),
    );
  }

  Widget _buildActionButtons(StockOrderDetailModel order, LiveStockOrderState state) {
    final String currentRole = role?.toLowerCase() ?? '';
    final String currentStatus = order.itemStatus?.toLowerCase() ?? '';

    Widget _btn(String text, Color color, VoidCallback onPressed, {bool loading = false}) {
      return Expanded(
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      );
    }

    List<Widget> buttons = [];

    // Super Admin: Allocate button (if Pending)
    if (currentRole == 'super_admin' && currentStatus == 'pending') {
      buttons.add(_btn("Allocate to Craftsman", AppColor.primary, () => _handleAllocate(order), loading: state.isAllocating));
    }

    // Super Admin: Complete and Reallocate buttons (Only show when In Process or Rejected)
    if (currentRole == 'super_admin' && (currentStatus == 'in process' || currentStatus == 'in-process' || currentStatus == 'rejected')) {
      buttons.add(_btn("Reallocate", Colors.orange, () => _handleReallocate(order), loading: state.isAllocating));
      if (currentStatus != 'rejected') {
        buttons.add(const SizedBox(width: 16));
        buttons.add(_btn("Mark as Complete", AppColor.primary, () => _handleComplete(order), loading: state.isCompleting));
      }
    }

    // Craftsman: Complete button (Show when Accepted)
    if (currentRole == 'craftsman' && (currentStatus == 'accepted' || currentStatus == 'in process' || currentStatus == 'in-process')) {
      buttons.add(_btn("Mark as Complete", AppColor.primary, () => _handleFinish(order), loading: state.isCompleting));
    }

    // Craftsman: Accept/Reject buttons (if Allocated)
    if (currentRole == 'craftsman' && currentStatus == 'allocated') {
      buttons.add(_btn("Accept", Colors.green, () => _handleAccept(order), loading: state.isAccepting));
      buttons.add(const SizedBox(width: 16));
      buttons.add(_btn("Reject", Colors.red, () => _handleReject(order), loading: state.isRejecting));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(children: buttons);
  }

  void _handleAccept(StockOrderDetailModel order) {
    Get.dialog(
      AlertDialog(
        title: const Text("Accept Stock Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text("Are you sure you want to accept this stock order?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ref.read(liveStockOrderNotifierProvider.notifier).acceptStockOrder(
                order.id.toString(), 
                order.itemId.toString()
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Accept"),
          )
        ],
      ),
    );
  }

  void _handleReject(StockOrderDetailModel order) {
    final TextEditingController reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("Reject Stock Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Are you sure you want to reject this stock order?"),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: "Rejection Reason",
                hintText: 'Enter reason here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Toaster.showError("Please enter a reason for rejection");
                return;
              }
              Get.back();
              ref.read(liveStockOrderNotifierProvider.notifier).rejectStockOrder(
                order.id.toString(), 
                order.itemId.toString(), 
                reasonController.text
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Reject"),
          )
        ],
      ),
    );
  }

  void _handleComplete(StockOrderDetailModel order) {
    Get.dialog(
      AlertDialog(
        title: const Text("Complete Stock Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text("Are you sure you want to mark this stock order as completed?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ref.read(liveStockOrderNotifierProvider.notifier).completeStockOrder(order.id.toString());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
            child: const Text("Complete"),
          )
        ],
      ),
    );
  }

  void _handleFinish(StockOrderDetailModel order) {
    Get.dialog(
      AlertDialog(
        title: const Text("Complete Stock Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text("Are you sure you want to mark this stock order as completed?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ref.read(liveStockOrderNotifierProvider.notifier).finishStockOrder(
                order.id.toString(), 
                order.itemId.toString()
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
            child: const Text("Complete"),
          )
        ],
      ),
    );
  }

  void _handleReallocate(StockOrderDetailModel order) {
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
            title: const Text("Reallocate Stock Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkOrderDropdownWidget<BpBuyerModel>(
                    label: 'Craftsman Code',
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedCraftsmanCode == null) {
                    Toaster.showError("Please select a craftsman");
                    return;
                  }
                  Get.back();
                  ref.read(liveStockOrderNotifierProvider.notifier).reallocateStockOrder(
                    order.id.toString(),
                    {
                      'craftsman_code': selectedCraftsmanCode,
                      'allocation_notes': notesController.text,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text("Reallocate"),
              )
            ],
          );
        },
      ),
    );
  }

  void _handleAllocate(StockOrderDetailModel order) {
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
            title: const Text("Allocate Stock Order", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkOrderDropdownWidget<BpBuyerModel>(
                    label: 'Craftsman Code',
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedCraftsmanCode == null) {
                    Toaster.showError("Please select a craftsman");
                    return;
                  }
                  Get.back();
                  ref.read(liveStockOrderNotifierProvider.notifier).allocateStockOrder(
                    order.id.toString(),
                    {
                      'craftsman_code': selectedCraftsmanCode,
                      'allocation_notes': notesController.text,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary, foregroundColor: Colors.white),
                child: const Text("Allocate"),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColor.primary,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _imagePlaceholder() => Container(
        width: 110,
        height: 110,
        color: Colors.grey.shade100,
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.grey.shade400, size: 32),
      );

  Widget _detailChip(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.black45),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
          ],
        ),
      );

  Future<void> _shareOrder(StockOrderDetailModel order, bool restricted) async {
    setState(() => _isSharing = true);
    try {
      await ShareCardService.share(
        context,
        ShareCardItem(
          imageUrl: order.imageUrl,
          title: order.designCode ?? 'Stock Order',
          bpCode: restricted ? null : order.buyer?.bpCode,
          productCode: order.orderNumber,
          category: null,
          size: order.hasSize ? order.size : null,
          narration: order.notes,
          orderNote: null,
          dueDate: null,
          subtitle: 'Stock# ${order.orderNumber}',
          gramsDetail: order.grams != null
              ? '${order.grams} gm × ${order.quantity ?? 1} = ${order.totalWeightDisplay}'
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}
